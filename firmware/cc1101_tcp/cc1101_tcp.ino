#include <Arduino.h>
#include <WiFi.h>
#include <ArduinoOTA.h>
#include <SPI.h>
#include <ELECHOUSE_CC1101_SRC_DRV.h>
#include "secrets.h"

// Secrets Fallback
#ifndef WIFI_SSID
#define WIFI_SSID "UnknownSSID"
#endif
#ifndef WIFI_PASS
#define WIFI_PASS "UnknownPass"
#endif

void setup() {
  Serial.begin(115200);
  Serial.println("Booting cc1101_tcp...");

  // 1. Setup WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.waitForConnectResult() != WL_CONNECTED) {
    Serial.println("Connection Failed! Rebooting...");
    delay(5000);
    ESP.restart();
  }

  // 2. Setup OTA
  ArduinoOTA.setHostname("cc1101-node");
  
  ArduinoOTA.onStart([]() {
    String type = (ArduinoOTA.getCommand() == U_FLASH) ? "sketch" : "filesystem";
    Serial.println("Start updating " + type);
  });
  ArduinoOTA.onEnd([]() {
    Serial.println("\nEnd");
  });
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) Serial.println("Auth Failed");
    else if (error == OTA_BEGIN_ERROR) Serial.println("Begin Failed");
    else if (error == OTA_CONNECT_ERROR) Serial.println("Connect Failed");
    else if (error == OTA_RECEIVE_ERROR) Serial.println("Receive Failed");
    else if (error == OTA_END_ERROR) Serial.println("End Failed");
  });

  ArduinoOTA.begin();
  Serial.println("Ready");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  // 3. Setup CC1101 (Preliminary)
  if (ELECHOUSE_cc1101.getCC1101()) {
    Serial.println("CC1101 Connection OK");
  } else {
    Serial.println("CC1101 Connection Error");
    // Init SPI and CC1101 with pins from README
    // SCK=12, MISO=13, MOSI=11, CSN=10, GDO0=4
    ELECHOUSE_cc1101.setSpiPin(12, 13, 11, 10); 
    if (ELECHOUSE_cc1101.getCC1101()) {
       Serial.println("CC1101 Connection Recovered");
    } else {
       Serial.println("CC1101 Connection FAILED");
    }
  }
  ELECHOUSE_cc1101.Init();
  ELECHOUSE_cc1101.setGDO(4, 5); // GDO0=4, GDO2=5
}

void loop() {
  ArduinoOTA.handle();
  // TODO: TCP Server Implementation
}
