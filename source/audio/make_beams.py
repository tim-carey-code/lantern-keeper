"""Beam 'burn' v2: less static than v1. 6 s seamless loop. Synthesized (ours, no third-party licence).
Adds: slow swelling and fading of the hiss, a drifting pitch on the hum, a rising-then-falling
shimmer, crackles that cluster into bursts, and a faint low throb."""
import numpy as np, wave
SR = 44100; DUR = 6.0; N = int(SR * DUR)
t = np.arange(N) / SR
rng = np.random.default_rng(11)
W = 2 * np.pi

def cyc(f):                      # frequency rounded to whole cycles per loop
    return round(f * DUR) / DUR

def band_noise(lo, hi):
    spec = np.fft.rfft(rng.standard_normal(N)); fr = np.fft.rfftfreq(N, 1 / SR)
    m = np.convolve(((fr >= lo) & (fr <= hi)).astype(float), np.ones(41) / 41, mode="same")
    x = np.fft.irfft(spec * m, N); return x / (np.abs(x).max() + 1e-9)

def lfo(f, ph=0.0):              # 0..1, loop-safe
    return 0.5 + 0.5 * np.sin(W * cyc(f) * t + ph)

def write(x, name, peak=0.5):
    x = x - x.mean(); x = x / (np.abs(x).max() + 1e-9) * peak
    with wave.open(name, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())

def build(crack_density, hiss_amt, bright):
    # hum with a slowly drifting pitch (phase-modulated, loop-safe)
    drift = 2.2 * np.sin(W * cyc(1 / DUR * 2) * t) + 0.8 * np.sin(W * cyc(1 / DUR * 5) * t + 1.3)
    hum = (np.sin(W * cyc(130) * t + drift) + 0.5 * np.sin(W * cyc(260) * t + 2 * drift)
           + 0.25 * np.sin(W * cyc(390) * t + 3 * drift) + 0.12 * np.sin(W * cyc(520) * t))
    hum *= 0.6 + 0.4 * lfo(1 / DUR * 3, 0.7)
    # low throb, like a slow pulse in the light
    throb = np.sin(W * cyc(55) * t) * lfo(1 / DUR * 4, 2.0) * 0.5
    # hiss that swells and fades on two unrelated slow cycles
    hiss = band_noise(1500, 9000) * (0.25 + 0.75 * lfo(1 / DUR * 2, 0.3) * lfo(1 / DUR * 3, 1.9))
    # shimmer: a high airy band that rises and falls
    shim = band_noise(4000, 10000) * lfo(1 / DUR * 1, 3.9) * bright
    # crackles clustered into bursts: burst centres are random, crackles gather around them
    crack = np.zeros(N)
    for c in rng.uniform(0, N, 9):
        for _ in range(crack_density):
            i = int((c + rng.normal(0, SR * 0.18)) % (N - 900))
            n = int(rng.integers(50, 500)); env = np.exp(-np.arange(n) / (n / 4))
            crack[i:i + n] += rng.standard_normal(n) * env * rng.uniform(0.2, 1.0)
    # a few louder 'snaps'
    for _ in range(7):
        i = int(rng.integers(0, N - 1500)); n = int(rng.integers(200, 900)); env = np.exp(-np.arange(n) / (n / 6))
        crack[i:i + n] += rng.standard_normal(n) * env * 1.6
    return 0.8 * hum + 0.45 * throb + hiss_amt * hiss + 0.5 * shim + 0.9 * crack

write(build(9, 0.55, 0.5), "beam_c2_burn_lively.wav")      # busier, crackly
write(build(4, 0.35, 0.9), "beam_c3_burn_airy.wav")        # calmer, more shimmer
write(build(14, 0.7, 0.25), "beam_c4_burn_fierce.wav")     # most aggressive
for n in ("c2_burn_lively", "c3_burn_airy", "c4_burn_fierce"):
    w = wave.open(f"beam_{n}.wav"); x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)
    d = np.abs(np.diff(x)); print(n, round(len(x) / SR, 1), "s  seam", int(abs(x[0] - x[-1])), " 99th pct step", int(np.percentile(d, 99)))
