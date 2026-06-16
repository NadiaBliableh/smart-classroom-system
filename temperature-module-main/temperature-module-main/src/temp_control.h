#pragma once
#include <Arduino.h>

enum TempMode { TEMP_AUTO, TEMP_MANUAL };

// CO2 alarm levels
enum Co2Level {
  CO2_NORMAL,   // < 1000 ppm
  CO2_WARNING,  // 1000-2000 ppm
  CO2_DANGER    // > 2000 ppm
};

void initTempControl();
void readSensor();
void applyFanControl();

// أوامر من MQTT
void setTempMode(TempMode mode);
void setFanSpeed(int speed);  // 0-5
void setFanOff();

// Getters
float    getCurrentTemp();
float    getCurrentHumidity();
int      getCurrentSpeed();
TempMode getCurrentTempMode();
bool     isOccupied();
void     setOccupied(bool occupied);

// SCD41 CO2
uint16_t getCurrentCO2();
Co2Level getCo2Level();
bool     isCo2AlarmActive();