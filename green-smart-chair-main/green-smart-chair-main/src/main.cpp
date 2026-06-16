#include <Arduino.h>
#include "config.h"
#include "wifi_manager.h"
#include "chair_control.h"
#include "mqtt_client.h"

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("=== Green Chair Module ===");

  connectWiFi();
  initChair();
  calibrateGyro();
  initMQTT();

  sendChairStatus();

  Serial.println("Green Chair Ready! Waiting for commands...");
}

void loop() {
  mqttLoop();
}