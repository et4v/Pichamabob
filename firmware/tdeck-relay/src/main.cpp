#include <Arduino.h>
#include <SPI.h>
#include <RadioLib.h>

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#include "ble_state.h"

// T-Deck Plus peripherals that share the LoRa SPI bus
#define BOARD_POWERON     10
#define BOARD_TFT_CS      12
#define BOARD_SDCARD_CS   39

// Must match iOS app
#define SERVICE_UUID          "19B10000-E8F2-537E-4F6C-D104768A1214"
#define SIGNAL_CHARACTERISTIC "19B10001-E8F2-537E-4F6C-D104768A1214"

BLEServer* pServer = nullptr;
BLECharacteristic* pSignalCharacteristic = nullptr;

// ============================================================
// LoRa Radio Config — MUST MATCH ON BOTH DEVICES
// ============================================================
#define LORA_FREQUENCY    915.0
#define LORA_BANDWIDTH    125.0
#define LORA_SPREAD_FACT  9
#define LORA_CODING_RATE  7
#define LORA_SYNC_WORD    0x12
#define LORA_TX_POWER     14
#define LORA_PREAMBLE     8

// ============================================================
// LoRa radio object
// ============================================================
Module radioModule(LORA_CS, LORA_DIO1, LORA_RST, LORA_BUSY);
SX1262 radio(&radioModule);

// ============================================================
// Non-blocking status print timer (so BLE doesn’t get starved)
// ============================================================
unsigned long lastStatusPrint = 0;
const unsigned long STATUS_INTERVAL_MS = 1000;

// ============================================================
// LoRa state flag (don’t hard-freeze the whole device on failure)
// ============================================================
static bool loraOk = false;

void setupBLE() {
  Serial.println("BLE minimal receive test");
  Serial.println("ADVERTISING...");

  BLEDevice::init("PitchCom-Relay");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  // IMPORTANT: include WRITE_NR for iOS writeWithoutResponse
  pSignalCharacteristic = pService->createCharacteristic(
    SIGNAL_CHARACTERISTIC,
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_WRITE_NR
  );
  pSignalCharacteristic->setCallbacks(new SignalCallbacks());

  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();
}

void setupLoRa() {
  Serial.println("[LoRa] Pre-init...");

  // ---- T-Deck needs POWERON and every other SPI device deselected ----
  Serial.println("[LoRa] Powering peripherals (BOARD_POWERON)...");
  pinMode(BOARD_POWERON, OUTPUT);
  digitalWrite(BOARD_POWERON, HIGH);
  delay(200);

  Serial.println("[LoRa] Deselecting TFT + SD + LoRa (shared SPI bus)...");
  pinMode(BOARD_TFT_CS, OUTPUT);
  digitalWrite(BOARD_TFT_CS, HIGH);

  pinMode(BOARD_SDCARD_CS, OUTPUT);
  digitalWrite(BOARD_SDCARD_CS, HIGH);

  pinMode(LORA_CS, OUTPUT);
  digitalWrite(LORA_CS, HIGH);
  delay(50);

  // ---- Hardware reset the SX1262 ----
  Serial.println("[LoRa] Hardware reset SX1262...");
  pinMode(LORA_RST, OUTPUT);
  digitalWrite(LORA_RST, LOW);
  delay(20);
  digitalWrite(LORA_RST, HIGH);
  delay(200);

  // ---- Start SPI with the pins you set ----
  Serial.println("[LoRa] Starting SPI...");
  SPI.begin(LORA_SPI_SCK, LORA_SPI_MISO, LORA_SPI_MOSI);

  // Keep CS high until RadioLib starts talking
  digitalWrite(LORA_CS, HIGH);
  delay(10);

  // ---- Init SX1262 ----
  Serial.println("[LoRa] Initializing SX1262...");
  int state = radio.begin(
    LORA_FREQUENCY, LORA_BANDWIDTH, LORA_SPREAD_FACT,
    LORA_CODING_RATE, LORA_SYNC_WORD, LORA_TX_POWER, LORA_PREAMBLE
  );

  if (state != RADIOLIB_ERR_NONE) {
    Serial.printf("\n*** SX1262 FAILED! Error: %d ***\n", state);
    Serial.println("Common causes:");
    Serial.println("  - shared SPI device still selected (CS not HIGH)");
    Serial.println("  - missing BOARD_POWERON high (T-Deck)");
    Serial.println("  - wrong wiring/pins OR radio not powered");
    Serial.println("Continuing anyway so BLE still works.\n");
    loraOk = false;
    return;
  }

  radio.setCurrentLimit(60.0);
  radio.setDio2AsRfSwitch(true);
  radio.setCRC(2);

  loraOk = true;
  Serial.println("\n*** SUCCESS! SX1262 initialized! ***\n");
}

void setup() {
  Serial.begin(115200);
  Serial.setTxTimeoutMs(0);
  delay(1500);

  Serial.println("\n========================================");
  Serial.println("  T-Deck Plus — BLE -> LoRa RELAY");
  Serial.println("========================================\n");

  setupBLE();
  setupLoRa();
}

void loop() {
  // 1) Non-blocking status print
  if (millis() - lastStatusPrint >= STATUS_INTERVAL_MS) {
    lastStatusPrint = millis();
    Serial.print("STATE=");
    Serial.print(deviceConnected ? "CONNECTED" : "WAITING");
    Serial.print(" | MSG=");
    Serial.print(messageReceived ? "YES" : "NO");
    Serial.print(" | LORA=");
    Serial.println(loraOk ? "OK" : "FAIL");
  }

  // 2) When BLE writes, send that exact string over LoRa
  if (messageReceived) {
    messageReceived = false;

    String msg = bleMessage;
    Serial.print("[TX] BLE->LoRa msg: ");
    Serial.println(msg);

    if (!loraOk) {
      Serial.println("[TX] Not sending because LoRa is not initialized.");
    } else {
      int state = radio.transmit(msg);
      if (state == RADIOLIB_ERR_NONE) {
        Serial.println("[TX] OK!");
      } else {
        Serial.print("[TX] FAILED: ");
        Serial.println(state);
      }
    }
  }


  // 3) Give BLE stack time
  delay(1);
}