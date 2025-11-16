#ADD INSTAGRAM STORY SHEARING

if __name__ == "__main__":
    from backend.api.claude import HarviaAPI
    from qa_brief import provide_brief, brief_setup

    ##Frontenden çek
    client = HarviaAPI(username="harviahackathon2025@gmail.com", password="junction25!")
    device = client.devices.get_device_by_serial("2513005304")
    client.devices.send_command(device_id=device.device_id, state="on")
    client.devices.change_profile(device_id=device.device_id, profile="3")
    client.devices.set_target(device_id=device.device_id, temperature=84, humidity=10)
    from dotenv import load_dotenv
    import time
    import matplotlib.pyplot as plt
    import numpy as np

    load_dotenv()
    INTERVAL = 2  # seconds
    TOTAL_DURATION = 1 * 60  # 1 minute
    POINTS = TOTAL_DURATION // INTERVAL

    # ---- DATA STORAGE ----
    timestamps = []
    temperatures = []
    humidities = []

    for i in range(POINTS):
        try:
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

    print("\nData collection complete! Generating graph...")
    print(f"Temperature range: {min(temperatures)} - {max(temperatures)}°C")
    print(f"Humidity range: {min(humidities)} - {max(humidities)}%")

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
    plt.savefig("sauna_brief.png", dpi=300)
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
    print(brief)
    client.devices.send_command(device_id=device.device_id, state="off")