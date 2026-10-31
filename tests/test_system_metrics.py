import importlib.util
import json
from pathlib import Path
import selectors
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'config/sessions/hyprland/scripts/quickshell/watchers/system_metrics.py'
spec = importlib.util.spec_from_file_location('system_metrics', SCRIPT)
metrics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(metrics)


class MetricsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'net').mkdir()
        (self.root / 'meminfo').write_text('MemTotal: 1048576 kB\nMemAvailable: 262144 kB\n')
        self.sampler = metrics.Sampler(self.root, self.root / 'sys')
        self.write_sample(100, 800, 100, 1000, 2000)

    def write_sample(self, user, idle, iowait, rx, tx, extra=''):
        cpu = f'{user} 0 0 {idle} {iowait} 0 0 0 50 0'
        (self.root / 'stat').write_text(f'cpu {cpu}\ncpu0 {cpu}\nintr 1\n')
        (self.root / 'net/dev').write_text(f'eth0: {rx} 0 0 0 0 0 0 0 {tx} 0 0 0 0 0 0 0\n' + extra)

    def test_cpu_deltas_memory_and_real_network_interval(self):
        first = self.sampler.sample(True, now=10)
        self.assertEqual(first['cpu'], 0)
        self.assertEqual(first['ramPercent'], 75)
        self.assertEqual(first['ramGb'], .75)
        self.write_sample(150, 825, 125, 1500, 3000)
        result = self.sampler.sample(True, now=12.5)
        self.assertEqual(result['cpu'], 50)  # iowait counts as idle; guest is not counted twice.
        self.assertEqual(result['coreCpu'], [50])
        self.assertEqual(result['netRx'], 200)
        self.assertEqual(result['netTx'], 400)

    def test_reset_and_hotplug_do_not_spike(self):
        self.sampler.sample(True, now=1)
        self.write_sample(0, 0, 0, 0, 0, 'wlan0: 9000000 0 0 0 0 0 0 0 9000000 0 0 0 0 0 0 0\n')
        result = self.sampler.sample(True, now=2)
        self.assertEqual(result['cpu'], 0)
        self.assertEqual(result['netRx'], 0)
        self.assertEqual(result['netTx'], 0)

    def test_basic_mode_does_not_read_network_or_temperature(self):
        (self.root / 'net/dev').unlink()
        self.sampler.temperature = lambda: self.fail('temperature read in basic mode')
        result = self.sampler.sample(False, now=1)
        self.assertNotIn('coreCpu', result)
        self.assertNotIn('netRx', result)

    def test_temperature_sensor_is_reused(self):
        sensor = self.root / 'sys/class/hwmon/hwmon0'
        sensor.mkdir(parents=True)
        (sensor / 'name').write_text('k10temp')
        (sensor / 'temp1_input').write_text('42000')
        self.assertEqual(self.sampler.sample(True, now=1)['temp'], 42)
        (sensor / 'temp1_input').write_text('43000')
        self.assertEqual(self.sampler.sample(True, now=2)['temp'], 43)

    def test_daemon_mode_switch_and_exit_on_closed_input(self):
        process = subprocess.Popen([sys.executable, '-u', str(SCRIPT)], stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.addCleanup(lambda: process.poll() is None and process.kill())
        selector = selectors.DefaultSelector()
        selector.register(process.stdout, selectors.EVENT_READ)
        self.addCleanup(selector.close)

        def read_frame():
            self.assertTrue(selector.select(5), 'collector timed out')
            return json.loads(process.stdout.readline())

        self.assertNotIn('coreCpu', read_frame())
        process.stdin.write(b'details 1\n')
        process.stdin.flush()
        self.assertIn('coreCpu', read_frame())
        process.stdin.write(b'details 0\n')
        process.stdin.flush()
        self.assertNotIn('coreCpu', read_frame())
        process.stdin.close()
        self.assertEqual(process.wait(timeout=2), 0)
        process.stdout.close()
        process.stderr.close()


if __name__ == '__main__':
    unittest.main()
