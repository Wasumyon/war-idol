"""Placeholder SFX for the intro: explosion, rumble, floor crack, debris, scuff, jump whoosh."""
from pathlib import Path
import wave
import numpy as np

OUT = Path(__file__).resolve().parents[1] / 'art' / 'sfx'
SR = 22050
rng = np.random.default_rng(7)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def lowpass(x, a):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += a * (v - acc)
        y[i] = acc
    return y


def env(t, attack, decay):
    return np.minimum(1, t / max(attack, 1e-4)) * np.exp(-t * decay)


def save(name, x, peak=0.9):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    fade = min(len(x), int(SR * 0.03))
    x[-fade:] *= np.linspace(1, 0, fade)
    with wave.open(str(OUT / name), 'wb') as w:
        w.setparams((1, 2, SR, 0, 'NONE', 'not compressed'))
        w.writeframes((np.clip(x, -1, 1) * 30000).astype('<i2').tobytes())


# Explosion: a sharp crack, a deep body that drops in pitch, and a long rumbling tail.
t = t_axis(3.2)
noise = rng.uniform(-1, 1, len(t))
body = lowpass(noise, 0.035) * 9 * env(t, 0.004, 1.6)
thump = np.sin(2 * np.pi * (55 * t - 18 * t * t)) * env(t, 0.002, 4.5) * 0.9
crack = noise * env(t, 0.0005, 38) * 0.8
save('intro_boom.wav', body + thump + crack)

# Low rumble bed under the black screen.
t = t_axis(10.0)
r = lowpass(rng.uniform(-1, 1, len(t)), 0.012) * 14
r *= 0.75 + 0.25 * np.sin(2 * np.pi * 0.7 * t)
loop_fade = int(SR * 0.25)
r[:loop_fade] *= np.linspace(0, 1, loop_fade)
save('intro_rumble.wav', r, 0.7)

# Floor cracking: splintering snaps over a groan.
t = t_axis(1.6)
x = lowpass(rng.uniform(-1, 1, len(t)), 0.05) * 4 * env(t, 0.05, 1.8)
for start in sorted(rng.uniform(0.0, 0.9, 14)):
    i = int(start * SR)
    n = int(SR * 0.05)
    snap = rng.uniform(-1, 1, n) * np.exp(-np.arange(n) / SR * 90) * rng.uniform(0.4, 1.0)
    x[i:i + n] += snap[:len(x) - i]
save('intro_crack.wav', x)

# Debris: chunks tumbling away into a deep shaft (thuds get fainter and duller).
t = t_axis(2.6)
x = lowpass(rng.uniform(-1, 1, len(t)), 0.08) * 1.2 * env(t, 0.02, 1.2)
for k, start in enumerate(sorted(rng.uniform(0.0, 2.2, 22))):
    i = int(start * SR)
    n = int(SR * 0.12)
    tt = np.arange(n) / SR
    hit = (np.sin(2 * np.pi * rng.uniform(90, 200) * tt) + rng.uniform(-0.6, 0.6, n)) * np.exp(-tt * 40)
    hit *= np.exp(-start * 1.1)
    x[i:i + n] += hit[:len(x) - i]
save('intro_debris.wav', x)

# Boot scuff on grit (backing up).
t = t_axis(0.35)
x = lowpass(rng.uniform(-1, 1, len(t)), 0.25) * np.sin(np.pi * np.minimum(1, t / 0.3)) ** 2
save('intro_scuff.wav', x, 0.6)

# Jump: a sharp push-off and rushing air that swells as he drops.
t = t_axis(1.3)
air = rng.uniform(-1, 1, len(t))
sweep = np.concatenate([lowpass(air[:len(t) // 2], 0.04), lowpass(air[len(t) // 2:], 0.12)])
x = sweep * 3 * np.minimum(1, t / 0.5) * np.exp(-np.maximum(0, t - 0.9) * 6)
push = lowpass(rng.uniform(-1, 1, len(t)), 0.3) * np.exp(-t * 30) * 1.5
save('intro_jump.wav', x + push)
print('ok')
