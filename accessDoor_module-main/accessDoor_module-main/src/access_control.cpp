#include "access_control.h"
#include "mqtt_client.h"
#include "config.h"
#include <LiquidCrystal_I2C.h>

extern LiquidCrystal_I2C lcd;

static bool  waitingForResponse = false;
static unsigned long requestTime = 0;
const unsigned long TIMEOUT = 10000; // 10 ثواني timeout

// ─── مساعد ───────────────────────────────────────
static void printCentered(int row, String text) {
  int col = (20 - (int)text.length()) / 2;
  if (col < 0) col = 0;
  lcd.setCursor(col, row);
  lcd.print(text);
}

// ─── الشاشة الرئيسية ─────────────────────────────
void showHome() {
  waitingForResponse = false;
  lcd.clear();
  printCentered(1, "Scan Student");
  printCentered(2, "Or Enter PIN");
}

// ─── فتح القفل ───────────────────────────────────
void openLock(String line1, String line2) {
  waitingForResponse = false;
  lcd.clear();
  printCentered(1, line1);
  printCentered(2, line2);
  
  digitalWrite(RELAY_PIN, HIGH);
  delay(5000);
  digitalWrite(RELAY_PIN, LOW);
  
  // هون بتصير الخربشة ↑ بعد هاد السطر مباشرة
  delay(300);      // انتظر تهدأ الضوضاء
  lcd.init();      // أعد تهيئة LCD
  lcd.backlight();
  
  showHome();
}

// ─── رفض الدخول ──────────────────────────────────
void denyAccess(String reason) {
  waitingForResponse = false;
  lcd.clear();
  printCentered(1, reason);
  delay(2000);
  showHome();
}

// ─── Callbacks من MQTT ───────────────────────────
void onAccessResponse(bool granted, String name, String reason) {
  if (!waitingForResponse) return;
  waitingForResponse = false;

  if (granted) {
    openLock("Welcome!", name.substring(0, 18));
  } else {
    if      (reason == "No Active Lecture") denyAccess("No Lecture Now");
    else if (reason == "Not Enrolled")       denyAccess("Not Enrolled");
    else if (reason == "Wrong PIN")          denyAccess("Wrong PIN");
    else                                     denyAccess("Access Denied");
  }
}

void onDoorCommand(bool openDoor) {
  if (openDoor) openLock("Remote Open", "WELCOME");
}

// ─── فحص طلب الدخول ──────────────────────────────
void checkStudentAccess(String studentId) {
  if (waitingForResponse) return;
  Serial.print("Student: "); Serial.println(studentId);

  lcd.clear();
  printCentered(1, "Checking...");

  waitingForResponse = true;
  requestTime = millis();
  sendAccessRequest("card", studentId);
}

void checkDoctorPin(String pin) {
  if (waitingForResponse) return;
  Serial.print("PIN: "); Serial.println(pin);

  lcd.clear();
  printCentered(1, "Checking...");

  waitingForResponse = true;
  requestTime = millis();
  sendAccessRequest("pin", pin);
}

// ─── timeout check - استدعيها من loop ────────────
void checkTimeout() {
  if (waitingForResponse && millis() - requestTime > TIMEOUT) {
    denyAccess("Server Timeout");
  }
}