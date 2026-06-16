# Smart Classroom Access System

An ESP32-based access control module for smart classrooms. Students authenticate via **QR code / NFC card**, doctors via **PIN pad**. All access decisions are handled by a Raspberry Pi server over **MQTT** on a local network. A relay-driven **electromagnetic lock** physically controls door entry.

---

## System Architecture

```
[QR Scanner]  ──┐
[Keypad 4×4]  ──┤──▶  [ESP32]  ──MQTT──▶  [Raspberry Pi]
[Exit Button] ──┘         │                     │
                          │                     │ verify lecture
                    [LCD 20×4]          ◀── access response
                          │
                    [Relay] ──▶ [EM Lock]
```

**Access flow:**

1. Student scans QR / Doctor enters PIN
2. ESP32 publishes an access request over MQTT
3. Raspberry Pi checks active lectures and enrollment
4. ESP32 receives `granted` or `denied` response
5. On grant → relay energizes EM lock for 5 seconds

---

## File Structure

```
src/
├── main.cpp              # setup(), loop(), keypad & QR handling
├── access_control.cpp/h  # LCD display, lock control, timeout logic
├── mqtt_client.cpp/h     # MQTT connect, publish, subscribe, callbacks
├── wifi_manager.cpp/h    # WiFi with static IP configuration
└── config.h              # All settings, credentials, pin definitions
platformio.ini            # Build configuration
```

---

## Hardware & Pins

| GPIO | Label        | Description                        |
|------|--------------|------------------------------------|
| 23   | RELAY_PIN    | Electromagnetic lock relay output  |
| 19   | BUTTON_PIN   | Interior exit button (INPUT_PULLUP)|
| 16   | QR_RX_PIN    | UART2 RX ← QR Scanner (9600 baud) |
| 27, 14, 12, 13 | Keypad ROWS | 4×4 keypad row pins      |
| 32, 33, 25, 26 | Keypad COLS | 4×4 keypad column pins   |

**LCD:** 20×4 I2C display at address `0x27`

---

## Network Configuration

| Parameter   | Value            |
|-------------|------------------|
| ESP32 IP    | 192.168.2.102    |
| MQTT Broker | 192.168.2.101    |
| Gateway     | 192.168.2.1      |
| Subnet      | 255.255.255.0    |
| WiFi SSID   | nadia            |
| MQTT Port   | 1883             |

---

## MQTT Topics

| Topic                              | Direction | Payload fields                        |
|------------------------------------|-----------|---------------------------------------|
| `room/Room101/access/request`      | ESP32 → Pi | `{ type, value }`                    |
| `room/Room101/access/response`     | Pi → ESP32 | `{ access, name, reason }`           |
| `room/Room101/access/command`      | Pi → ESP32 | `{ openDoor: true }`                 |

**Request types:**
- `type: "card"` — QR or NFC card scan, `value` = student ID
- `type: "pin"` — keypad entry, `value` = PIN string

**Denial reasons:**
- `No Active Lecture` → displays *"No Lecture Now"*
- `Not Enrolled` → displays *"Not Enrolled"*
- `Wrong PIN` → displays *"Wrong PIN"*
- Anything else → displays *"Access Denied"*

---

## Keypad Usage

| Key     | Action                                  |
|---------|-----------------------------------------|
| `0–9`   | Append digit to PIN (max 6 digits)      |
| `#`     | Confirm and submit PIN                  |
| `*`     | Clear input, return to home screen      |

---

## Dependencies (PlatformIO)

```ini
lib_deps =
  marcoschwartz/LiquidCrystal_I2C
  chris--a/Keypad
  bblanchon/ArduinoJson@^7.0.0
  knolleary/PubSubClient@^2.8
```

---

## Getting Started

**Prerequisites:**
- PlatformIO installed (VS Code extension or CLI)
- Mosquitto (or any MQTT broker) running on the Raspberry Pi at port 1883
- Raspberry Pi server listening on the request topic and publishing responses

**Steps:**

1. Clone or copy the project.
2. Open `config.h` and update WiFi credentials and IP addresses for your network.
3. Connect hardware according to the GPIO table above.
4. Build and flash:
   ```
   pio run --target upload
   ```
5. Open Serial Monitor at **115200 baud** to watch logs.

---

## Technical Notes

- **Request timeout:** If the Raspberry Pi does not respond within **10 seconds**, the display shows *"Server Timeout"* and resets to the home screen.
- **LCD re-init after unlock:** The LCD is re-initialized after every lock cycle (`lcd.init()`) to clear corruption caused by relay switching noise on the I2C bus.
- **MQTT keep-alive:** Set to 30 seconds with automatic reconnection (up to 5 retries).
- **Static IP:** The ESP32 uses a fixed IP to ensure stable MQTT connectivity on the local network.
- **Remote open:** The Raspberry Pi (or a Firebase-connected backend) can push `{ openDoor: true }` to the command topic to unlock the door remotely without a card or PIN.
- **Exit button:** GPIO 19 opens the lock immediately from the inside, bypassing MQTT entirely.

---

## Room Configuration

The room ID is defined in `config.h`:

```cpp
#define ROOM_ID "Room101"
```

All MQTT topics are prefixed with `room/{ROOM_ID}/`, making it straightforward to deploy multiple ESP32 units for different classrooms by changing this single constant.

---

## License

MIT — free to use and modify for educational and research purposes.
