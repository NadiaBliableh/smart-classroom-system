#pragma once
#include <IPAddress.h>

// ─── WiFi ────────────────────────────────────────
#define WIFI_SSID           "nadia"
#define WIFI_PASSWORD       "12345678"

// ─── Network ─────────────────────────────────────
#define IP_THIS_ESP32       192,168,2,104
#define IP_GATEWAY          192,168,2,1
#define IP_SUBNET           255,255,255,0
#define IP_DNS              192,168,2,1

// ─── MQTT ────────────────────────────────────────
#define MQTT_BROKER         "192.168.2.101"
#define MQTT_PORT           1883
#define MQTT_CLIENT_ID      "esp32-temperature"

// ─── MQTT Topics ─────────────────────────────────
#define TOPIC_TEMP_DATA     "room/Room101/temperature/data"
#define TOPIC_TEMP_CMD      "room/Room101/temperature/command"

// ─── Room ─────────────────────────────────────────
#define ROOM_ID             "Room101"

// ─── DHT Sensor ──────────────────────────────────
#define DHTPIN              4
#define DHTTYPE             DHT22

// ─── SCD41 (CO2 Sensor) ──────────────────────────
#define SDA_PIN             21    // Default ESP32 SDA
#define SCL_PIN             22    // Default ESP32 SCL
#define CO2_ALARM_THRESHOLD 1000  // ppm - حد الإنذار
#define CO2_DANGER_THRESHOLD 2000 // ppm - خطر عالي

// ─── Relay Pins (HIGH = OFF, LOW = ON) ───────────
#define RELAY1_PIN          25   // Speed 1
#define RELAY2_PIN          26   // Speed 2
#define RELAY3_PIN          27   // Speed 3
#define RELAY4_PIN          14   // Speed 4
#define RELAY5_PIN          13   // Speed 5

// ─── Fan Speed Thresholds ────────────────────────
#define TEMP_OFF            24.0
#define TEMP_SPEED1         24.0
<<<<<<< HEAD
#define TEMP_SPEED2         27.0
#define TEMP_SPEED3         31.0

=======
#define TEMP_SPEED2         28.0
#define TEMP_SPEED3         32.0
//#define TEMP_SPEED4         30.0
//#define TEMP_SPEED5         32.0
>>>>>>> 91785e73d664d10e66c46820f74b57ee6c31281b

// ─── Intervals ───────────────────────────────────
#define SEND_INTERVAL       5000   // بعث بيانات كل 5 ثواني
#define READ_INTERVAL       2000   // قراءة sensor كل 2 ثواني
#define CMD_INTERVAL        3000   // فحص أوامر كل 3 ثواني