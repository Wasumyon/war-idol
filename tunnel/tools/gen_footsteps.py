"""Generate short, dry boot impacts and resonant catwalk variants (stdlib only)."""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / 'art' / 'sfx'
SR = 22050
for heavy in (False, True):
    for metal in (False, True):
        for variant in range(3):
            rng = random.Random(100 + variant + 10 * heavy + 20 * metal)
            samples = []
            low = 0.0
            duration = 0.30 if metal else 0.18
            fundamental = (76 if heavy else 115) * rng.uniform(.94, 1.06)
            for i in range(int(SR * duration)):
                t = i / SR
                white = rng.uniform(-1, 1)
                low += .15 * (white - low)
                attack = min(1, t / .002)
                thud = math.sin(2 * math.pi * fundamental * t) * math.exp(-t * 48)
                grit = (.65 * low + .12 * white) * math.exp(-t * 60)
                value = .65 * thud + grit
                if metal:
                    for freq, amp in ((337, .21), (583, .13), (973, .07)):
                        value += amp * math.sin(2 * math.pi * freq * t) * math.exp(-t * 21)
                    value += .12 * white * math.exp(-t * 95)
                value *= attack * min(1, (duration - t) / .025)
                samples.append(value)
            name = f"step_{'guard' if heavy else 'player'}_{'metal' if metal else 'concrete'}_{variant}.wav"
            with wave.open(str(OUT / name), 'wb') as wav:
                wav.setparams((1, 2, SR, 0, 'NONE', 'not compressed'))
                wav.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x)) * 24000)) for x in samples))
