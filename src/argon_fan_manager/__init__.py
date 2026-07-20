import time

from smbus2 import SMBus

TEMPERATURE_PATH = "/sys/class/thermal/thermal_zone0/temp"
FAN_ADDRESS = 0x1A


def main():
    current_fan_speed = None
    with SMBus(1) as bus:
        while True:
            with open(TEMPERATURE_PATH, "r") as temperature_file:
                # original unit is, apparently, millidegree centigrade!
                temperature = int(temperature_file.readline()) / 1000

            # I tweaked these parameters slightly from Argon's default.
            # Who knows what I was thinking!
            if temperature >= 65:
                fan_speed = 100
            elif temperature >= 55:
                fan_speed = 55
            elif temperature >= 50:
                fan_speed = 25
            else:
                fan_speed = 0

            if current_fan_speed != fan_speed:
                print(
                    f"Fan speed was {current_fan_speed}, now setting to {fan_speed}",
                    flush=True,
                )
                if fan_speed > 0:
                    bus.write_byte(FAN_ADDRESS, 100)
                    time.sleep(1)
                bus.write_byte(FAN_ADDRESS, fan_speed)
                current_fan_speed = fan_speed

            time.sleep(60)


if __name__ == "__main__":
    main()
