#ifndef BLE_STATE_H
#define BLE_STATE_H

#include <Arduino.h>
#include <BLEServer.h>
#include <BLECharacteristic.h>

// these variables are shared between ble callbacks and main
// they are defined in ble_state cpp not in this file
// deviceConnected tells us whether the phone is currently connected
// messageReceived is flipped when the phone writes new data
extern bool deviceConnected;
extern volatile bool messageReceived;
extern String bleMessage;   // last message received from phone

// server callbacks handle connection level events
// this is how we know when a phone connects or disconnects
class ServerCallbacks : public BLEServerCallbacks {
  // called automatically when a client connects
  // used to mark deviceConnected true
  void onConnect(BLEServer* pServer) override;

  // called automatically when a client disconnects
  // used to mark deviceConnected false and resume advertising
  void onDisconnect(BLEServer* pServer) override;
};

// characteristic callbacks handle actual data writes
// this is where messages sent from the phone arrive
class SignalCallbacks : public BLECharacteristicCallbacks {
  // called whenever the phone writes to the characteristic
  // sets messageReceived so main can react
  void onWrite(BLECharacteristic* pCharacteristic) override;
};

#endif