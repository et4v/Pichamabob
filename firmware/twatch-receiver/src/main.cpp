/*
 * T-Watch S3 — LoRa receiver
 * Listens for pitch calls relayed by the T-Deck and shows them on screen.
 */

#include <Arduino.h>
#include <SPI.h>
#include <RadioLib.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>

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
// Forward declarations
// ============================================================
void receiverLoop();

// ============================================================
// Radio — use default SPI bus (this is what LilyGO examples do)
// ============================================================
Module radioModule(LORA_CS, LORA_DIO1, LORA_RST, LORA_BUSY);
SX1262 radio(&radioModule);

// TFT display pins (T-Watch S3 screen)
#define TFT_MOSI  13
#define TFT_SCLK  18
#define TFT_CS    12
#define TFT_DC    38
#define TFT_BL    45

// Use explicit SPI bus
SPIClass tftSpi(1);
Adafruit_ST7789 tft(&tftSpi, TFT_CS, TFT_DC, -1);

// ============================================================
// Setup
// ============================================================
void setup() {
    Serial.begin(115200);
    delay(3000);
    Serial.println("\n=== DISPLAY TEST ===\n");

    // Backlight
    Serial.println("Backlight ON...");
    pinMode(TFT_BL, OUTPUT);
    digitalWrite(TFT_BL, HIGH);
    delay(100);

    // Start SPI
    Serial.printf("SPI begin — SCLK:%d MOSI:%d\n", TFT_SCLK, TFT_MOSI);
    tftSpi.begin(TFT_SCLK, -1, TFT_MOSI, TFT_CS);

    // Init display
    Serial.println("tft.init(240, 240)...");
    tft.init(240, 240);
    tft.setRotation(0);
    Serial.println("Fill screen BLACK...");
    tft.fillScreen(ST77XX_BLACK);
    delay(500);

    // Flash red, then blue, so you can see the screen is working
    Serial.println("Fill screen RED...");
    tft.fillScreen(ST77XX_RED);
    delay(1000);

    Serial.println("Fill screen BLUE...");
    tft.fillScreen(ST77XX_BLUE);
    delay(1000);

    Serial.println("Fill screen BLACK + text...");
    tft.fillScreen(ST77XX_BLACK);
    tft.setTextColor(ST77XX_WHITE);
    tft.setTextSize(3);
    tft.setCursor(30, 100);
    tft.println("HELLO!");

    Serial.println("\n=== DONE ===");
    Serial.println("You should see: RED -> BLUE -> 'HELLO!' on black");
    Serial.println("If screen is dark, check backlight pin.");
    Serial.println("If screen is white/garbage, try SPI_MODE3.");

    unsigned long waitStart = millis();
    while (!Serial && (millis() - waitStart < 5000)) {
        delay(100);
    }

    Serial.println("\n========================================");
    Serial.println("  T-Watch S3 — LoRa RECEIVER");
    Serial.println("========================================\n");

    // ----------------------------------------------------------
    // STEP 1: Hardware reset the SX1262
    // ----------------------------------------------------------
    Serial.println("[Step 1] Hardware reset SX1262...");
    pinMode(LORA_RST, OUTPUT);
    digitalWrite(LORA_RST, LOW);
    delay(20);
    digitalWrite(LORA_RST, HIGH);
    delay(200);
    Serial.println("[Step 1] Reset complete");

    // ----------------------------------------------------------
    // STEP 2: Print config
    // ----------------------------------------------------------
    Serial.println("\n[Config] Pins:");
    Serial.printf("  MOSI:%d  MISO:%d  SCK:%d\n", LORA_SPI_MOSI, LORA_SPI_MISO, LORA_SPI_SCK);
    Serial.printf("  CS:%d  RST:%d  DIO1:%d  BUSY:%d\n", LORA_CS, LORA_RST, LORA_DIO1, LORA_BUSY);
    Serial.printf("[Config] Freq:%.1f BW:%.1f SF:%d CR:4/%d Sync:0x%02X Power:%d\n\n",
        LORA_FREQUENCY, LORA_BANDWIDTH, LORA_SPREAD_FACT, LORA_CODING_RATE, LORA_SYNC_WORD, LORA_TX_POWER);

    // ----------------------------------------------------------
    // STEP 3: Init SPI (default SPI object, as LilyGO uses)
    // ----------------------------------------------------------
    Serial.println("[Step 3] Starting SPI...");
    SPI.begin(LORA_SPI_SCK, LORA_SPI_MISO, LORA_SPI_MOSI);
    Serial.println("[Step 3] SPI OK");

    // ----------------------------------------------------------
    // STEP 4: Init SX1262
    // ----------------------------------------------------------
    Serial.println("[Step 4] Initializing SX1262...");
    int state = radio.begin(
        LORA_FREQUENCY, LORA_BANDWIDTH, LORA_SPREAD_FACT,
        LORA_CODING_RATE, LORA_SYNC_WORD, LORA_TX_POWER, LORA_PREAMBLE
    );

    if (state == RADIOLIB_ERR_NONE) {
        Serial.println("\n*** SUCCESS! SX1262 initialized! ***\n");
    } else {
        Serial.printf("\n*** SX1262 FAILED! Error: %d ***\n\n", state);
        Serial.println("  -2   = Chip not found");
        Serial.println("  -6   = SPI command failed");
        Serial.println("  -20  = SPI timeout (no power?)");
        Serial.println("  -706 = SPI cmd failed (bus conflict?)");
        Serial.println("  -707 = Busy timeout (BUSY pin wrong?)");
        Serial.println("\nHALTED.");
        while (true) { delay(1000); }
    }

    // ----------------------------------------------------------
    // STEP 5: Radio config
    // ----------------------------------------------------------
    radio.setCurrentLimit(60.0);
    radio.setDio2AsRfSwitch(true);
    radio.setCRC(2);

    Serial.println("[Ready] Listening for packets...\n");
}

// ============================================================
void loop() {
    receiverLoop();
}

// ============================================================
void receiverLoop() {
    String incoming;
    int state = radio.receive(incoming);
    if (state == RADIOLIB_ERR_NONE) {
        Serial.println("*** PACKET RECEIVED ***");
        Serial.printf("  Data: %s\n", incoming.c_str());
        Serial.printf("  RSSI: %.1f dBm | SNR: %.1f dB\n\n", radio.getRSSI(), radio.getSNR());
        tft.fillScreen(ST77XX_GREEN);
        tft.setTextColor(ST77XX_WHITE);
        tft.setTextSize(3);
        tft.setCursor(30, 100);
        tft.println(incoming.c_str());
    } else if (state == RADIOLIB_ERR_CRC_MISMATCH) {
        Serial.println("[RX] CRC error (radio works, packet corrupted)");
    } else if (state == RADIOLIB_ERR_RX_TIMEOUT) {
        // Normal — no packet yet, just loop again
    } else {
        Serial.printf("[RX] Error: %d\n", state);
    }
}
