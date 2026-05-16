import csv
import requests
from datetime import datetime
import time
from HX711 import SimpleHX711, Mass

# Configuration
DT_PIN  = 5   # GPIO 5, Pi pin 29
SCK_PIN = 6   # GPIO 6, Pi pin 31

REFERENCE_UNIT = -94      # Replace with calibration value if required
OFFSET         = 117625      # Replace with calibration value if required

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
OUTPUT_FILE = f"readings/cycle_{timestamp}.csv"

API_URL = "http://192.168.1.173:5000/upload_csv"

# Initialise
hx = SimpleHX711(DT_PIN, SCK_PIN, REFERENCE_UNIT, OFFSET)
hx.setUnit(Mass.Unit.G)
hx.zero()
print("Scale zeroed.")

input("Press ENTER to start collecting...")

start_time = time.time()
readings = []

print("Collecting... Press Ctrl+C to stop")

# Read loop
try:
    while True:
        value = hx.weight(1).value
        timestamp = round(time.time() - start_time, 4)
		readings.append({"time_s": timestamp, "tension_g": value})

except KeyboardInterrupt:
	print(f"\nStopped. {len(readings)} readings collected. ")

with open(OUTPUT_FILE, "w", newline="") as f:
	writer = csv.DictWriter(f, fieldnames=["time_s", "tension_g"])
	writer.writeheader()
	writer.writerows(readings)

print(f"Saved to {OUTPUT_FILE}")
