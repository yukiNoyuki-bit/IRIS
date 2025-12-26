#include <WiFi.h>
#include <DHT.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ---------- WiFi ----------
#define WIFI_SSID     "kuaci"
#define WIFI_PASSWORD "yukkiciw"

// ---------- Firebase (Realtime Database) ----------
#define API_KEY       "AIzaSyAdD_a1ITsvwrKov8z7PeBvrny0EBChBfk"
#define DATABASE_URL  "https://smart-iris-default-rtdb.firebaseio.com/"

// Auth (kosongkan untuk Anonymous)
#define USER_EMAIL    ""
#define USER_PASSWORD ""

// Identitas device untuk path RTDB
#define DEVICE_ID     "esp32-iris-01"

// ---------- DHT ----------
#define DHT_PIN   25
#define DHTTYPE   DHT22
DHT dht(DHT_PIN, DHTTYPE);

// ---------- Pin analog & relay ----------
const int SOIL_PIN  = 36;  // ADC1 (WAJIB ADC1 saat Wi-Fi)
const int LDR_PIN   = 33;  // ADC1
const int UV_PIN    = 32;  // ADC1
const int RELAY_PIN = 26;  // Relay IN (modul aktif-LOW)
const bool RELAY_ACTIVE_HIGH = false;

// ---------- Kalibrasi Soil & LDR ----------
// SESUAIKAN dari hasil bacaan Anda:
const int WET_ADC = 2920;
const int DRY_ADC = 4095;

int LDR_DARK_ADC   = 300;
int LDR_BRIGHT_ADC = 3000;

// ---------- Kalibrasi UV ----------
#define UV_ADC_FS_MV 1100.0f
float UV_BASE_mV    = 50.0f;
float UV_FULLSUN_mV = 900.0f;
float UVI_FULLSUN   = 10.0f;
const int  UV_MIN_RAW_DETECT = 8;

// ---------- Smoothing ----------
const float SOIL_SMOOTH_ALPHA = 0.20f;

// ---------- Timing ----------
const unsigned long LOOP_EVERY_MS      = 2000;
const unsigned long CTRL_POLL_MS       = 1000;  // jangan terlalu cepat agar tidak timeout
const unsigned long FIREBASE_POST_MS   = 5000;
const unsigned long NTP_SYNC_MS        = 60000;

const unsigned long MIN_ON_MS          = 1000;  // demo cepat
const unsigned long MIN_OFF_MS         = 1000;  // demo cepat

// ---------- Vars ----------
bool pumpOn = false;
unsigned long lastChangeMs = 0;
unsigned long lastLoopMs   = 0;
unsigned long lastPostMs   = 0;
unsigned long lastCtrlMs   = 0;
unsigned long lastNtpMs    = 0;
float pctSoilFilt = -1.0f;

bool manualMode = false;   // mode == "manual"
bool powerEnabled = true;

// Path RTDB
String basePath, pathMode, pathPower, pathPumpManual, pathPumpAuto;

// Firebase
FirebaseData fbdo;      // push state/telemetry
FirebaseData fbdoCtrl;  // read controls
FirebaseAuth auth;
FirebaseConfig config;

// ---------- Helper ----------
void setRelay(bool on) {
  pumpOn = on;
  lastChangeMs = millis();
  if (RELAY_ACTIVE_HIGH) digitalWrite(RELAY_PIN, on ? HIGH : LOW);
  else                   digitalWrite(RELAY_PIN, on ? LOW  : HIGH);
}

int readADCTrimmed(int pin, uint8_t samples = 8, uint16_t dly = 5) {
  if (samples < 3) samples = 3;
  int minV = 4095, maxV = 0;
  long sum = 0;
  for (uint8_t i = 0; i < samples; i++) {
    int v = analogRead(pin);
    if (v < minV) minV = v;
    if (v > maxV) maxV = v;
    sum += v;
    delay(dly);
  }
  sum -= minV; sum -= maxV;
  return sum / (samples - 2);
}

int soilPercent(int adc) {
  long pct = (DRY_ADC > WET_ADC)
             ? map(adc, DRY_ADC, WET_ADC, 0, 100)
             : map(adc, WET_ADC, DRY_ADC, 0, 100);
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return (int)pct;
}

int lightPercent(int adc) {
  long pct = map(adc, LDR_DARK_ADC, LDR_BRIGHT_ADC, 0, 100);
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return (int)pct;
}

float uvMilliVoltsFromRaw(int raw) {
  return (raw * UV_ADC_FS_MV) / 4095.0f;
}

float uvIndexEstimate(float uv_mV) {
  float pct = (uv_mV - UV_BASE_mV) / (UV_FULLSUN_mV - UV_BASE_mV);
  if (pct < 0) pct = 0;
  if (pct > 1) pct = 1;
  return pct * UVI_FULLSUN;
}

void syncNTPIfNeeded() {
  unsigned long now = millis();
  if (now - lastNtpMs < NTP_SYNC_MS) return;
  lastNtpMs = now;

  // penting untuk TLS token kalau jam device meleset
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
}

void pushToFirebase(int adcSoil, int pctSoil, float tempC, float humRH,
                    int ldrPct, bool pump,
                    int uvRaw, float uv_mV, float uv_uvi, bool uvPresent, const String &uvStatus) {
  FirebaseJson json;

  // struktur state sesuai SC
  json.set("soil/adc",      adcSoil);
  json.set("soil/percent",  pctSoil);
  json.set("env/tempC",     isnan(tempC) ? 0.0 : tempC);
  json.set("env/humRH",     isnan(humRH) ? 0.0 : humRH);
  json.set("light/percent", ldrPct);

  json.set("uv/raw",     uvRaw);
  json.set("uv/mV",      uv_mV);
  json.set("uv/uvi",     uv_uvi);
  json.set("uv/status",  uvStatus);
  json.set("uv/present", uvPresent);

  json.set("pump/on", pump);

  // info kontrol (buat debug/demo)
  json.set("control/mode",  manualMode ? "manual" : "auto");
  json.set("control/power", powerEnabled);

  json.set("ts/.sv", "timestamp");

  String base = String("/devices/") + DEVICE_ID;

  // push telemetry (history)
  if (!Firebase.RTDB.pushJSON(&fbdo, (base + "/telemetry").c_str(), &json)) {
    Serial.printf("[RTDB] telemetry push ERR: %s\n", fbdo.errorReason().c_str());
  }

  // set state (current)
  if (!Firebase.RTDB.setJSON(&fbdo, (base + "/state").c_str(), &json)) {
    Serial.printf("[RTDB] state set ERR: %s\n", fbdo.errorReason().c_str());
  }
}

void setup() {
  Serial.begin(115200);
  delay(200);

  WiFi.setSleep(false); // bantu stabil untuk Firebase

  analogSetWidth(12);
  analogSetPinAttenuation(SOIL_PIN, ADC_11db);
  analogSetPinAttenuation(LDR_PIN,  ADC_11db);
  analogSetPinAttenuation(UV_PIN,   ADC_0db);

  pinMode(SOIL_PIN, INPUT);
  pinMode(LDR_PIN,  INPUT);
  pinMode(UV_PIN,   INPUT);

  pinMode(RELAY_PIN, OUTPUT);
  setRelay(false);

  dht.begin();

  // WiFi
  Serial.printf("WiFi: connecting to %s ...\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected, IP: " + WiFi.localIP().toString());

  // NTP
  syncNTPIfNeeded();

  // Firebase config
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  // optional: kecilkan response buffer agar ringan
  fbdo.setResponseSize(2048);
  fbdoCtrl.setResponseSize(2048);

  Serial.println("Auth: Anonymous sign-in");
  if (!Firebase.signUp(&config, &auth, "", "")) {
    Serial.printf("SignUp ERR: %s\n", config.signer.signupError.message.c_str());
  } else {
    Serial.println("SignUp OK");
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Path controls (SKEMA BARU)
  basePath       = String("/devices/") + DEVICE_ID;
  pathMode       = basePath + "/controls/mode";
  pathPower      = basePath + "/controls/power";
  pathPumpManual = basePath + "/controls/pump_manual";
  pathPumpAuto   = basePath + "/controls/pump_auto";

  Serial.println("=== ESP32 + Firebase (RTDB) READY ===");
}

void loop() {
  unsigned long now = millis();
  if (now - lastLoopMs < LOOP_EVERY_MS) return;
  lastLoopMs = now;

  // 1) sync NTP berkala
  syncNTPIfNeeded();

  // 2) BACA CONTROL RTDB
  if (Firebase.ready() && (now - lastCtrlMs >= CTRL_POLL_MS)) {
    lastCtrlMs = now;

    // mode default auto
    String mode = "auto";
    if (Firebase.RTDB.getString(&fbdoCtrl, pathMode.c_str())) {
      mode = fbdoCtrl.stringData();
      mode.toLowerCase();
    }
    manualMode = (mode == "manual");

    // power default true
    if (Firebase.RTDB.getBool(&fbdoCtrl, pathPower.c_str())) {
      powerEnabled = fbdoCtrl.boolData();
    } else {
      powerEnabled = true;
    }

    // pilih command sesuai mode
    bool cmdPump = false;
    if (manualMode) {
      if (Firebase.RTDB.getBool(&fbdoCtrl, pathPumpManual.c_str())) {
        cmdPump = fbdoCtrl.boolData();
      }
    } else {
      if (Firebase.RTDB.getBool(&fbdoCtrl, pathPumpAuto.c_str())) {
        cmdPump = fbdoCtrl.boolData();
      }
    }

    // power OFF => paksa OFF
    if (!powerEnabled) cmdPump = false;

    // eksekusi relay (hormati MIN_ON/OFF)
    if (cmdPump != pumpOn) {
      unsigned long since = now - lastChangeMs;
      if (cmdPump && since >= MIN_OFF_MS) setRelay(true);
      else if (!cmdPump && since >= MIN_ON_MS) setRelay(false);
    }
  }

  // 3) SENSOR READ
  int adcSoil = readADCTrimmed(SOIL_PIN, 8, 5);
  int pctSoilRaw = soilPercent(adcSoil);

  if (pctSoilFilt < 0) pctSoilFilt = pctSoilRaw;
  else pctSoilFilt += SOIL_SMOOTH_ALPHA * ((float)pctSoilRaw - pctSoilFilt);
  int pctSoil = (int)(pctSoilFilt + 0.5f);

  float suhuC = dht.readTemperature();
  float humRH = dht.readHumidity();
  bool dhtOK  = !(isnan(suhuC) || isnan(humRH));

  int ldrRaw = readADCTrimmed(LDR_PIN, 8, 3);
  int ldrPct = lightPercent(ldrRaw);

  int uvRaw = readADCTrimmed(UV_PIN, 16, 3);
  bool uvPresent = (uvRaw > UV_MIN_RAW_DETECT);
  float uv_mV = uvPresent ? uvMilliVoltsFromRaw(uvRaw) : 0.0f;
  float uv_uvi = uvPresent ? uvIndexEstimate(uv_mV) : 0.0f;
  String uvStatus = uvPresent ? "OK" : "N/A";

  // 4) DEBUG SERIAL
  Serial.print("mode="); Serial.print(manualMode ? "manual" : "auto");
  Serial.print(" power="); Serial.print(powerEnabled ? "1" : "0");
  Serial.print(" pump="); Serial.print(pumpOn ? "1" : "0");
  Serial.print(" adcSoil="); Serial.print(adcSoil);
  Serial.print(" soil%raw="); Serial.print(pctSoilRaw);
  Serial.print(" soil%="); Serial.println(pctSoil);

  // 5) PUSH FIREBASE
  if (Firebase.ready() && (now - lastPostMs >= FIREBASE_POST_MS)) {
    lastPostMs = now;
    pushToFirebase(
      adcSoil, pctSoil,
      dhtOK ? suhuC : 0.0, dhtOK ? humRH : 0.0,
      ldrPct, pumpOn,
      uvRaw, uv_mV, uv_uvi, uvPresent, uvStatus
    );
  }
}
