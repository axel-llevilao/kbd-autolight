"""Tests that run without hardware: python3 -m unittest discover tests"""
import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest

SRC = os.path.join(os.path.dirname(__file__), "..", "src", "kbd-autolight")


def load_module():
    loader = importlib.machinery.SourceFileLoader("kbd_autolight", SRC)
    spec = importlib.util.spec_from_loader("kbd_autolight", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


m = load_module()
CFG = dict(m.DEFAULTS)


def fake_sysfs(root, raw=36400, level=0):
    """Mimics the Yoga Slim 7 ProX: a colour sensor, a plain sensor and the LED."""
    def write(path, value):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(f"{value}\n")
    iio = os.path.join(root, "bus/iio/devices")
    color, plain = os.path.join(iio, "iio:device0"), os.path.join(iio, "iio:device1")
    for dev in (color, plain):
        write(f"{dev}/name", "als")
        write(f"{dev}/in_illuminance_raw", raw)
        write(f"{dev}/in_illuminance_scale", "0.010000000")
        write(f"{dev}/in_illuminance_offset", 0)
    write(f"{color}/in_chromaticity_x_raw", 1)
    led = os.path.join(root, "class/leds/platform::kbd_backlight")
    write(f"{led}/brightness", level)
    write(f"{led}/max_brightness", 2)
    return plain


class TargetLevel(unittest.TestCase):
    def test_bright_room_turns_off(self):
        for cur in (0, 1, 2):
            self.assertEqual(m.target_level(364, cur, 2, CFG), 0)

    def test_dark_room_goes_to_max(self):
        for cur in (0, 1, 2):
            self.assertEqual(m.target_level(3, cur, 2, CFG), 2)

    def test_dim_light_uses_low_level(self):
        self.assertEqual(m.target_level(50, 0, 2, CFG), 1)
        self.assertEqual(m.target_level(50, 2, 2, CFG), 1)

    def test_hysteresis_keeps_level_near_thresholds(self):
        self.assertEqual(m.target_level(110, 1, 2, CFG), 1)   # just above dim_lux
        self.assertEqual(m.target_level(90, 0, 2, CFG), 0)    # just below dim_lux
        self.assertEqual(m.target_level(22, 2, 2, CFG), 2)    # just above dark_lux

    def test_on_off_keyboard(self):
        self.assertEqual(m.target_level(5, 0, 1, CFG), 1)
        self.assertEqual(m.target_level(500, 1, 1, CFG), 0)


class Sysfs(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.plain = fake_sysfs(self.tmp.name, raw=1900, level=1)
        m.SYSFS = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def test_prefers_plain_sensor_over_colour_sensor(self):
        self.assertEqual(m.find_sensor(), self.plain)

    def test_lux_uses_scale(self):
        self.assertAlmostEqual(m.read_lux(m.find_sensor()), 19.0)

    def test_status_json(self):
        env = dict(os.environ, KBD_AUTOLIGHT_SYSFS=self.tmp.name,
                   XDG_RUNTIME_DIR=self.tmp.name)
        out = subprocess.run([sys.executable, SRC, "status"], env=env,
                             capture_output=True, text=True, check=True).stdout
        s = json.loads(out)
        self.assertEqual((s["lux"], s["level"], s["max"], s["sensor"]), (19.0, 1, 2, True))


if __name__ == "__main__":
    unittest.main()
