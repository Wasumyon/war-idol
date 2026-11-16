# Placeholder SFX for the acid pool: art/sfx/acid_*.wav (stdlib only).
import wave, struct, random, math
SR = 22050
def save(name, xs):
    peak = max(1e-6, max(abs(x) for x in xs))
    w = wave.open(f"art/sfx/{name}.wav", "wb")
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(32000 * 0.9 * x / peak)) for x in xs))
    w.close()
rnd = random.Random(3)

# sizzle: crackling hiss, seamless-ish loop (fades at both ends are tiny)
n = int(SR * 1.6); xs = []; lp = 0.0
for i in range(n):
    white = rnd.uniform(-1, 1)
    hp = white - lp; lp += 0.35 * (white - lp)      # high-passed hiss
    crackle = rnd.uniform(-1, 1) * (1.0 if rnd.random() < 0.004 else 0.0) * 3
    env = min(1.0, i / 400, (n - i) / 400)
    xs.append((hp * 0.35 + crackle) * env)
save("acid_sizzle", xs)

def blub(xs, start, f0, f1, dur, amp):
    m = int(SR * dur); ph = 0.0
    for i in range(m):
        t = i / m
        ph += 2 * math.pi * (f0 + (f1 - f0) * t) / SR
        k = start + i
        if k < len(xs): xs[k] += math.sin(ph) * amp * math.sin(math.pi * t) ** 2

# squelch: low wet slap + rising blub
n = int(SR * 0.22); xs = [0.0] * n; lp = 0.0
for i in range(n):
    lp += 0.08 * (rnd.uniform(-1, 1) - lp)
    xs[i] = lp * 3 * math.exp(-i / (SR * 0.04))
blub(xs, int(SR * 0.03), 140, 420, 0.12, 0.6)
save("acid_squelch", xs)

# bubble surge: half a second of quickening blubs
n = int(SR * 0.6); xs = [0.0] * n
t = 0.0
while t < 0.55:
    blub(xs, int(t * SR), rnd.uniform(180, 300), rnd.uniform(500, 900), rnd.uniform(0.03, 0.06), rnd.uniform(0.4, 1.0) * (0.4 + t))
    t += 0.09 * (1 - t) + 0.012
save("acid_bubbles", xs)

# burst: splash eruption
n = int(SR * 0.5); xs = [0.0] * n; lp = 0.0
for i in range(n):
    lp += 0.25 * (rnd.uniform(-1, 1) - lp)
    xs[i] = lp * 2 * math.exp(-i / (SR * 0.12))
blub(xs, 0, 90, 60, 0.25, 0.9)
save("acid_burst", xs)
