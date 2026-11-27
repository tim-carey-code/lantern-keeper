"""Soft lamp-beam loops for Lantern Keeper (synthesized, ours: no third-party licence).
Every component is periodic over the loop length, so the loop is seamless."""
import numpy as np, wave
SR = 44100
DUR = 3.0
N = int(SR * DUR)
t = np.arange(N) / SR
rng = np.random.default_rng(7)

def tone(f, amp=1.0, ph=0.0):
    f = round(f * DUR) / DUR          # whole number of cycles in the loop
    return amp * np.sin(2 * np.pi * f * t + ph)

def band_noise(lo, hi, slope=0.0):
    """Circular (loop-safe) noise limited to lo..hi Hz."""
    spec = np.fft.rfft(rng.standard_normal(N))
    fr = np.fft.rfftfreq(N, 1 / SR)
    mask = ((fr >= lo) & (fr <= hi)).astype(float)
    mask *= (np.maximum(fr, 1) / lo) ** slope
    # soften the band edges
    k = np.ones(25) / 25
    mask = np.convolve(mask, k, mode="same")
    x = np.fft.irfft(spec * mask, N)
    return x / (np.max(np.abs(x)) + 1e-9)

def slow(f):       # slow breathing, whole cycles per loop
    return 0.5 + 0.5 * np.sin(2 * np.pi * round(f * DUR) / DUR * t)

def finish(x, name, peak=0.5):
    x = x - np.mean(x)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    pcm = (x * 32767).astype(np.int16)
    with wave.open(name, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(name, f"{DUR}s", "peak", round(float(np.max(np.abs(x))), 2))

# 1 HUM: warm and low, like a lantern's glow given a voice
hum = (tone(110, 1.0) + tone(220, 0.45) + tone(330, 0.2) + tone(441, 0.08)) * (0.85 + 0.15 * slow(1.0 / DUR * 2))
hum += 0.10 * band_noise(1200, 4000) * slow(1.0 / DUR * 3)
finish(hum, "beam_a_hum.wav")

# 2 GLOW: airy shimmer, detuned pairs that slowly beat (like light rippling)
glow = (tone(196, 0.8) + tone(196 * 1.0 + 1.0 / DUR * 6, 0.6) + tone(294, 0.4) + tone(294 + 1.0 / DUR * 9, 0.35)
        + tone(588, 0.12) + tone(784, 0.07))
glow *= 0.75 + 0.25 * slow(1.0 / DUR * 4)
glow += 0.22 * band_noise(2500, 7500) * slow(1.0 / DUR * 2)
finish(glow, "beam_b_glow.wav")

# 3 BURN: a thin hum plus a hissing, crackling scorch, for the beam eating an enemy
burn = tone(140, 0.6) + tone(280, 0.3) + tone(420, 0.12)
burn += 0.55 * band_noise(1800, 9000) * (0.6 + 0.4 * slow(1.0 / DUR * 5))
crack = np.zeros(N)
for _ in range(34):
    i = rng.integers(0, N - 700)
    n = rng.integers(60, 420)
    env = np.exp(-np.arange(n) / (n / 4))
    crack[i:i + n] += rng.standard_normal(n) * env * rng.uniform(0.25, 1.0)
burn += 0.9 * crack
finish(burn, "beam_c_burn.wav")

# loop-seam check: the jump from the last sample to the first, relative to the typical step
for nme, x in (("hum", hum), ("glow", glow), ("burn", burn)):
    x = x / np.max(np.abs(x))
    print(nme, "seam jump", round(float(abs(x[0] - x[-1])), 4), "typical step", round(float(np.mean(np.abs(np.diff(x)))), 4))
