import time
from datetime import datetime, timedelta
from pathlib import Path
import warnings

import pytz
import joblib
import pandas as pd

import firebase_admin
from firebase_admin import credentials, db

# =========================
# KONFIG
# ==========================
DEVICE_ID = "esp32-iris-01"

DB_URL = "https://smart-iris-default-rtdb.firebaseio.com"
# jika console Anda pakai firebaseio.com, ganti ke:
# DB_URL = "https://smart-iris-default-rtdb.firebaseioio.com"

TZ = pytz.timezone("Asia/Makassar")

LOOP_SEC = 1
FORECAST_INTERVAL_SEC = 10
STEP_MINUTES = 10

SOIL_IRRIGATE_THRESHOLD = 60.0

# mapping label legacy -> aksi pompa (jika model Anda mengeluarkan label seperti ini)
LABEL_MAP = {
    "kurang_air": True,
    "butuh_air": True,
    "kering": True,
    "aman": False,
    "normal": False,
    "cukup": False,
    "basah": False,
}

warnings.filterwarnings("ignore", message="X has feature names, but .* was fitted without feature names")

# =========================
# PATH FILE
# =========================
BASE_DIR = Path(__file__).resolve().parent
SERVICE_ACCOUNT_PATH = BASE_DIR / "serviceAccountKey.json"

DECISION_MODEL_PATH = BASE_DIR / "2tomato_decision_multilabel_model.joblib"
FORECAST_MODEL_PATH = BASE_DIR / "2tomato_forecast_model.joblib"

# versi kolom ala device (ESP32)
FEATURES_5 = ["soil_percent", "tempC", "humRH", "light_percent", "uv_uvi"]
FEATURES_6 = FEATURES_5 + ["hour"]

# versi kolom ala model training (yang muncul di error Anda)
MODEL_FEATURES_5 = ["soil_moisture_pct", "air_temperature_c", "air_humidity_pct", "light_intensity_lux", "uv_index"]
MODEL_FEATURES_6 = MODEL_FEATURES_5 + ["hour"]

# =========================
# DEBUG START
# =========================
def debug_start():
    import os
    print("=== SC WORKER START ===")
    print("CWD              :", os.getcwd())
    print("BASE_DIR         :", str(BASE_DIR))
    print("SERVICE_ACCOUNT  :", str(SERVICE_ACCOUNT_PATH), "| exists =", SERVICE_ACCOUNT_PATH.exists())
    print("DECISION_MODEL   :", str(DECISION_MODEL_PATH), "| exists =", DECISION_MODEL_PATH.exists())
    print("FORECAST_MODEL   :", str(FORECAST_MODEL_PATH), "| exists =", FORECAST_MODEL_PATH.exists())
    print("DB_URL           :", DB_URL)
    print("DEVICE_ID        :", DEVICE_ID)
    print("=======================")

debug_start()

if not SERVICE_ACCOUNT_PATH.exists():
    raise FileNotFoundError(f"serviceAccountKey.json tidak ditemukan di: {SERVICE_ACCOUNT_PATH}")
if not DECISION_MODEL_PATH.exists():
    raise FileNotFoundError(f"Decision model tidak ditemukan di: {DECISION_MODEL_PATH}")
if not FORECAST_MODEL_PATH.exists():
    raise FileNotFoundError(f"Forecast model tidak ditemukan di: {FORECAST_MODEL_PATH}")

# =========================
# INIT FIREBASE
# =========================
cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {"databaseURL": DB_URL})

# =========================
# LOAD MODELS (unwrap dict bundle)
# =========================
def unwrap_joblib(loaded_obj):
    """
    Mendukung 2 format:
      1) joblib berisi model langsung (punya .predict)
      2) joblib berisi dict bundle: {"model": ..., "sensor_cols": ..., "target_label_cols": ...}
    """
    if isinstance(loaded_obj, dict):
        model = loaded_obj.get("model") or loaded_obj.get("estimator") or loaded_obj.get("pipeline")
        return model, loaded_obj
    return loaded_obj, {}

_dec_loaded = joblib.load(str(DECISION_MODEL_PATH))
decision_model, DEC_META = unwrap_joblib(_dec_loaded)

_for_loaded = joblib.load(str(FORECAST_MODEL_PATH))
forecast_model, FOR_META = unwrap_joblib(_for_loaded)

print("DECISION_MODEL type:", type(decision_model), "| meta keys:", list(DEC_META.keys()))
print("FORECAST_MODEL type:", type(forecast_model), "| meta keys:", list(FOR_META.keys()))

if decision_model is None or not hasattr(decision_model, "predict"):
    raise TypeError("DECISION_MODEL tidak valid: tidak ada .predict() (cek isi joblib, pastikan ada key 'model').")
if forecast_model is None or not hasattr(forecast_model, "predict"):
    raise TypeError("FORECAST_MODEL tidak valid: tidak ada .predict() (cek isi joblib, pastikan ada key 'model').")

# =========================
# RTDB REFS
# =========================
base = db.reference(f"/devices/{DEVICE_ID}")
ref_state = base.child("state")
ref_controls = base.child("controls")
ref_telemetry = base.child("telemetry")

ref_ai = base.child("ai")
ref_ai_now = ref_ai.child("now")
ref_ai_forecast = ref_ai.child("forecast")

# =========================
# LABEL THRESHOLD (sesuai Flutter)
# =========================
def suhu_ket_tomat_indoor(t: float) -> str:
    if t != t:
        return "-"
    if t < 13:
        return "Dingin"
    if t < 18:
        return "Sejuk"
    if t <= 27:
        return "Optimal"
    if t <= 30:
        return "Hangat"
    if t <= 33:
        return "Panas"
    return "Bahaya panas"

def rh_ket_tomat_indoor(rh: float) -> str:
    if rh != rh:
        return "-"
    if rh < 40:
        return "Terlalu kering"
    if rh < 55:
        return "Agak kering"
    if rh <= 75:
        return "Optimal"
    if rh <= 85:
        return "Terlalu lembap"
    return "Sangat lembap (risiko jamur)"

def soil_ket_tomat_indoor(sm: float) -> str:
    if sm != sm:
        return "-"
    if sm < 30:
        return "Kering (butuh air)"
    if sm < 40:
        return "Agak kering"
    if sm <= 70:
        return "Optimal"
    if sm <= 85:
        return "Basah (kurangi air)"
    return "Terlalu basah (risiko busuk akar)"

def lux_ket(lux: float) -> str:
    if lux != lux:
        return "-"
    if lux < 200:
        return "Rendah"
    if lux < 600:
        return "Sedang"
    if lux < 900:
        return "Tinggi"
    return "Sangat tinggi"

def uv_ket(uv: float) -> str:
    if uv != uv:
        return "-"
    if uv <= 2:
        return "Rendah"
    if uv <= 5:
        return "Sedang"
    if uv <= 7:
        return "Tinggi"
    if uv <= 10:
        return "Sangat tinggi"
    return "Ekstrem"

def rule_labels_from_row(row: dict) -> dict:
    t = float(row.get("tempC", float("nan")))
    rh = float(row.get("humRH", float("nan")))
    sm = float(row.get("soil_percent", float("nan")))
    # gunakan lux asli jika tersedia, fallback ke light_intensity_lux
    lux = float(row.get("light_intensity_lux", row.get("light_percent", 0.0) * 10.0))
    uv = float(row.get("uv_uvi", float("nan")))
    return {
        "label_suhu": suhu_ket_tomat_indoor(t),
        "label_rh": rh_ket_tomat_indoor(rh),
        "label_soil": soil_ket_tomat_indoor(sm),
        "label_lux": lux_ket(lux),
        "label_uv": uv_ket(uv),
    }

# =========================
# UTIL
# =========================
def infer_n_features(model):
    if hasattr(model, "n_features_in_"):
        return int(model.n_features_in_)
    if hasattr(model, "steps"):
        for _, step in model.steps:
            if hasattr(step, "n_features_in_"):
                return int(step.n_features_in_)
    return None

def build_row_from_state(state: dict, now: datetime) -> dict:
    """
    Ambil state device + buat alias fitur sesuai model training.
    """
    soil = state.get("soil", {}).get("percent", None)
    temp = state.get("env", {}).get("tempC", None)
    hum  = state.get("env", {}).get("humRH", None)

    light_obj = state.get("light", {}) or {}
    light_percent = light_obj.get("percent", 0)

    # jika ada lux asli dari device, pakai
    light_lux = light_obj.get("lux", None)
    if light_lux is None:
        # fallback kasar: 0–100% -> 0–1000 lux
        try:
            light_lux = float(light_percent) * 10.0
        except Exception:
            light_lux = 0.0

    uv_obj = state.get("uv", {}) or {}
    uv_uvi = uv_obj.get("uvi", 0.0)

    if soil is None or temp is None or hum is None:
        raise ValueError("State belum lengkap: pastikan /state/soil/percent dan /state/env/tempC|humRH sudah ada.")

    # versi field ESP32
    row = {
        "soil_percent": float(soil),
        "tempC": float(temp),
        "humRH": float(hum),
        "light_percent": float(light_percent),
        "uv_uvi": float(uv_uvi),
        "hour": int(now.hour),
    }

    # alias untuk model training (yang muncul di error)
    row.update({
        "soil_moisture_pct": row["soil_percent"],
        "air_temperature_c": row["tempC"],
        "air_humidity_pct": row["humRH"],
        "light_intensity_lux": float(light_lux),
        "uv_index": row["uv_uvi"],
    })

    return row

def make_X_single_step_for(model, row: dict, meta: dict | None = None) -> pd.DataFrame:
    """
    Pilih urutan kolom fitur yang benar untuk model.
    Prioritas:
      1) model.feature_names_in_
      2) meta["sensor_cols"] / meta["feature_cols"]
      3) n_features_in_ -> pilih default MODEL_FEATURES_6 atau FEATURES_6
    """
    cols = getattr(model, "feature_names_in_", None)
    if cols is not None:
        cols = list(cols)
        missing = [c for c in cols if c not in row]
        if missing:
            raise ValueError(f"Fitur kurang untuk model (feature_names_in_): {missing}")
        return pd.DataFrame([[row[c] for c in cols]], columns=cols)

    if meta:
        meta_cols = meta.get("sensor_cols") or meta.get("feature_cols")
        if meta_cols:
            cols = list(meta_cols)
            missing = [c for c in cols if c not in row]
            if missing:
                raise ValueError(f"Fitur kurang untuk model (meta sensor_cols): {missing}")
            return pd.DataFrame([[row[c] for c in cols]], columns=cols)

    # fallback berdasarkan jumlah fitur
    n = infer_n_features(model)
    if n == 5:
        # lebih aman pakai versi model training kalau ada
        cols = MODEL_FEATURES_5
    else:
        cols = MODEL_FEATURES_6
    missing = [c for c in cols if c not in row]
    if missing:
        # fallback ke versi ESP32 jika ternyata itu yang dibutuhkan
        cols = FEATURES_6 if len(cols) == 6 else FEATURES_5
    return pd.DataFrame([[row[c] for c in cols]], columns=cols)

def decode_multioutput_prediction(pred_row) -> dict:
    """
    MultiOutputClassifier -> pred_row biasanya array label.
    """
    import numpy as np
    label_cols = (
        DEC_META.get("target_label_cols")
        or DEC_META.get("label_cols")
        or ["label_suhu", "label_rh", "label_soil", "label_lux", "label_uv"]
    )

    labels = {}
    if isinstance(pred_row, (list, tuple, np.ndarray)) and len(pred_row) >= 2:
        for i, col in enumerate(label_cols[:len(pred_row)]):
            v = pred_row[i]
            if hasattr(v, "item"):
                v = v.item()
            labels[str(col)] = str(v)
        return labels

    v = pred_row
    if hasattr(v, "item"):
        v = v.item()
    labels["label"] = str(v)
    return labels

def interpret_decision_to_pump(pred_row, row: dict, labels_dict: dict | None = None) -> bool:
    """
    Prioritas:
    1) Jika ada label_soil dari multioutput -> ON/OFF berdasarkan label soil
    2) Jika output legacy -> LABEL_MAP
    3) fallback soil threshold
    """
    if labels_dict and isinstance(labels_dict, dict):
        soil_label = str(labels_dict.get("label_soil", "")).strip().lower()
        if soil_label:
            if "kering" in soil_label or "butuh air" in soil_label or "agak kering" in soil_label:
                return True
            if "basah" in soil_label or "optimal" in soil_label:
                return False

    s = str(pred_row).strip().lower()
    for key, val in LABEL_MAP.items():
        if key in s:
            return bool(val)

    if "stres_panas" in s or "panas" in s:
        return float(row.get("soil_percent", 100.0)) < SOIL_IRRIGATE_THRESHOLD

    return float(row.get("soil_percent", 100.0)) < SOIL_IRRIGATE_THRESHOLD

def _extract_points_from_telemetry(raw) -> list:
    if raw is None:
        return []
    if isinstance(raw, dict):
        if "history" in raw:
            raw = raw["history"]
        elif "series" in raw:
            raw = raw["series"]

    points = []
    if isinstance(raw, list):
        points = raw
    elif isinstance(raw, dict):
        items = list(raw.items())

        def key_fn(item):
            k = item[0]
            try:
                return int(str(k))
            except Exception:
                return str(k)

        items.sort(key=key_fn)
        points = [v for _, v in items]

    return [p for p in points if isinstance(p, dict)]

def _normalize_point(p: dict, now: datetime) -> dict | None:
    """
    Normalisasi telemetry point agar punya kedua set fitur (ESP32 + model training).
    """
    # flat ESP32
    if all(k in p for k in ["soil_percent", "tempC", "humRH", "light_percent", "uv_uvi"]):
        row = {
            "soil_percent": float(p["soil_percent"]),
            "tempC": float(p["tempC"]),
            "humRH": float(p["humRH"]),
            "light_percent": float(p["light_percent"]),
            "uv_uvi": float(p["uv_uvi"]),
            "hour": int(p.get("hour", now.hour)),
        }
        row.update({
            "soil_moisture_pct": row["soil_percent"],
            "air_temperature_c": row["tempC"],
            "air_humidity_pct": row["humRH"],
            "light_intensity_lux": float(p.get("light_intensity_lux", row["light_percent"] * 10.0)),
            "uv_index": row["uv_uvi"],
        })
        return row

    # flat model training
    if all(k in p for k in ["soil_moisture_pct", "air_temperature_c", "air_humidity_pct", "light_intensity_lux", "uv_index"]):
        row = {
            "soil_moisture_pct": float(p["soil_moisture_pct"]),
            "air_temperature_c": float(p["air_temperature_c"]),
            "air_humidity_pct": float(p["air_humidity_pct"]),
            "light_intensity_lux": float(p["light_intensity_lux"]),
            "uv_index": float(p["uv_index"]),
            "hour": int(p.get("hour", now.hour)),
        }
        row.update({
            "soil_percent": row["soil_moisture_pct"],
            "tempC": row["air_temperature_c"],
            "humRH": row["air_humidity_pct"],
            "light_percent": float(p.get("light_percent", row["light_intensity_lux"] / 10.0)),
            "uv_uvi": row["uv_index"],
        })
        return row

    # bentuk mirip state
    try:
        return build_row_from_state(p, now)
    except Exception:
        return None

def build_X_sequence_for_forecast(model, state: dict, now: datetime, meta: dict | None = None) -> pd.DataFrame:
    """
    Jika forecast model butuh banyak fitur, bentuk sequence dari telemetry.
    """
    n_in = infer_n_features(model)
    if not n_in or n_in <= 6:
        row = build_row_from_state(state, now)
        return make_X_single_step_for(model, row, meta=meta)

    # per-step features berdasarkan n_in
    if n_in % 5 == 0:
        per = 5
        feats = MODEL_FEATURES_5
        steps = n_in // 5
    elif n_in % 6 == 0:
        per = 6
        feats = MODEL_FEATURES_6
        steps = n_in // 6
    else:
        raise ValueError(f"Forecast model n_features_in_={n_in} tidak bisa dipetakan ke 5/6 fitur per step.")

    raw_tel = ref_telemetry.get()
    pts = _extract_points_from_telemetry(raw_tel)

    rows = []
    for pt in pts[-(steps * 3):]:
        r = _normalize_point(pt, now)
        if r is not None:
            rows.append(r)

    current_row = build_row_from_state(state, now)
    if len(rows) < steps:
        pad_needed = steps - len(rows)
        rows = ([current_row] * pad_needed) + rows

    rows = rows[-steps:]

    # set hour per step kalau butuh
    if per == 6:
        base_time = now - timedelta(minutes=(steps - 1) * STEP_MINUTES)
        for i in range(steps):
            t = base_time + timedelta(minutes=i * STEP_MINUTES)
            rows[i]["hour"] = int(t.hour)

    flat = []
    for r in rows:
        for f in feats:
            flat.append(float(r[f]))

    return pd.DataFrame([flat])

def interpret_forecast_output(y_pred, threshold: float) -> tuple[list, str, int | None]:
    soil_future = []
    try:
        import numpy as np
        if isinstance(y_pred, np.ndarray):
            soil_future = [float(x) for x in y_pred.flatten().tolist()]
        elif isinstance(y_pred, (list, tuple)):
            soil_future = [float(x) for x in y_pred]
        else:
            soil_future = [float(y_pred)]
    except Exception:
        soil_future = [float(y_pred)]

    idx = None
    for i, v in enumerate(soil_future):
        if v < threshold:
            idx = i
            break

    horizon_min = int((len(soil_future) - 1) * STEP_MINUTES) if len(soil_future) > 1 else STEP_MINUTES

    if idx is None:
        hours = horizon_min / 60.0
        text = f">{hours:.1f} jam (masih aman)"
        return soil_future, text, None

    minutes = int(idx * STEP_MINUTES)
    if minutes <= 0:
        text = "sekarang"
    elif minutes < 60:
        text = f"{minutes} menit lagi"
    else:
        text = f"{minutes/60.0:.1f} jam lagi"

    return soil_future, text, minutes

# =========================
# LOOP
# =========================
last_pump = None
last_forecast_ts = 0

while True:
    try:
        controls = ref_controls.get() or {}
        mode = str(controls.get("mode", "auto")).lower()
        power = bool(controls.get("power", True))

        state = ref_state.get() or {}
        now = datetime.now(TZ)

        # ---------- DECISION ----------
        if mode == "auto":
            row = build_row_from_state(state, now)
            Xd = make_X_single_step_for(decision_model, row, meta=DEC_META)

            pred = decision_model.predict(Xd)
            pred_row = pred[0]
            pred_labels = decode_multioutput_prediction(pred_row)

            rule_labels = rule_labels_from_row(row)

            pump_auto = interpret_decision_to_pump(pred_row, row, labels_dict=pred_labels)
            if not power:
                pump_auto = False

            if last_pump is None or pump_auto != last_pump:
                ref_controls.update({"pump_auto": pump_auto})

                ref_ai_now.set({
                    "pump_auto": pump_auto,
                    "mode": mode,
                    "power": power,

                    "row": row,

                    # hasil AI (multioutput)
                    "labels": pred_labels,
                    "label": pred_labels.get("label_soil") or pred_labels.get("label") or "",

                    # hasil rule threshold untuk konsistensi UI
                    "rule_labels": rule_labels,

                    "ts": int(time.time()),
                    "iso": now.isoformat(),
                })

                print("DECISION -> pump_auto =", pump_auto, "| labels =", pred_labels)
                last_pump = pump_auto

        # ---------- FORECAST ----------
        now_ts = int(time.time())
        if now_ts - last_forecast_ts >= FORECAST_INTERVAL_SEC:
            row = build_row_from_state(state, now)
            Xf = build_X_sequence_for_forecast(forecast_model, state, now, meta=FOR_META)

            yhat = forecast_model.predict(Xf)
            y_pred = yhat[0]

            soil_future, forecast_text, next_min = interpret_forecast_output(
                y_pred,
                threshold=SOIL_IRRIGATE_THRESHOLD
            )

            ref_ai_forecast.set({
                "soil_future": soil_future,
                "threshold": SOIL_IRRIGATE_THRESHOLD,
                "step_minutes": STEP_MINUTES,
                "text": forecast_text,
                "next_irrigation_min": next_min,
                "row_now": row,
                "ts": now_ts,
                "iso": now.isoformat(),
            })

            ref_controls.update({
                "forecast_text": forecast_text,
                "forecast_next_min": next_min if next_min is not None else -1,
                "forecast_soil_now": float(row["soil_percent"]),
                "forecast_soil_min_horizon": float(min(soil_future)) if soil_future else float(row["soil_percent"]),
            })

            print("FORECAST ->", forecast_text, "| len =", len(soil_future))
            last_forecast_ts = now_ts

        time.sleep(LOOP_SEC)

    except Exception as e:
        print("SC error:", repr(e))
        time.sleep(3)
