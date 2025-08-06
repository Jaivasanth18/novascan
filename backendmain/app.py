from flask import Flask, request, jsonify
import numpy as np
import cv2
import mediapipe as mp
from PIL import Image
from ultralytics import YOLO
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Load YOLO model
yolo_model = YOLO("yolov8n.pt")  # or yolov8s.pt, yolov8m.pt, yolov8l.pt, yolov8x.pt


# Initialize MediaPipe Pose
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()

background_suggestions = {
    "happy": "Sunny park or beach",
    "sad": "Warm indoor setting with soft lighting",
    "angry": "Calm nature scenery with waterfalls",
    "surprise": "Vibrant cityscape or amusement park",
    "neutral": "Minimalist background with soft tones",
    "fear": "Cozy room with comforting decor",
    "disgust": "Clean and fresh environment with greenery"
}

def detect_objects(image):
    # Convert BGR to RGB as required by YOLOv8
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Run inference
    results = yolo_model(image_rgb)[0]

    detected_objects = []
    
    for box in results.boxes:
        class_id = int(box.cls[0].item())
        class_name = yolo_model.names[class_id]
        detected_objects.append(class_name)

    return detected_objects


def estimate_height(image):
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = pose.process(image_rgb)

    if results.pose_landmarks:
        landmarks = results.pose_landmarks.landmark
        if (mp_pose.PoseLandmark.NOSE.value in range(len(landmarks)) and
            mp_pose.PoseLandmark.LEFT_ANKLE.value in range(len(landmarks)) and
            mp_pose.PoseLandmark.RIGHT_ANKLE.value in range(len(landmarks))):

            nose_y = landmarks[mp_pose.PoseLandmark.NOSE.value].y
            left_ankle_y = landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value].y
            right_ankle_y = landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value].y
            avg_ankle_y = (left_ankle_y + right_ankle_y) / 2

            height_px = (abs(nose_y - avg_ankle_y) * 100) + 100
            return f"Estimated Relative Height: {height_px:.2f}"
    return "Height estimation failed (no full standing pose detected)."

def check_posture(image):
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = pose.process(image_rgb)

    if results.pose_landmarks:
        landmarks = results.pose_landmarks.landmark
        hip_y = landmarks[mp_pose.PoseLandmark.LEFT_HIP.value].y
        knee_y = landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value].y
        ankle_y = landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value].y

        if abs(hip_y - knee_y) < 0.15 and abs(knee_y - ankle_y) < 0.15:
            return "Sitting"
        else:
            return "Standing"
    return "Unknown posture"

def detect_environment(image):
    detected_objects = detect_objects(image)
    top_objects = detected_objects[:7]  # Select top 7 detected objects

    environment_mappings = {
        "home": ["sofa", "tv", "bed", "dining table", "chair", "potted plant", "refrigerator"],
        "office": ["laptop", "keyboard", "mouse", "desk", "chair", "monitor", "book"],
        "outdoor": ["bicycle", "car", "bus", "motorcycle", "traffic light", "bench", "fire hydrant"]
    }

    environment_scores = {"home": 0, "office": 0, "outdoor": 0, "store": 0}
    for obj in top_objects:
        for env, items in environment_mappings.items():
            if obj in items:
                environment_scores[env] += 1

    predicted_environment = max(environment_scores, key=environment_scores.get)
    return f"Predicted Environment: {predicted_environment}"

def suggest_background():
    emotion = np.random.choice(["happy", "neutral"])
    background = background_suggestions.get(emotion, "Neutral background")
    return f"Suggested Background: {background}"

@app.route('/analyze', methods=['POST'])
def analyze_image():
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400
    else:
        file = request.files['image']
    image = Image.open(file)
    image = np.array(image)

    if len(image.shape) == 2:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    elif image.shape[2] == 4:
        image = cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)

    detected_objects = detect_objects(image)
    posture = check_posture(image)
    height_estimation = estimate_height(image) if posture == "Standing" else "Height estimation skipped."
    environment = detect_environment(image)
    suggested_background = suggest_background()

    result={
        "detected_objects": detected_objects,
        "posture": posture,
        "height_estimation": height_estimation,
        "suggested_background": suggested_background,
        "environment": environment
    }
    for key, value in result.items():
        print(f"{key}: {value}")
    
    return jsonify(result)
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
