import os
os.environ["OPENBLAS_NUM_THREADS"] = "4"
os.environ["OMP_NUM_THREADS"] = "4"

import depthai as dai
import cv2
import face_recognition
import numpy as np
import paho.mqtt.client as mqtt
import json
from datetime import datetime

ROOM_ID     = "Room101"
FACES_DIR   = "registered_faces"
YUNET_MODEL = "face_detection_yunet_2023mar.onnx"

# -- MQTT --------------------------------------
mqtt_att = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)

current_lecture_id = None
_last_lecture_id = None

def on_att_message(client, userdata, msg):
    global current_lecture_id, _last_lecture_id
    try:
        data = json.loads(msg.payload.decode())
        new_id = data.get("lectureId")
        if new_id != _last_lecture_id:  # ? ?? ?? ????
            _last_lecture_id = new_id
            current_lecture_id = new_id
            print(f"Active lecture updated: {current_lecture_id}")
    except:
        pass

mqtt_att.on_message = on_att_message
mqtt_att.connect("localhost", 1883, 60)
mqtt_att.subscribe(f"room/{ROOM_ID}/lecture/active")
mqtt_att.loop_start()

# -- ????? ?????? ?? ???? ?? ???? Firebase ----
# ??????? ?? ?????? ?? server.py ?????? ??? MQTT
# ?? ?????? ?? ??? JSON ????
known_encodings = []
known_ids       = []
known_names     = []

# ?? ???? ??? names.json ???? ???? {"id": "name"}
import os
names_map = {}
names_file = "names.json"
if os.path.exists(names_file):
    with open(names_file, "r", encoding="utf-8") as f:
        names_map = json.load(f)

print("Loading student faces...")
for filename in os.listdir(FACES_DIR):
    if filename.endswith(('.jpg', '.jpeg', '.png')):
        student_id = os.path.splitext(filename)[0]
        name       = names_map.get(student_id, student_id)

        img       = face_recognition.load_image_file(os.path.join(FACES_DIR, filename))
        encodings = face_recognition.face_encodings(img, num_jitters=0, model="small")

        if encodings:
            known_encodings.append(encodings[0])
            known_ids.append(student_id)
            known_names.append(name)
            print(f"  Loaded: {name} ({student_id})")
        else:
            print(f"  No face in: {filename}")

print(f"Total: {len(known_encodings)} students\n")

# -- Attendance --------------------------------
marked_today = set()

def mark_attendance(lecture_id, student_id, name, confidence):
    key = f"{lecture_id}_{student_id}"
    if key in marked_today:
        return
    marked_today.add(key)

    mqtt_att.publish(f"room/{ROOM_ID}/attendance/result", json.dumps({
        "lectureId":  lecture_id,
        "studentId":  student_id,
        "name":       name,
        "confidence": round(confidence, 2)
    }))
    print(f"Sent via MQTT: {name} | {lecture_id}")

# -- YuNet -------------------------------------
detector = cv2.FaceDetectorYN.create(
    YUNET_MODEL, "", (640, 480),
    score_threshold=0.6,
    nms_threshold=0.3,
    top_k=100
)

# -- Pipeline ----------------------------------
pipeline = dai.Pipeline()
cam = pipeline.create(dai.node.ColorCamera)
cam.setVideoSize(640, 480)
cam.setResolution(dai.ColorCameraProperties.SensorResolution.THE_1080_P)
cam.setInterleaved(False)
cam.setFps(15)

xout = pipeline.create(dai.node.XLinkOut)
xout.setStreamName("video")
xout.input.setBlocking(False)
cam.video.link(xout.input)

# -- Main Loop ---------------------------------
with dai.Device(pipeline) as device:
    video_q = device.getOutputQueue("video", maxSize=4, blocking=False)

    cv2.namedWindow("Attendance System", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("Attendance System", 640, 480)

    print("System Running - Press Q to quit\n")
    frame_count     = 0
    last_faces_info = []

    while True:
        frame = video_q.get().getCvFrame()
        h, w  = frame.shape[:2]

        frame_count += 1
        if frame_count % 20 == 0 and known_encodings:
            detector.setInputSize((w, h))
            _, faces = detector.detect(frame)
            faces = faces if faces is not None else []

            last_faces_info = []

            for face in faces:
                x, y, fw, fh = int(face[0]), int(face[1]), int(face[2]), int(face[3])
                x1, y1 = max(0, x), max(0, y)
                x2, y2 = min(w, x+fw), min(h, y+fh)
                face_crop = frame[y1:y2, x1:x2]

                if face_crop.size == 0:
                    continue

                face_small = cv2.resize(face_crop, (100, 100))
                rgb_face   = cv2.cvtColor(face_small, cv2.COLOR_BGR2RGB)
                encodings  = face_recognition.face_encodings(
                    rgb_face, num_jitters=0, model="small"
                )

                name  = "Unknown"
                color = (0, 0, 255)

                if encodings:
                    distances = face_recognition.face_distance(known_encodings, encodings[0])
                    best_idx  = np.argmin(distances)
                    best_dist = distances[best_idx]

                    if best_dist < 0.5:
                        name  = known_names[best_idx]
                        sid   = known_ids[best_idx]
                        color = (0, 255, 0)
                        if current_lecture_id:
                            mark_attendance(current_lecture_id, sid, name, 1 - best_dist)

                last_faces_info.append((x1, y1, x2, y2, name, color))

        for (x1, y1, x2, y2, name, color) in last_faces_info:
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            cv2.putText(frame, name, (x1, y1-8),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)

        status = f"Lecture: {current_lecture_id}" if current_lecture_id else "No active lecture"
        cv2.putText(frame, status, (20, 40),
                   cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 200, 255), 2)
        cv2.putText(frame, f"Present: {len(marked_today)}", (20, 80),
                   cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
        cv2.putText(frame, datetime.now().strftime("%H:%M:%S"), (20, 120),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)

        cv2.imshow("Attendance System", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

mqtt_att.loop_stop()
cv2.destroyAllWindows()
print(f"\nDone. Present: {len(marked_today)}")