#pragma once
#include <IPAddress.h>

// ─── WiFi ────────────────────────────────────────
#define WIFI_SSID           "nadia"
#define WIFI_PASSWORD       "12345678"

// ─── Network ─────────────────────────────────────
#define IP_THIS_ESP32       192,168,2,102
#define IP_GATEWAY          192,168,2,1
#define IP_SUBNET           255,255,255,0
#define IP_DNS              192,168,2,1

// ─── MQTT ────────────────────────────────────────
#define MQTT_BROKER         "192.168.2.101"
#define MQTT_PORT           1883
#define MQTT_CLIENT_ID      "esp32-access"

// ─── MQTT Topics ─────────────────────────────────
#define TOPIC_ACCESS_REQUEST   "room/Room101/access/request"
#define TOPIC_ACCESS_RESPONSE  "room/Room101/access/response"
#define TOPIC_ACCESS_COMMAND   "room/Room101/access/command"

// ─── Room ─────────────────────────────────────────
#define ROOM_ID             "Room101"

// ─── Hardware Pins ────────────────────────────────
#define RELAY_PIN           23
#define BUTTON_PIN          19
#define QR_RX_PIN           16