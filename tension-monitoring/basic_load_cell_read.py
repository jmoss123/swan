import time
from HX711 import SimpleHX711, Mass

# --- Configuration ---
DT_PIN  = 5   # GPIO 5, Pi pin 29
SCK_PIN = 6   # GPIO 6, Pi pin 31

REFERENCE_UNIT = -94      # replace after calibration
OFFSET         = 117625      # replace after calibration

# --- Initialise ---
hx = SimpleHX711(DT_PIN, SCK_PIN, REFERENCE_UNIT, OFFSET)
hx.setUnit(Mass.Unit.G)
hx.zero()
print("Scale zeroed. Starting readings...")

# --- Read loop ---
try:
    while True:
        weight = hx.weight(1)
        print(f"Tension: {weight}")
        time.sleep(0.02)

except KeyboardInterrupt:
    print("Stopped.")

