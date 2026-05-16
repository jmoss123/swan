import time
import RPi.GPIO as gpio
from hx711 import HX711

# Setup
hx = HX711(5, 6)
hx.set_reading_format("MSB", "MSB")
hx.set_reference_unit(1)
hx.reset()
hx.tare()

# Calibration
num_samples = 15
known_weight = float(input("Place known weight and enter weight in grams: "))

print("Collecting samples...")
samples = []
for i in range(num_samples):
    reading = hx.get_weight(1)
    samples.append(reading)
    print(f"{i+1}: {reading}")
    time.sleep(0.1)

# Calculate reference unit
average_reading = sum(samples) / len(samples)
reference_unit = average_reading / known_weight

print(f"\nAverage reading: {average_reading:.1f}")
print(f"Reference unit: {reference_unit:.2f}")
print(f"\nAdd this to your script:")
print(f"hx.set_reference_unit({reference_unit:.2f})")

gpio.cleanup()
