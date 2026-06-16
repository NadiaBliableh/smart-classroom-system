#pragma once
#include <Arduino.h>

// أوضاع الكرسي
enum ChairMode { MODE_LECTURE, MODE_EXAM, MODE_GROUP };
enum ChairStatus { STATUS_IDLE, STATUS_MOVING, STATUS_DONE };

void initChair();
void calibrateGyro();
void moveToMode(String mode);



void setCurrentDistance(int dist);   // ← أضف هاد
int  getCurrentDistance();           // ← أضف هاد

// Getters
int         getCurrentAngle();
ChairStatus getChairStatus();
String      getCurrentMode();

void setCurrentAngle(int angle);