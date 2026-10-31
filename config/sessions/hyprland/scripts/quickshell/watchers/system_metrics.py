#!/usr/bin/env python3
"""One sampler per shell; JSON lines out, 'details 0/1' commands on stdin."""
import json
import os
from pathlib import Path
import selectors
import sys
import time


class Sampler:
    def __init__(self, proc=Path('/proc'), sysfs=Path('/sys')):
        self.proc, self.sysfs = proc, sysfs
        self.previous_cpu, self.previous_net = {}, {}
        self.previous_time = None
        self.temperature_path = None

    def cpu_times(self, details):
        result = {}
        with (self.proc / 'stat').open() as stream:
            for line in stream:
                fields = line.split()
                if not fields or not fields[0].startswith('cpu'):
                    break
                values = [int(v) for v in fields[1:9]]
                # guest/guest_nice are already included in user/nice.
                result[fields[0]] = (sum(values), values[3] + values[4])
                if not details:
                    break
        return result

    @staticmethod
    def utilization(current, previous):
        if previous is None:
            return 0
        total, idle = current[0] - previous[0], current[1] - previous[1]
        return max(0, min(100, round(100 * (total - idle) / total))) if total > 0 else 0

    def temperature(self):
        if self.temperature_path is None:
            for directory in sorted((self.sysfs / 'class/hwmon').glob('hwmon*')):
                try:
                    if (directory / 'name').read_text().strip() in {
                        'coretemp', 'k10temp', 'zenpower', 'cpu_thermal', 'bcm2835_thermal'
                    } and (directory / 'temp1_input').exists():
                        self.temperature_path = directory / 'temp1_input'
                        break
                except OSError:
                    continue
        try:
            return round(int(self.temperature_path.read_text()) / 1000) if self.temperature_path else 0
        except (OSError, ValueError):
            self.temperature_path = None
            return 0

    def sample(self, details=False, now=None):
        now = time.monotonic() if now is None else now
        cpus = self.cpu_times(details)
        memory = {}
        for line in (self.proc / 'meminfo').read_text().splitlines():
            key, value = line.split(':', 1)
            if key in ('MemTotal', 'MemAvailable'):
                memory[key] = int(value.split()[0])
        total = memory.get('MemTotal', 0)
        used = max(0, total - memory.get('MemAvailable', total))
        result = {
            'cpu': self.utilization(cpus['cpu'], self.previous_cpu.get('cpu')),
            'ramPercent': round(100 * used / total) if total else 0,
            'ramGb': used / 1048576, 'ramTotalGb': total / 1048576,
        }
        if details:
            result['coreCpu'] = [self.utilization(value, self.previous_cpu.get(name))
                                 for name, value in cpus.items() if name != 'cpu']
            result['temp'] = self.temperature()
            interfaces = {}
            for line in (self.proc / 'net/dev').read_text().splitlines():
                if ':' not in line:
                    continue
                name, data = line.split(':', 1)
                name = name.strip()
                # Physical ethernet/Wi-Fi/WWAN interfaces, as in the old collector.
                if name.startswith(('e', 'w')):
                    values = data.split()
                    interfaces[name] = (int(values[0]), int(values[8]))
            elapsed = now - self.previous_time if self.previous_time is not None else 0
            for index, key in enumerate(('netRx', 'netTx')):
                delta = sum(max(0, values[index] - self.previous_net[name][index])
                            for name, values in interfaces.items() if name in self.previous_net)
                result[key] = delta / elapsed if elapsed > 0 else 0
            self.previous_net = interfaces
        else:
            self.previous_net = {}
        self.previous_cpu = cpus
        self.previous_time = now
        return result


def main():
    sampler = Sampler()
    details = False
    selector = selectors.DefaultSelector()
    selector.register(sys.stdin, selectors.EVENT_READ)
    pending = b''
    deadline = time.monotonic()
    while True:
        if time.monotonic() >= deadline:
            try:
                print(json.dumps(sampler.sample(details), separators=(',', ':')), flush=True)
            except (OSError, ValueError, KeyError) as error:
                print(f'system_metrics: {error}', file=sys.stderr)
            deadline = time.monotonic() + (2 if details else 3)
        if selector.select(max(0, deadline - time.monotonic())):
            data = os.read(sys.stdin.fileno(), 4096)
            if not data:
                return  # Exit when Quickshell closes the pipe; no orphan collector.
            pending += data
            while b'\n' in pending:
                line, pending = pending.split(b'\n', 1)
                if line in (b'details 0', b'details 1'):
                    updated = line == b'details 1'
                    if updated != details:
                        details = updated
                        deadline = time.monotonic()


if __name__ == '__main__':
    main()
