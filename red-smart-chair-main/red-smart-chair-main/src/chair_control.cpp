#include "chair_control.h"
#include "config.h"
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

Adafruit_MPU6050 mpu;

static float       gyroBiasX    = 0;
static int         currentAngle = 0;
static ChairStatus chairStatus  = STATUS_IDLE;
static String      currentMode  = "lecture";

// ════════════════════════════════════════════════════════════
//  زوايا الكرسي الأحمر حسب المود
//  lecture = 0°  |  exam = 0°  |  group = 90°
// ════════════════════════════════════════════════════════════

// ─── إيقاف الموتورات ─────────────────────────────
static void stopMotors() {
  digitalWrite(MOTOR1_PIN1, LOW);
  digitalWrite(MOTOR1_PIN2, LOW);
  digitalWrite(MOTOR2_PIN1, LOW);
  digitalWrite(MOTOR2_PIN2, LOW);
  ledcWrite(0, 0);
  ledcWrite(1, 0);
}

// ─── تحرك للأمام ─────────────────────────────────
static void moveForward(int cm) {
  int duration = cm * MS_PER_CM;
  Serial.print("Moving forward "); Serial.print(cm); Serial.println("cm...");
  digitalWrite(MOTOR1_PIN1, LOW);  digitalWrite(MOTOR1_PIN2, HIGH);
  digitalWrite(MOTOR2_PIN1, LOW);  digitalWrite(MOTOR2_PIN2, HIGH);
  ledcWrite(0, MOTOR_SPEED);
  ledcWrite(1, MOTOR_SPEED);
  delay(duration);
  stopMotors();
  Serial.println("Forward done!");
}

// ─── تحرك للخلف ──────────────────────────────────
static void moveBackward(int cm) {
  int duration = cm * MS_PER_CM;
  Serial.print("Moving backward "); Serial.print(cm); Serial.println("cm...");
  digitalWrite(MOTOR1_PIN1, HIGH); digitalWrite(MOTOR1_PIN2, LOW);
  digitalWrite(MOTOR2_PIN1, HIGH); digitalWrite(MOTOR2_PIN2, LOW);
  ledcWrite(0, MOTOR_SPEED);
  ledcWrite(1, MOTOR_SPEED);
  delay(duration);
  stopMotors();
  Serial.println("Backward done!");
}

// ─── دوران ذكي باستخدام MPU6050 ──────────────────
static void rotateSmart(int angle) {
  if (angle == 0) return;

  float rotated = 0;
  float target  = abs(angle);
  unsigned long lastTime = millis();

  Serial.print("Rotating "); Serial.print(angle); Serial.println(" degrees...");

  if (angle > 0) {
    // عكس عقارب الساعة
    digitalWrite(MOTOR1_PIN1, LOW);  digitalWrite(MOTOR1_PIN2, HIGH);
    digitalWrite(MOTOR2_PIN1, HIGH); digitalWrite(MOTOR2_PIN2, LOW);
  } else {
    // مع عقارب الساعة
    digitalWrite(MOTOR1_PIN1, HIGH); digitalWrite(MOTOR1_PIN2, LOW);
    digitalWrite(MOTOR2_PIN1, LOW);  digitalWrite(MOTOR2_PIN2, HIGH);
  }

  ledcWrite(0, MOTOR_SPEED);
  ledcWrite(1, MOTOR_SPEED);

  while (rotated < target) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    unsigned long now = millis();
    float dt = (now - lastTime) / 1000.0;
    lastTime = now;

    float speed = (g.gyro.x - gyroBiasX) * (180.0 / PI);
    if (abs(speed) > GYRO_THRESHOLD) {
      rotated += abs(speed) * dt;
    }

    Serial.print("Rotated: "); Serial.println(rotated);
    delay(10);
  }

  stopMotors();
  Serial.println("Rotation done!");
}

// ─── تهيئة ───────────────────────────────────────
void initChair() {
  pinMode(MOTOR1_PIN1, OUTPUT);
  pinMode(MOTOR1_PIN2, OUTPUT);
  pinMode(MOTOR2_PIN1, OUTPUT);
  pinMode(MOTOR2_PIN2, OUTPUT);
  ledcSetup(0, MOTOR_FREQ, MOTOR_RESOLUTION);
  ledcAttachPin(ENABLE1_PIN, 0);
  ledcSetup(1, MOTOR_FREQ, MOTOR_RESOLUTION);
  ledcAttachPin(ENABLE2_PIN, 1);

  stopMotors();

  Wire.begin();
  if (!mpu.begin()) {
    Serial.println("MPU6050 not found!");
    while (1) delay(10);
  }

  Serial.println("Red Chair initialized!");
}

// ─── معايرة الـ Gyro ──────────────────────────────
void calibrateGyro() {
  Serial.println("Calibrating... Keep chair STILL!");
  float sum = 0;
  for (int i = 0; i < 300; i++) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    sum += g.gyro.x;
    delay(5);
  }
  gyroBiasX = sum / 300.0;
  Serial.print("Calibration done. Offset: ");
  Serial.println(gyroBiasX);
}

// ════════════════════════════════════════════════════════════
//  تحريك الكرسي الأحمر حسب الانتقال بين المودات
//
//  المسافات الثابتة:
//    DIST_LECTURE = 15 cm
//    DIST_EXAM    = 40 cm
//    DIST_GROUP   = 50 cm
//
//  الزوايا:
//    lecture = 0°  |  exam = 0°  |  group = 90°
//
//  ملاحظة: الكرسي الأحمر على اليمين، يلف 90° للـ group
//          (عكس الأخضر اللي يلف 270°)
// ════════════════════════════════════════════════════════════
void moveToMode(String mode) {
  Serial.print("=== RED: "); Serial.print(currentMode);
  Serial.print(" → "); Serial.print(mode); Serial.println(" ===");

  if (mode == currentMode) {
    Serial.println("Already in this mode, nothing to do.");
    chairStatus = STATUS_DONE;
    return;
  }

  chairStatus = STATUS_MOVING;

  // ──────────────────────────────────────────────
  //  lecture → group
  //  1. تقدم 15 سم (ليبعد عن الأخضر ويقدر يلف)
  //  2. لف 90° (الأحمر يلف 90° للـ group)
  // ──────────────────────────────────────────────
  if (currentMode == "lecture" && mode == "group") {
    moveForward(DIST_LECTURE);
    delay(300);
    rotateSmart(90);    // -90° = مع عقارب الساعة للأحمر
    currentAngle = 90;
  }

  // ──────────────────────────────────────────────
  //  group → lecture
  //  1. تراجع للخلف 15 سم
  //  2. لف -90° (يرجع لـ 0°)
  // ──────────────────────────────────────────────
  else if (currentMode == "group" && mode == "lecture") {
    moveBackward(DIST_LECTURE);
    delay(300);
    rotateSmart(90);     // +90° عكس عقارب الساعة → يرجع لـ 0°
    currentAngle = 0;
  }

  // ──────────────────────────────────────────────
  //  lecture → exam
  //  1. تقدم 15 سم لتجنب التصادم
  //  2. لف -90° (باتجاه اليمين)
  //  3. تقدم 25 سم أفقياً للخارج
  //  4. لف +90° (يرجع اتجاه الأمام)
  // ──────────────────────────────────────────────
  else if (currentMode == "lecture" && mode == "exam") {
    moveForward(DIST_LECTURE);
    delay(300);
    rotateSmart(-90);                          // يلف يمين
    delay(300);
    moveForward(DIST_EXAM - DIST_LECTURE);     // 25 سم للخارج
    delay(300);
    rotateSmart(90);                           // يرجع اتجاه الأمام
    currentAngle = 0;
  }

  // ──────────────────────────────────────────────
  //  exam → lecture
  //  عكس lecture→exam
  // ──────────────────────────────────────────────
  else if (currentMode == "exam" && mode == "lecture") {
    moveForward(DIST_LECTURE);
    delay(300);
    rotateSmart(-90);                          // يلف يمين
    delay(300);
    moveBackward(DIST_EXAM - DIST_LECTURE);    // يرجع 25 سم للداخل
    delay(300);
    rotateSmart(90);                           // يرجع اتجاه الأمام
    currentAngle = 0;
  }

  // ──────────────────────────────────────────────
  //  exam → group
  //  المسافة كبيرة، يلف 90° مباشرة
  // ──────────────────────────────────────────────
  else if (currentMode == "exam" && mode == "group") {
    rotateSmart(-90);    // يلف 90° مع عقارب الساعة
    currentAngle = 90;
  }

  // ──────────────────────────────────────────────
  //  group → exam
  //  من 90° يرجع لـ 0° مباشرة
  // ──────────────────────────────────────────────
  else if (currentMode == "group" && mode == "exam") {
    rotateSmart(90);     // يرجع لـ 0°
    currentAngle = 0;
  }

  else {
    Serial.println("Unknown transition!");
  }

  currentMode = mode;
  chairStatus = STATUS_DONE;

  Serial.print("Red chair reached: "); Serial.println(mode);
}

// ─── Setter ──────────────────────────────────────
void setCurrentAngle(int angle) {
  currentAngle = angle;
  Serial.print("Angle set to: "); Serial.println(angle);
}

// ─── Getters ─────────────────────────────────────
int         getCurrentAngle() { return currentAngle; }
ChairStatus getChairStatus()  { return chairStatus;  }
String      getCurrentMode()  { return currentMode;  }
