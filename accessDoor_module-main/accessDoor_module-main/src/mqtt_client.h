#pragma once
#include <Arduino.h>

void initMQTT();
void mqttLoop();
void sendAccessRequest(String type, String value);

// Callback لما يجي رد من الـ Raspberry
extern void onAccessResponse(bool granted, String name, String reason);
extern void onDoorCommand(bool openDoor);