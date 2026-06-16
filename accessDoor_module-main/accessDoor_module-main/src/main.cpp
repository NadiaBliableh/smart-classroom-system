#include <Arduino.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>

#include "config.h"
#include "wifi_manager.h"
#include "mqtt_client.h"
#include "access_control.h"

// ─── LCD ─────────────────────────────────────────
LiquidCrystal_I2C lcd(0x27, 20, 4);

// ─── QR Serial ───────────────────────────────────
HardwareSerial QRSerial(2);

// ─── Keypad ──────────────────────────────────────
const byte ROWS = 4, COLS = 4;
char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};
byte rowPins[ROWS] = {27,14,12,13};
byte colPins[COLS] = {32,33,25,26};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

String inputCode = "";

// ════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  QRSerial.begin(9600, SERIAL_8N1, QR_RX_PIN, -1);

  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(3, 1);
  lcd.print("Connecting...");

  connectWiFi();
  initMQTT();
  showHome();
}

// ════════════════════════════════════════════════
void loop() {
  mqttLoop();
  checkTimeout();

  // ── Keypad ──────────────────────────────────
  char key = keypad.getKey();
  if (key) {
    if (key == '#') {
      if (inputCode.length() > 0) checkDoctorPin(inputCode);
      inputCode = "";
    }
    else if (key == '*') {
      inputCode = "";
      showHome();
    }
    else {
      if (inputCode.length() < 6) {
        inputCode += key;
        lcd.clear();
        lcd.setCursor(6, 1);
        lcd.print("Enter PIN");
        String stars = "";
        for (int i = 0; i < (int)inputCode.length(); i++) stars += "*";
        lcd.setCursor((20 - stars.length()) / 2, 2);
        lcd.print(stars);
      }
    }
  }

  // ── QR Scanner ──────────────────────────────
  if (QRSerial.available()) {
    String qrData = "";
    while (QRSerial.available()) {
      qrData += (char)QRSerial.read();
      delay(5);
    }
    qrData.trim();
    if (qrData.length() > 0) checkStudentAccess(qrData);
  }

  // ── Button (خروج) ────────────────────────────
  if (digitalRead(BUTTON_PIN) == LOW) {
    openLock("Door Open", "Exit");
    delay(300);
  }
}