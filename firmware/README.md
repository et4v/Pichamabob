# Firmware

Two PlatformIO projects, one per device. Open each folder on its own in VS Code with the
PlatformIO extension, or use the `pio` CLI from inside the folder.

| Project | Device | Role |
|---|---|---|
| [`tdeck-relay/`](tdeck-relay/) | LilyGO T-Deck Plus | Advertises over BLE as `PitchCom-Relay`, receives text from the app, transmits it over LoRa |
| [`twatch-receiver/`](twatch-receiver/) | LilyGO T-Watch S3 (SX1262) | Receives LoRa packets and shows them on the screen |

## Flashing

```bash
cd firmware/twatch-receiver
pio run -t upload && pio device monitor
```

```bash
cd firmware/tdeck-relay
pio run -t upload && pio device monitor
```

Expected serial output on the T-Deck once the phone connects and sends a call:

```
BLE RX: Fast TL
[TX] BLE->LoRa msg: Fast TL
[TX] OK!
```

On the watch:

```
*** PACKET RECEIVED ***
  Data: Fast TL
  RSSI: -45.0 dBm | SNR: 10.5 dB
```

## Radio settings

These are defined at the top of each `main.cpp` and **must match on both devices**:

| Setting | Value |
|---|---|
| Frequency | 915.0 MHz (US; use 868.0 in the EU) |
| Bandwidth | 125 kHz |
| Spreading factor | 9 |
| Coding rate | 4/7 |
| Sync word | 0x12 |
| TX power | 14 dBm |

Pin assignments are set as `-D` build flags in each `platformio.ini`.

## BLE protocol (app ↔ T-Deck)

| | UUID |
|---|---|
| Service | `19B10000-E8F2-537E-4F6C-D104768A1214` |
| Signal characteristic (write / write without response) | `19B10001-E8F2-537E-4F6C-D104768A1214` |

Payload: ASCII text `"<pitch> <location>"`, e.g. `Fast TL`. Pitch is `Fast`, `Curve` or `Slider`.
Location is a 3×3 grid: `TL TM TR / ML MM MR / BL BM BR`.

## Troubleshooting

- **`SX1262 FAILED! Error: -2` (chip not found):** wrong pins, or the radio has no power. On the
  T-Deck, GPIO10 (`BOARD_POWERON`) has to go HIGH, and the display and SD card chip-selects must
  be HIGH before the radio starts.
- **Both radios start but nothing is received:** check that both antennas are attached, that the
  radio settings above match, and try with the devices next to each other.
- **CRC errors:** the link works but packets are getting corrupted. Move the devices closer
  together or raise the spreading factor on both.
- **The app can't find the relay:** make sure the T-Deck serial output shows `ADVERTISING...`.
  It starts advertising again on its own after a disconnect.
