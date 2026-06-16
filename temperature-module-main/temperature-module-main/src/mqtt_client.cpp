#include "mqtt_client.h"
#include "temp_control.h"
#include "config.h"
#include <PubSubClient.h>
#include <WiFi.h>
#include <ArduinoJson.h>

static WiFiClient   wifiClient;
static PubSubClient mqttClient(wifiClient);

// ─── استقبال أوامر من الـ Raspberry ──────────────
static void onMessage(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];
  Serial.print("MQTT IN: "); Serial.println(msg);

  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, msg)) return;

  if (doc.containsKey("mode")) {
    String mode = doc["mode"].as<String>();
    if      (mode == "auto")   setTempMode(TEMP_AUTO);
    else if (mode == "manual") setTempMode(TEMP_MANUAL);
  }

  if (doc.containsKey("fanOff") && doc["fanOff"].as<bool>()) {
    setFanOff();
    return;
  }

  if (doc.containsKey("fanSpeed")) {
    setFanSpeed(doc["fanSpeed"].as<int>());
  }

  if (doc.containsKey("occupied")) {
    setOccupied(doc["occupied"].as<bool>());
  }
}

// ─── إعادة الاتصال ────────────────────────────────
static void reconnect() {
  int tries = 0;
  while (!mqttClient.connected() && tries < 5) {
    Serial.print("Connecting to MQTT...");
    if (mqttClient.connect(MQTT_CLIENT_ID)) {
      Serial.println("connected!");
      mqttClient.subscribe(TOPIC_TEMP_CMD);
    } else {
      Serial.print("failed rc="); Serial.println(mqttClient.state());
      delay(2000);
      tries++;
    }
  }
}

// ─── تهيئة ───────────────────────────────────────
void initMQTT() {
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(onMessage);
  mqttClient.setKeepAlive(30);
  reconnect();
}

// ─── Loop ─────────────────────────────────────────
void mqttLoop() {
  if (!mqttClient.connected()) reconnect();
  mqttClient.loop();
}

// ─── تحديد نص مستوى CO2 ──────────────────────────
static const char* co2LevelStr() {
  switch (getCo2Level()) {
    case CO2_WARNING: return "warning";
    case CO2_DANGER:  return "danger";
    default:          return "normal";
  }
}

// ─── بعث البيانات للـ Raspberry ──────────────────
void sendTempData() {
  if (!mqttClient.connected()) return;

  StaticJsonDocument<512> doc;
  doc["roomId"]      = ROOM_ID;
  doc["temp"]        = getCurrentTemp();
  doc["humidity"]    = getCurrentHumidity();
  doc["fanSpeed"]    = getCurrentSpeed();
  doc["fanStatus"]   = getCurrentSpeed() > 0 ? "on" : "off";
  doc["mode"]        = getCurrentTempMode() == TEMP_AUTO ? "auto" : "manual";
  doc["relay1"]      = !digitalRead(RELAY1_PIN);
  doc["relay2"]      = !digitalRead(RELAY2_PIN);
  doc["relay3"]      = !digitalRead(RELAY3_PIN);
  doc["relay4"]      = !digitalRead(RELAY4_PIN);
  doc["relay5"]      = !digitalRead(RELAY5_PIN);

  // CO2 data
  doc["co2"]         = getCurrentCO2();
  doc["co2Level"]    = co2LevelStr();
  doc["co2Alarm"]    = isCo2AlarmActive();

  String msg;
  serializeJson(doc, msg);
  mqttClient.publish(TOPIC_TEMP_DATA, msg.c_str());
  Serial.print("Temp data sent: "); Serial.println(msg);
}