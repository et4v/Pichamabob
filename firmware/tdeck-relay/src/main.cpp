// t deck relay
// takes whatever the phone sends over ble and pushes it out over lora to the watch

#include <Arduino.h>
#include <SPI.h>
#include <RadioLib.h>

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#include "ble_state.h"

// these share the spi bus with the lora radio
// if any of them are still selected the radio wont answer
// poweron has to go high or nothing on the board gets power
#define BOARD_POWERON     10
#define BOARD_TFT_CS      12
#define BOARD_SDCARD_CS   39

// the ios app looks for exactly these
// if they change here they have to change in BLEManager swift too
#define SERVICE_UUID          "19B10000-E8F2-537E-4F6C-D104768A1214"
#define SIGNAL_CHARACTERISTIC "19B10001-E8F2-537E-4F6C-D104768A1214"

BLEServer* pServer = nullptr;
BLECharacteristic* pSignalCharacteristic = nullptr;

// lora settings
// these have to match the watch exactly or it just hears nothing
#define LORA_FREQUENCY    915.0
#define LORA_BANDWIDTH    125.0
#define LORA_SPREAD_FACT  9
#define LORA_CODING_RATE  7
#define LORA_SYNC_WORD    0x12
#define LORA_TX_POWER     14
#define LORA_PREAMBLE     8

// the sx1262 radio
// pins come from platformio ini so this file doesnt care which board it is
Module radioModule(LORA_CS, LORA_DIO1, LORA_RST, LORA_BUSY);
SX1262 radio(&radioModule);

// print status once a second without blocking
// if we used a big delay here ble would get starved and drop the phone
unsigned long lastStatusPrint = 0;
const unsigned long STATUS_INTERVAL_MS = 1000;

// remembers if lora came up
// if it didnt we keep running so ble still works and we can see whats wrong
static bool loraOk = false;

void setupBLE() {
  Serial.println("BLE minimal receive test");
  Serial.println("ADVERTISING...");

  BLEDevice::init("PitchCom-Relay");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  // the app sends with write without response
  // so WRITE_NR has to be here or ios never actually delivers anything
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

  // turn on the t deck peripheral power rail
  // without this the lora chip is effectively dead
  Serial.println("[LoRa] Powering peripherals (BOARD_POWERON)...");
  pinMode(BOARD_POWERON, OUTPUT);
  digitalWrite(BOARD_POWERON, HIGH);
  delay(200);

  // deselect everything else on the shared bus so only the radio is listening
  Serial.println("[LoRa] Deselecting TFT + SD + LoRa (shared SPI bus)...");
  pinMode(BOARD_TFT_CS, OUTPUT);
  digitalWrite(BOARD_TFT_CS, HIGH);

  pinMode(BOARD_SDCARD_CS, OUTPUT);
  digitalWrite(BOARD_SDCARD_CS, HIGH);

  pinMode(LORA_CS, OUTPUT);
  digitalWrite(LORA_CS, HIGH);
  delay(50);

  // reset the radio so it starts from a known state
  Serial.println("[LoRa] Hardware reset SX1262...");
  pinMode(LORA_RST, OUTPUT);
  digitalWrite(LORA_RST, LOW);
  delay(20);
  digitalWrite(LORA_RST, HIGH);
  delay(200);

  // the radio is not on the default spi pins so we have to give them explicitly
  Serial.println("[LoRa] Starting SPI...");
  SPI.begin(LORA_SPI_SCK, LORA_SPI_MISO, LORA_SPI_MOSI);

  // keep cs high until radiolib is ready to talk to it
  digitalWrite(LORA_CS, HIGH);
  delay(10);

  // bring up the radio with the shared settings
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

  // dio2 controls the rf switch on this board
  // crc lets the watch throw away packets that got mangled
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
  // status line so we can watch it in the serial monitor
  if (millis() - lastStatusPrint >= STATUS_INTERVAL_MS) {
    lastStatusPrint = millis();
    Serial.print("STATE=");
    Serial.print(deviceConnected ? "CONNECTED" : "WAITING");
    Serial.print(" | MSG=");
    Serial.print(messageReceived ? "YES" : "NO");
    Serial.print(" | LORA=");
    Serial.println(loraOk ? "OK" : "FAIL");
  }

  // when the phone writes something send that exact text over lora
  // the flag gets cleared first so we only send each message once
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

  // tiny pause so the ble stack gets time to run
  delay(1);
}