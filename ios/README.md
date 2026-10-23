# Pichamabob — iOS app

SwiftUI coach app. Open `Pichamabob.xcodeproj` in Xcode.

## Tabs

- **Signal:** pick a pitch (Fast / Curve / Slider), then a location on a 3×3 grid. Sends the call to the T-Deck over BLE and keeps a history.
- **Bluetooth:** connect to or disconnect from the `PitchCom-Relay` T-Deck.
- **Statistics:** pitcher list and per-pitcher stats from the backend.
- **Games:** game list from the backend.

## Running

1. Select your own team under **Signing & Capabilities** (the project has the original developer's team).
2. Run on a **real iPhone**. Bluetooth doesn't work in the simulator.
3. For Statistics and Games, start the [backend](../backend/README.md) and set `apiBaseURL` at the
   top of `Pichamabob/ContentView.swift` to your ngrok URL.

## Code

| File | Purpose |
|---|---|
| `Pichamabob/BLEManager.swift` | Scans for, connects to and writes to the T-Deck relay (UUIDs must match the firmware) |
| `Pichamabob/ContentView.swift` | All screens, plus the JSON models for the backend |
| `Pichamabob/PichamabobApp.swift` | App entry point |
