import time
import requests
from datetime import datetime
import RPi.GPIO as gpio
from hx711 import HX711

# Configuration
API_URL = "https://your-api.com/tension-data"
API_KEY = "your_api_key"
REFERENCE_UNIT = 417.47  # Use calibrated value

# Setup HX711
hx = HX711(5, 6)
hx.set_reading_format("MSB", "MSB")
hx.set_reference_unit(REFERENCE_UNIT)
hx.reset()
hx.tare()

print("Wire tension monitor started...")

try:
    while True:
        # Read tension (average of 5 readings for stability)
        tension = hx.get_weight(5)
        timestamp = datetime.now().isoformat()

        # Prepare data payload
        data = {
            "timestamp": timestamp,
            "tension": round(tension, 2),
            "unit": "grams"
        }

        # Send to REST API
        try:
            response = requests.post(
                API_URL,
                json=data,
                headers={"Authorization": f"Bearer {API_KEY}"},
                timeout=5
            )

            if response.status_code == 200:
                print(f"✓ Sent: {tension:.2f}g at {timestamp}")
            else:
                print(f"✗ API Error: {response.status_code}")

        except requests.exceptions.RequestException as e:
            print(f"✗ Connection error: {e}")

        # Power down between readings to save energy
        hx.power_down()
        time.sleep(1)  # Adjust sampling rate as needed
        hx.power_up()

except KeyboardInterrupt:
    print("\nShutting down...")
    gpio.cleanup()
