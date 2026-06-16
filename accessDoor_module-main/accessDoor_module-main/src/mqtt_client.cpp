#include "mqtt_client.h"
#include "config.h"
#include <PubSubClient.h>
#include <WiFi.h>
#include <ArduinoJson.h>

static WiFiClient   wifiClient;
static PubSubClient mqttClient(wifiClient);

// ─── استقبال رسائل MQTT ───────────────────────────
static void onMessage(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];
  Serial.print("MQTT IN ["); Serial.print(topic); Serial.print("]: ");
  Serial.println(msg);

  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, msg)) return;

  String t = String(topic);

  // ── رد على طلب الدخول ──────────────────────────
  if (t == TOPIC_ACCESS_RESPONSE) {
    bool   granted = doc["access"].as<bool>();
    String name    = doc["name"].as<String>();
    String reason  = doc["reason"].as<String>();
    onAccessResponse(granted, name, reason);
  }

  // ── أمر فتح الباب من Firebase ──────────────────
  else if (t == TOPIC_ACCESS_COMMAND) {
    bool openDoor = doc["openDoor"].as<bool>();
    if (openDoor) onDoorCommand(true);
  }
}

// ─── إعادة الاتصال ───────────────────────────────
static void reconnect() {
  int tries = 0;
  while (!mqttClient.connected() && tries < 5) {
    Serial.print("Connecting to MQTT...");
    if (mqttClient.connect(MQTT_CLIENT_ID)) {
      Serial.println("connected!");
      mqttClient.subscribe(TOPIC_ACCESS_RESPONSE);
      mqttClient.subscribe(TOPIC_ACCESS_COMMAND);
    } else {
      Serial.print("failed, rc=");
      Serial.println(mqttClient.state());
      delay(2000);
      tries++;
    }
  }
}

// ─── تهيئة MQTT ──────────────────────────────────
void initMQTT() {
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(onMessage);
  mqttClient.setKeepAlive(30);
  reconnect();
}

// ─── loop ─────────────────────────────────────────
void mqttLoop() {
  if (!mqttClient.connected()) reconnect();
  mqttClient.loop();
}

// ─── بعث طلب دخول ────────────────────────────────
void sendAccessRequest(String type, String value) {
  StaticJsonDocument<128> doc;
  doc["type"]  = type;   // "card" or "pin"
  doc["value"] = value;

  String msg;
  serializeJson(doc, msg);

  mqttClient.publish(TOPIC_ACCESS_REQUEST, msg.c_str());
  Serial.print("Access request sent: "); Serial.println(msg);
}