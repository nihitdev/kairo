#!/usr/bin/env python3
"""CPU-reactive font frames, capped at 5 fps with one CPU sample per second."""
import sys
import time

kind = sys.argv[1]

def cpu():
    with open("/proc/stat", encoding="ascii") as stat:
        ticks = list(map(int, stat.readline().split()[1:9]))
    total = sum(ticks)
    return total - ticks[3] - ticks[4], total

previous = cpu()
usage = 0.0
idle_samples = 0
sample_at = time.monotonic() + 1
frame = 0
try:
    while True:
        now = time.monotonic()
        if now >= sample_at:
            current = cpu()
            elapsed = current[1] - previous[1]
            usage = max(0.0, min(1.0, (current[0] - previous[0]) / elapsed)) if elapsed > 0 else 0.0
            previous = current
            idle_samples = idle_samples + 1 if usage < 0.02 else 0
            sample_at = now + 1
        asleep = idle_samples >= 4
        if kind == "cat":
            frames = "GHIJKLMN" if asleep else "ABCDE"
        else:
            frames = "abcdefghijklmnopqrst" if asleep else ("ABCDEFGHI" if usage > 0.6 else "JKLMNOPQRS")
        print(frames[frame % len(frames)], flush=True)
        frame += 1
        time.sleep(0.5 if asleep else max(0.2, 0.35 - usage * 0.15))
except (BrokenPipeError, KeyboardInterrupt):
    pass
