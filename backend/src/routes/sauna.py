import time

import numpy as np
from fastapi import APIRouter, Request
import matplotlib.pyplot as plt

from backend.bridge.bridge import send_to_ts
from backend.src.core.client import client, device
from backend.src.models.error_models import generic_fail
from backend.src.models.request_models import StartSessionRequest, StopSessionRequest, SaunaRecommendationRequest
from backend.src.models.response_models import StartSessionResponse, StopSessionResponse, SaunaRecommendationResponse
from backend.src.services.recommendation import get_sauna_engine
from backend.src.utils.logger import get_logger
from datetime import datetime
device_online = True

def set_device_online(status: bool):
    global device_online
    device_online = status

logger = get_logger("sauna-backend.sauna")
router = APIRouter()

# Keep your existing response model
# from your code: SaunaRecommendationResponse

@router.post("/recommendations", response_model=SaunaRecommendationResponse)
def post_sauna_recommendations(request: SaunaRecommendationRequest):
    age = request.age
    gender = request.gender
    height = request.height
    weight = request.weight
    goals = request.goals
    print(goals)
    """
    Get optimal sauna settings recommendations for a user.
    If user_id is provided, fetches profile data from Firestore.
    Otherwise, uses provided parameters.
    """
    sauna_engine = get_sauna_engine()
    if sauna_engine is None:
        raise generic_fail("Sauna recommendation engine is not initialized.")



    # Ensure height is in meters (convert from cm if needed)
    if height > 3:  # Likely in cm, convert to meters
        height = height / 100
        logger.info(f"Converted height from cm to meters: {height}m")


    try:
        # Get recommendations from neural network
        recommendation = sauna_engine.predict(
            age=float(age),
            gender=gender,
            height=float(height),
            weight=float(weight),
            selected_goals=goals
        )



        return SaunaRecommendationResponse(
            temperature=recommendation['temperature'],
            humidity=recommendation['humidity'],
            session_length=recommendation['session_length'],
            goals_used=goals
        )
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        raise generic_fail(
            detail=f"Error generating recommendations: {str(e)}"
        )


@router.post("/start_session")
def post_start_session(request: StartSessionRequest):
    from backend.brief.qa_brief  import provide_brief, brief_setup

    client.devices.send_command(device_id=device.device_id, state="on")
    set_device_online(True)
    client.devices.change_profile(device_id=device.device_id, profile="3")
    client.devices.set_target(device_id=device.device_id, temperature=request.temperature, humidity=request.humidity)
    start_time = datetime.now()
    INTERVAL = 1  # seconds
    TOTAL_DURATION = request.session_length # Convert minutes to seconds
    POINTS = TOTAL_DURATION // INTERVAL

    timestamps = []
    temperatures = []
    humidities = []

    for i in range(POINTS):

        try:
            if not device_online:  # If sauna is turned off
                break

            response = client.data.get_latest_data(device_id=device.device_id)
            print(f"Sample {i + 1}: {response}")

            temp1 = response["data"].get("temp")
            hum2 = response["data"].get("hum")

            timestamps.append(i * INTERVAL)
            temperatures.append(temp1)
            humidities.append(hum2)

            print(f"  -> Temp: {temp1}°C, Humidity: {hum2}%")
        except Exception as e:
            print("Error:", e)

        time.sleep(INTERVAL)

    stop_time = datetime.now()
    print("\nData collection complete! Generating graph...")

    # ---- GRAPH WITH DUAL Y-AXES ----
    fig, ax1 = plt.subplots(figsize=(12, 6))

    # Temperature axis
    color = 'tab:red'
    ax1.set_xlabel("Time (seconds)", fontsize=12)
    ax1.set_ylabel("Temperature (°C)", color=color, fontsize=12)
    ax1.plot(timestamps, temperatures, color=color, marker='o', linewidth=2, markersize=8, label="Temperature")
    ax1.tick_params(axis='y', labelcolor=color)
    ax1.grid(True, alpha=0.3)

    temp_min = min(temperatures) - 10
    temp_max = max(temperatures) + 10
    ax1.set_ylim([temp_min, temp_max])

    # Humidity axis
    ax2 = ax1.twinx()
    color = 'tab:blue'
    ax2.set_ylabel("Humidity (%)", color=color, fontsize=12)
    ax2.plot(timestamps, humidities, color=color, marker='s', linewidth=2, markersize=8, label="Humidity")
    ax2.tick_params(axis='y', labelcolor=color)

    hum_min = min(humidities) - 5
    hum_max = max(humidities) + 5
    ax2.set_ylim([hum_min, hum_max])

    plt.title("Sauna Brief", fontsize=14, fontweight='bold')
    fig.tight_layout()
    # ---- EXTRACT ALL AXIS DATA INTO ARRAYS ----
    axis_data = {
        # X-axis data (shared by both plots)
        'x_axis': {
            'label': ax1.get_xlabel(),
            'data': np.array(timestamps),
            'limits': ax1.get_xlim()
        },

        # Left Y-axis (Temperature)
        'y_axis_left': {
            'label': ax1.get_ylabel(),
            'data': np.array(temperatures),
            'limits': ax1.get_ylim(),
            'color': 'tab:red'
        },

        # Right Y-axis (Humidity)
        'y_axis_right': {
            'label': ax2.get_ylabel(),
            'data': np.array(humidities),
            'limits': ax2.get_ylim(),
            'color': 'tab:blue'
        }
    }



    chain = brief_setup("gpt-4o")
    analysis = provide_brief(
        chat_chain=chain,
        question=f"Comment on the graph's data here {axis_data}",
        session_id="session_001"
    )
    brief = analysis["answer"]

    client.devices.send_command(device_id=device.device_id, state="off")

    elapsed_time = (stop_time - start_time).total_seconds()

    json_ready_data = to_json_safe(axis_data)

    payload = {
        'start': str(start_time),
        'stop': str(stop_time),
        'humidity': request.humidity,
        'elapsed': elapsed_time,
        'uid': request.uid,
        'temperature': request.temperature,
        'brief': brief,
        'axis_data': str(json_ready_data)
    }
    send_to_ts(payload)


def to_json_safe(obj):
    # numpy scalar → native Python scalar
    if isinstance(obj, np.generic):
        return obj.item()

    # numpy array → list
    if isinstance(obj, np.ndarray):
        return obj.tolist()

    # tuple → list (JSON cannot represent tuples)
    if isinstance(obj, tuple):
        return [to_json_safe(v) for v in obj]

    # list → list
    if isinstance(obj, list):
        return [to_json_safe(v) for v in obj]

    # dict → dict
    if isinstance(obj, dict):
        return {k: to_json_safe(v) for k, v in obj.items()}

    # leave normal Python types unchanged
    return obj

@router.post("/end_session")
def post_stop_session():
    client.devices.send_command(device_id=device.device_id, state="off")
    set_device_online(False)
    return {"message": "Sauna session stopped successfully."}


