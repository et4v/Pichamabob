#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLECharacteristic.h>
#include <string>

#include "ble_state.h"

// shared flags used by main
bool deviceConnected = false;
volatile bool messageReceived = false;
String bleMessage = "";

// called automatically when a phone connects over BLE
void ServerCallbacks::onConnect(BLEServer* /*pServer*/) {
  deviceConnected = true;
  Serial.println("BLE connected");
}

// called automatically when the phone disconnects
void ServerCallbacks::onDisconnect(BLEServer* /*pServer*/) {
  deviceConnected = false;
  Serial.println("BLE disconnected");

  // iOS likes a tiny pause before we re-advertise
  delay(200);

  // restart advertising so iOS can reconnect
  BLEDevice::startAdvertising();
  Serial.println("ADVERTISING...");
}

// called whenever the phone writes to the signal characteristic
void SignalCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
  std::string v = pCharacteristic->getValue();

  if (!v.empty()) {
    bleMessage = String(v.c_str());
    messageReceived = true;

    Serial.print("BLE RX: ");
    Serial.println(bleMessage);
  }
}