#include <Arduino.h>
#include "config.h"
#include "wifi_manager.h"
#include "temp_control.h"
#include "mqtt_client.h"

unsigned long lastSendTime = 0;
unsigned long lastReadTime = 0;

void setup() {
  pinMode(2, OUTPUT);
  digitalWrite(2, LOW);

  Serial.begin(115200);
  delay(1000);


  
  connectWiFi();
  initTempControl();
  initMQTT();
  Serial.println("Temperature Module Ready!");
}

void loop() {
  mqttLoop();

  unsigned long now = millis();

  // قراءة السنسور كل 2 ثانية
  if (now - lastReadTime >= READ_INTERVAL) {
    lastReadTime = now;
    readSensor();
    applyFanControl();
  }

  // بعث البيانات كل 5 ثواني
  if (now - lastSendTime >= SEND_INTERVAL) {
    lastSendTime = now;
    sendTempData();
  }
}