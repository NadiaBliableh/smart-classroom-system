#pragma once
#include <Arduino.h>

void showHome();
void openLock(String line1, String line2);
void denyAccess(String reason);
void checkStudentAccess(String studentId);
void checkDoctorPin(String pin);
void checkTimeout();