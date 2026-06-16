import paho.mqtt.client as mqtt
import firebase_admin
from firebase_admin import credentials, db
from datetime import datetime
import pytz
import json
import threading
import socket
import time

ROOM_ID         = "Room101"
MQTT_BROKER     = "localhost"
MQTT_PORT       = 1883
TZ              = pytz.timezone("Asia/Hebron")
SERVICE_ACCOUNT = "/home/admin/smart-classroom/serviceAccount.json"
DATABASE_URL    = "https://universitysystem-mn-default-rtdb.firebaseio.com"
POLL_INTERVAL   = 5

def get_now():
    now = datetime.now(TZ)
    return now.strftime("%H:%M"), now.strftime("%A")

def time_to_min(t):
    h, m = map(int, t.split(":"))
    return h * 60 + m

def has_internet():
    try:
        socket.create_connection(("8.8.8.8", 53), timeout=3)
        return True
    except:
        return False

firebase_ok = False

def init_firebase():
    global firebase_ok
    if not has_internet():
        print("No internet - Firebase offline mode")
        return
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT)
        firebase_admin.initialize_app(cred, {'databaseURL': DATABASE_URL})
        firebase_ok = True
        print("Firebase connected!")
    except Exception as e:
        print(f"Firebase error: {e}")

def fb_write(path, data):
    if not firebase_ok: return
    try:
        db.reference(path).update(data)
    except Exception as e:
        print(f"Firebase write error: {e}")

def fb_get(path):
    if not firebase_ok: return None
    try:
        return db.reference(path).get()
    except:
        return None

def unlock_then_lock(roomId, delay=5):
    def _lock():
        time.sleep(delay)
        fb_write(f"/classrooms/{roomId}/accessControl", {"doorStatus": "locked"})
        print(f"Door locked: {roomId}")
    threading.Thread(target=_lock, daemon=True).start()

def push_log(roomId, data):
    if not firebase_ok: return
    try:
        logs_ref = db.reference(f"/accessLogs/{roomId}")
        existing = logs_ref.get()
        count = len([k for k in existing.keys() if k.startswith("log")]) if existing else 0
        log_key = f"log{count + 1}"
        logs_ref.child(log_key).set(data)
        print(f"Log saved: {log_key}")
    except Exception as e:
        print(f"Log error: {e}")

_last_request = {}

def is_duplicate(key, window=3):
    now = time.time()
    if key in _last_request and now - _last_request[key] < window:
        return True
    _last_request[key] = now
    return False

# ════════════════════════════════════════════════
# MQTT
# ════════════════════════════════════════════════
mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)

def on_connect(client, userdata, flags, reason_code, properties):
    print(f"MQTT Connected: {reason_code}")
    client.subscribe(f"room/{ROOM_ID}/access/request")
    client.subscribe(f"room/{ROOM_ID}/temperature/data")
    client.subscribe(f"room/{ROOM_ID}/lighting/data")
    client.subscribe(f"room/{ROOM_ID}/chair/red/status")
    client.subscribe(f"room/{ROOM_ID}/chair/green/status")
    print("Subscribed to all topics")

def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode('utf-8')
    except UnicodeDecodeError:
        try:
            payload = msg.payload.decode('latin-1')
        except:
            print(f"MQTT: Cannot decode message on {msg.topic}")
            return
    topic = msg.topic
    print(f"MQTT [{topic}]: {payload}")
    try:
        data = json.loads(payload)
    except:
        return
    if "access/request" in topic:
        handle_access_request(data)
    elif "temperature/data" in topic:
        handle_temp_data(data)
    elif "lighting/data" in topic:
        handle_lighting_data(data)
    elif "chair/red/status" in topic:
        handle_chair_status(data, "redChair")
    elif "chair/green/status" in topic:
        handle_chair_status(data, "greenChair")

# ════════════════════════════════════════════════
# ACCESS CONTROL
# ════════════════════════════════════════════════
def handle_access_request(data):
    req_type        = data.get("type")
    value           = str(data.get("value", ""))
    now_time, today = get_now()
    now_min         = time_to_min(now_time)
    dup_key = f"{req_type}_{value}"
    if is_duplicate(dup_key):
        print(f"Duplicate ignored: {dup_key}")
        return
    print(f"Access request: {req_type} = {value}")
    if req_type == "card":
        result = check_student(value, today, now_time, now_min)
    elif req_type == "pin":
        result = check_pin(value, now_time)
    else:
        return
    mqtt_client.publish(f"room/{ROOM_ID}/access/response", json.dumps(result))
    print(f"Access response: {result}")

def check_student(studentId, today, now_time, now_min):
    lectures = fb_get("/lectures")
    if not lectures:
        return {"access": False, "reason": "DB Error"}
    matched = None
    for lid, ldata in lectures.items():
        if not isinstance(ldata, dict): continue
        if ldata.get("roomId") != ROOM_ID: continue
        if today not in ldata.get("days", []): continue
        start_min = time_to_min(ldata.get("startTime", "00:00"))
        end_min   = time_to_min(ldata.get("endTime",   "00:00"))
        if end_min < start_min:
            in_time = now_min >= start_min - 10 or now_min <= end_min
        else:
            in_time = start_min - 10 <= now_min <= end_min
        if in_time:
            matched = lid
            break
    if not matched:
        return {"access": False, "reason": "No Active Lecture"}
    enrolled = fb_get(f"/enrollments/{matched}/{studentId}")
    if not enrolled:
        return {"access": False, "reason": "Not Enrolled"}
    name = fb_get(f"/students/{studentId}/name") or studentId
    push_log(ROOM_ID, {"userId": studentId, "method": "Card", "time": now_time})
    fb_write(f"/classrooms/{ROOM_ID}/accessControl", {
        "doorStatus": "unlocked",
        "lastEntry":  f"{datetime.now(TZ).strftime('%Y-%m-%d')} {now_time}"
    })
    unlock_then_lock(ROOM_ID)
    return {"access": True, "name": name}

def check_pin(pin, now_time):
    doctors = fb_get("/doctors")
    if doctors:
        for did, ddata in doctors.items():
            if str(ddata.get("pinCode", "")) == pin:
                push_log(ROOM_ID, {"userId": did, "method": "PIN", "time": now_time})
                fb_write(f"/classrooms/{ROOM_ID}/accessControl", {
                    "doorStatus": "unlocked",
                    "lastEntry":  f"{datetime.now(TZ).strftime('%Y-%m-%d')} {now_time}"
                })
                unlock_then_lock(ROOM_ID)
                return {"access": True, "name": ddata.get("name", "Doctor"), "role": "doctor"}
    admins = fb_get("/admins")
    if admins:
        for aid, adata in admins.items():
            if str(adata.get("pinCode", "")) == pin:
                push_log(ROOM_ID, {"userId": aid, "method": "PIN", "time": now_time})
                fb_write(f"/classrooms/{ROOM_ID}/accessControl", {
                    "doorStatus": "unlocked",
                    "lastEntry":  f"{datetime.now(TZ).strftime('%Y-%m-%d')} {now_time}"
                })
                unlock_then_lock(ROOM_ID)
                return {"access": True, "name": "Admin", "role": "admin"}
    return {"access": False, "reason": "Wrong PIN"}

# ════════════════════════════════════════════════
# TEMPERATURE
# ════════════════════════════════════════════════
def handle_temp_data(data):
    roomId = data.get("roomId", ROOM_ID)
    fb_write(f"/classrooms/{roomId}/temperature", {
        "currentTemp": data.get("temp"),
        "humidity":    data.get("humidity"),
        "fanLevel":    data.get("fanSpeed"),
        "fanStatus":   "on" if data.get("fanSpeed", 0) > 0 else "off",
        "mode":        data.get("mode"),
    })

# ════════════════════════════════════════════════
# LIGHTING
# ════════════════════════════════════════════════
def handle_lighting_data(data):
    roomId = data.get("roomId", ROOM_ID)
    lighting_update = {}
    if "brightness" in data: lighting_update["brightness"] = data["brightness"]
    if "status"     in data: lighting_update["status"]     = data["status"]
    if "mode"       in data: lighting_update["mode"]       = data["mode"]
    if "lux"        in data: lighting_update["lux"]        = data["lux"]
    if lighting_update:
        fb_write(f"/classrooms/{roomId}/lighting", lighting_update)
    if "occupied" in data:
        fb_write(f"/classrooms/{roomId}/occupancy", {"detected": data["occupied"]})
        mqtt_client.publish(
            f"room/{roomId}/temperature/command",
            json.dumps({"occupied": data["occupied"]})
        )
        print(f"Occupancy sent to temp module: {data['occupied']}")

# ════════════════════════════════════════════════
# CHAIRS
# ════════════════════════════════════════════════
def send_mode_to_chairs(mode):
    # اجلب الزوايا الحالية من Firebase
    red_angle   = fb_get(f"/classrooms/{ROOM_ID}/smartChairs/redChair/angle")   or 0
    green_angle = fb_get(f"/classrooms/{ROOM_ID}/smartChairs/greenChair/angle") or 0

    red_cmd   = json.dumps({"mode": mode, "currentAngle": red_angle})
    green_cmd = json.dumps({"mode": mode, "currentAngle": green_angle})

    mqtt_client.publish(f"room/{ROOM_ID}/chair/red/command",   red_cmd)
    mqtt_client.publish(f"room/{ROOM_ID}/chair/green/command", green_cmd)
    print(f"Mode '{mode}' sent: red={red_angle}°, green={green_angle}°")

def handle_chair_status(data, chairId):
    angle  = data.get("angle", 0)
    status = data.get("status", "idle")
    print(f"{chairId}: angle={angle}, status={status}")
    if status == "done":
        fb_write(f"/classrooms/{ROOM_ID}/smartChairs/{chairId}", {"angle": angle})
        print(f"{chairId} angle updated in Firebase: {angle}")

def apply_chairs_mode(mode):
    # ابعت الأمر للكراسي أولاً مع الزاوية الحالية
    send_mode_to_chairs(mode)

# ════════════════════════════════════════════════
# POLLING
# ════════════════════════════════════════════════
_poll_state = {
    "temp":        None,
    "lighting":    None,
    "door":        None,
    "chairs_mode": None,
}

def poll_firebase():
    while True:
        if not firebase_ok:
            time.sleep(POLL_INTERVAL)
            continue
        try:
            # ── Temperature ──
            temp_data = fb_get(f"/classrooms/{ROOM_ID}/temperature")
            if isinstance(temp_data, dict) and temp_data != _poll_state["temp"]:
                _poll_state["temp"] = temp_data
                cmd = {}
                if temp_data.get("fanStatus") == "off": cmd["fanOff"] = True
                if "mode" in temp_data: cmd["mode"] = temp_data["mode"]
                if temp_data.get("mode") == "manual" and "fanLevel" in temp_data:
                    cmd["fanSpeed"] = temp_data["fanLevel"]
                if cmd:
                    mqtt_client.publish(f"room/{ROOM_ID}/temperature/command", json.dumps(cmd))
                    print(f"Temp command sent: {cmd}")

            # ── Lighting ──
            lighting_data = fb_get(f"/classrooms/{ROOM_ID}/lighting")
            if isinstance(lighting_data, dict) and lighting_data != _poll_state["lighting"]:
                _poll_state["lighting"] = lighting_data
                cmd = {}
                if "mode"       in lighting_data: cmd["mode"]       = lighting_data["mode"]
                if "status"     in lighting_data: cmd["status"]     = lighting_data["status"]
                if "brightness" in lighting_data: cmd["brightness"] = lighting_data["brightness"]
                if cmd:
                    mqtt_client.publish(f"room/{ROOM_ID}/lighting/command", json.dumps(cmd))
                    print(f"Lighting command sent: {cmd}")

            # ── Door ──
            door_status = fb_get(f"/classrooms/{ROOM_ID}/accessControl/doorStatus")
            if door_status != _poll_state["door"]:
                _poll_state["door"] = door_status
                print(f"Door status changed: {door_status}")
                if door_status == "remote_open":
                    mqtt_client.publish(f"room/{ROOM_ID}/access/command", json.dumps({"openDoor": True}))
                    unlock_then_lock(ROOM_ID)
                    print("Door open command sent!")

            # ── Chairs mode ──
            chairs_data = fb_get(f"/classrooms/{ROOM_ID}/smartChairs/mode")
            if isinstance(chairs_data, str):
                mode = chairs_data
            elif isinstance(chairs_data, dict):
                mode = chairs_data.get("mode", "")
            else:
                mode = None

            if mode and mode in ["lecture", "exam", "group"] and mode != _poll_state["chairs_mode"]:
                _poll_state["chairs_mode"] = mode
                print(f"New chairs mode: {mode}")
                apply_chairs_mode(mode)

        except Exception as e:
            print(f"Poll error: {e}")

        time.sleep(POLL_INTERVAL)

# ════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════
if __name__ == "__main__":
    init_firebase()
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message
    mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
    threading.Thread(target=poll_firebase, daemon=True).start()
    print("Smart Classroom Server started!")
    mqtt_client.loop_forever()
