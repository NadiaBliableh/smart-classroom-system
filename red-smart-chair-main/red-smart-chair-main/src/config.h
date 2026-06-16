#pragma once
#include <IPAddress.h>

// ─── WiFi ────────────────────────────────────────
#define WIFI_SSID           "nadia"
#define WIFI_PASSWORD       "12345678"

// ─── Network ─────────────────────────────────────
#define IP_THIS_ESP32       192,168,2,105
#define IP_GATEWAY          192,168,2,1
#define IP_SUBNET           255,255,255,0
#define IP_DNS              192,168,2,1

// ─── MQTT ────────────────────────────────────────
#define MQTT_BROKER         "192.168.2.101"
#define MQTT_PORT           1883
#define MQTT_CLIENT_ID      "esp32-red-chair"

// ─── MQTT Topics ─────────────────────────────────
#define TOPIC_CMD           "room/Room101/chair/red/command"
#define TOPIC_STATUS        "room/Room101/chair/red/status"

// ─── Chair Identity ──────────────────────────────
#define CHAIR_ID            "redChair"
#define CHAIR_SIDE          "red"
#define ROOM_ID             "Room101"

// ─── Motor Pins ──────────────────────────────────
#define MOTOR1_PIN1         12
#define MOTOR1_PIN2         14
#define ENABLE1_PIN         13
#define MOTOR2_PIN1         27
#define MOTOR2_PIN2         26
#define ENABLE2_PIN         25

// ─── Motor Settings ──────────────────────────────
#define MOTOR_FREQ          30000
#define MOTOR_RESOLUTION    8
#define MOTOR_SPEED         240    // 0-255
#define GYRO_THRESHOLD      1.5    // تجاهل الضجيج

// ─── Distance & Speed Settings ───────────────────
#define CM_PER_SECOND       7.5    // سرعة الكرسي الأحمر
#define MS_PER_CM           133    // 1سم = 133ms

#define DIST_LECTURE        15     // سم
#define DIST_EXAM           40     // سم
#define DIST_GROUP          50     // سم

// ─── Target Angles per Mode ──────────────────────
// lecture → 0°
// exam    → 0°
// group   → red=90°, green=270°