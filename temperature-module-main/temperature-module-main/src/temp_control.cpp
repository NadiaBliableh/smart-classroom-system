#include "temp_control.h"
#include "config.h"
#include <DHT.h>
#include <Wire.h>
#include <SensirionI2CScd4x.h>

DHT dht(DHTPIN, DHTTYPE);
SensirionI2CScd4x scd4x;

static float    currentTemp     = 0.0;
static float    currentHumidity = 0.0;
static int      currentSpeed    = 0;
static TempMode currentMode     = TEMP_AUTO;
static bool     occupied        = false;

// ✅ حماية من أوامر auto تطغى على manual
static bool     manualOverride  = false;

// SCD41
static uint16_t currentCO2      = 0;
static bool     co2AlarmActive  = false;
static unsigned long lastScdRead = 0;
#define SCD_MIN_INTERVAL 5100

// ─── تطبيق السرعة على الريليهات ──────────────────
static void applySpeed(int speed) {
  digitalWrite(RELAY1_PIN, HIGH);
  digitalWrite(RELAY2_PIN, HIGH);
  digitalWrite(RELAY3_PIN, HIGH);
 

<<<<<<< HEAD
 switch (speed) {
  case 1:
    digitalWrite(RELAY1_PIN, LOW);   // كاباسيتور 1.5 فقط
    break;
  case 2:
    digitalWrite(RELAY1_PIN, LOW);   // الكاباسيتورين مع بعض
    digitalWrite(RELAY2_PIN, LOW);
    break;
  case 3:
    digitalWrite(RELAY3_PIN, LOW);   // فل سرعة مباشر
    break;
  default:
    break;
}
=======
  switch (speed) {
    case 1: digitalWrite(RELAY1_PIN, LOW); break;
    case 2: digitalWrite(RELAY2_PIN, LOW); break;
    case 3: digitalWrite(RELAY3_PIN, LOW); break;
    case 4: digitalWrite(RELAY4_PIN, LOW); break;
    case 5: digitalWrite(RELAY5_PIN, LOW); break;
    default: break;
  }
>>>>>>> 91785e73d664d10e66c46820f74b57ee6c31281b
  currentSpeed = speed;
  Serial.print("Fan Speed: "); Serial.println(speed);
}

// ─── تهيئة ───────────────────────────────────────
void initTempControl() {
  dht.begin();

  Wire.begin(SDA_PIN, SCL_PIN);
  scd4x.begin(Wire);
  scd4x.stopPeriodicMeasurement();
  delay(500);
  scd4x.startPeriodicMeasurement();
  Serial.println("SCD41 started — waiting 5s for first reading...");

  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(RELAY3_PIN, OUTPUT);
  

  digitalWrite(RELAY1_PIN, HIGH);
  digitalWrite(RELAY2_PIN, HIGH);
  digitalWrite(RELAY3_PIN, HIGH);
  

  Serial.println("Temperature Control Initialized");
}

// ─── قراءة السنسور ───────────────────────────────
void readSensor() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (!isnan(t)) currentTemp     = t;
  if (!isnan(h)) currentHumidity = h;

  unsigned long now = millis();
  if (now - lastScdRead >= SCD_MIN_INTERVAL) {
    bool dataReady = false;
    int16_t err = scd4x.getDataReadyFlag(dataReady);
    if (err == 0 && dataReady) {
      uint16_t co2 = 0;
      float st = 0, sh = 0;
      err = scd4x.readMeasurement(co2, st, sh);
      if (err == 0 && co2 > 0) {
        currentCO2     = co2;
        lastScdRead    = now;
        co2AlarmActive = (currentCO2 >= CO2_ALARM_THRESHOLD);
        Serial.print("SCD41 CO2: "); Serial.print(currentCO2); Serial.println(" ppm");
      } else if (err != 0) {
        Serial.print("SCD41 readMeasurement error: "); Serial.println(err);
      }
    } else if (err != 0) {
      Serial.print("SCD41 getDataReadyFlag error: "); Serial.println(err);
    }
  }
 
  Serial.print("Temp: ");       Serial.print(currentTemp);
  Serial.print("C | Hum: ");    Serial.print(currentHumidity);
  Serial.print("% | CO2: ");    Serial.print(currentCO2);
  Serial.print("ppm | Speed:"); Serial.print(currentSpeed);
  Serial.print(" | Mode: ");    Serial.print(currentMode == TEMP_AUTO ? "AUTO" : "MANUAL");
  Serial.print(" | Override:"); Serial.print(manualOverride ? "YES" : "NO");
  Serial.print(" | CO2Alarm:"); Serial.print(co2AlarmActive ? "YES" : "NO");
  Serial.print(" | Occupied:"); Serial.println(occupied ? "YES" : "NO");
}

// ─── تطبيق منطق التحكم ───────────────────────────
void applyFanControl() {
  // ✅ إذا manual أو manualOverride → لا تتدخل
  if (currentMode == TEMP_MANUAL || manualOverride) return;

  if (!occupied) {
    if (currentSpeed != 0) applySpeed(0);
    return;
  }

  int newSpeed = 0;
<<<<<<< HEAD
=======
  //if      (currentTemp >= TEMP_SPEED5) newSpeed = 5;
  //else if (currentTemp >= TEMP_SPEED4) newSpeed = 4;
>>>>>>> 91785e73d664d10e66c46820f74b57ee6c31281b
  if (currentTemp >= TEMP_SPEED3) newSpeed = 3;
  else if (currentTemp >= TEMP_SPEED2) newSpeed = 2;
  else if (currentTemp >= TEMP_SPEED1) newSpeed = 1;
  else                                  newSpeed = 0;

  if (newSpeed != currentSpeed) applySpeed(newSpeed);
}

// ─── أوامر من MQTT ────────────────────────────────
void setTempMode(TempMode mode) {
  currentMode = mode;
  // ✅ بس عند AUTO الصريح نرفع الـ override
  if (mode == TEMP_AUTO) {
    manualOverride = false;
  }
  
  Serial.print("Temp Mode: ");
  Serial.print(mode == TEMP_AUTO ? "AUTO" : "MANUAL");
  Serial.print(" | Override: ");
  Serial.println(manualOverride ? "YES" : "NO");
  
}

void setFanSpeed(int speed) {
<<<<<<< HEAD
  if (speed < 0 || speed > 3) return;
=======
  if (speed < 0 || speed > 5) return;
>>>>>>> 91785e73d664d10e66c46820f74b57ee6c31281b
  currentMode    = TEMP_MANUAL;
  manualOverride = true;  // ✅ نمنع applyFanControl من التدخل
  applySpeed(speed);
  Serial.print("Manual override active — Speed: "); Serial.println(speed);
}

void setFanOff() {
  applySpeed(0);
  Serial.println("Fan OFF");
}

void setOccupied(bool val) {
  occupied = val;
}

// ─── Getters ─────────────────────────────────────
float    getCurrentTemp()      { return currentTemp;     }
float    getCurrentHumidity()  { return currentHumidity; }
int      getCurrentSpeed()     { return currentSpeed;    }
TempMode getCurrentTempMode()  { return currentMode;     }
bool     isOccupied()          { return occupied;        }
uint16_t getCurrentCO2()       { return currentCO2;      }
bool     isCo2AlarmActive()    { return co2AlarmActive;  }

Co2Level getCo2Level() {
  if (currentCO2 >= CO2_DANGER_THRESHOLD)  return CO2_DANGER;
  if (currentCO2 >= CO2_ALARM_THRESHOLD)   return CO2_WARNING;
  return CO2_NORMAL;
}