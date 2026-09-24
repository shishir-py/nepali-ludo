"""Original, procedurally-synthesised sound effects + music for Nepali Ludo.

Everything here is generated from maths (oscillators, noise, envelopes), so the
output is original work that can be shipped in an open-source repo.

Produces assets/sounds/<event>_<n>.mp3 for every slot declared in
lib/audio/sound_library.dart.
"""
import os
import subprocess
import numpy as np
from scipy.signal import lfilter

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "sounds")  # → copy into assets/sounds/
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


# ─── primitives ──────────────────────────────────────────────────────────────
def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env_exp(dur, decay, attack=0.002):
    t = t_axis(dur)
    a = np.clip(t / attack, 0, 1) if attack > 0 else 1.0
    return a * np.exp(-t / decay)


def adsr(dur, a=0.01, d=0.05, s=0.7, r=0.1):
    n = int(SR * dur)
    e = np.ones(n) * s
    na, nd, nr = int(SR * a), int(SR * d), int(SR * r)
    na = max(na, 1)
    e[:na] = np.linspace(0, 1, na)
    if nd > 0:
        e[na:na + nd] = np.linspace(1, s, len(e[na:na + nd]))
    if nr > 0:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def sine(freq, dur, phase=0.0):
    t = t_axis(dur)
    if np.ndim(freq) == 0:
        return np.sin(2 * np.pi * freq * t + phase)
    ph = 2 * np.pi * np.cumsum(freq) / SR
    return np.sin(ph + phase)


def square(freq, dur, duty=0.5):
    t = t_axis(dur)
    ph = (freq * t) % 1.0 if np.ndim(freq) == 0 else (np.cumsum(freq) / SR) % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def tri(freq, dur):
    t = t_axis(dur)
    ph = (freq * t) % 1.0
    return 2 * np.abs(2 * ph - 1) - 1


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def lowpass(x, cutoff):
    # one-pole
    a = np.exp(-2 * np.pi * cutoff / SR)
    return lfilter([1 - a], [1, -a], x)


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def bandpass(x, lo, hi):
    return lowpass(highpass(x, lo), hi)


def sweep(f0, f1, dur, curve="exp"):
    n = int(SR * dur)
    if curve == "exp":
        return f0 * (f1 / f0) ** np.linspace(0, 1, n)
    return np.linspace(f0, f1, n)


def pad(x, dur):
    n = int(SR * dur)
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def mix(*parts, dur=None):
    if dur is None:
        dur = max(len(p) for p in parts) / SR
    out = np.zeros(int(SR * dur))
    for p in parts:
        out[: len(p)] += p[: len(out)]
    return out


def place(buf, x, at):
    i = int(SR * at)
    end = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:end] += x[: end - i]
    return buf


def bell(freq, dur, decay=0.5, bright=1.0):
    partials = [(1, 1.0), (2.0, 0.6 * bright), (2.76, 0.4 * bright),
                (5.4, 0.25 * bright), (8.93, 0.12 * bright)]
    out = np.zeros(int(SR * dur))
    for ratio, amp in partials:
        out += amp * sine(freq * ratio, dur) * env_exp(dur, decay / (1 + ratio * 0.3))
    return out


def pluck(freq, dur, damp=0.996):
    """Karplus-Strong plucked string (sitar/sarangi-ish)."""
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    buf = rng.uniform(-1, 1, period)
    out = np.zeros(n)
    for i in range(n):
        v = buf[i % period]
        out[i] = v
        buf[i % period] = damp * 0.5 * (v + buf[(i + 1) % period])
    return out


def drum(freq=90, dur=0.35, drop=0.4, noise_amt=0.15):
    f = sweep(freq * 1.8, freq * drop + freq * 0.5, dur)
    body = sine(f, dur) * env_exp(dur, dur / 3.5)
    slap = lowpass(noise(dur), 3000) * env_exp(dur, 0.02) * noise_amt
    return body + slap


def click(dur=0.03, freq=2500, decay=0.004):
    return (bandpass(noise(dur), freq * 0.5, freq * 1.5) * 3 +
            0.5 * sine(freq, dur)) * env_exp(dur, decay)


def normalize(x, peak=0.89):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def fade(x, fin=0.003, fout=0.02):
    n_in, n_out = int(SR * fin), int(SR * fout)
    if n_in:
        x[:n_in] *= np.linspace(0, 1, n_in)
    if n_out:
        x[-n_out:] *= np.linspace(1, 0, n_out)
    return x


def save(name, x, peak=0.89, bitrate="96k"):
    x = fade(normalize(x, peak))
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    path = os.path.join(OUT, name + ".mp3")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR),
         "-ac", "1", "-i", "-", "-codec:a", "libmp3lame", "-b:a", bitrate, path],
        input=pcm, check=True)


NOTE = lambda m: 440.0 * 2 ** ((m - 69) / 12)


# ─── dice (6) ────────────────────────────────────────────────────────────────
def dice(v):
    dur = 0.75
    out = np.zeros(int(SR * dur))
    hits = [8, 11, 6, 13, 9, 7][v]
    base = [2200, 1800, 2600, 1500, 3000, 2000][v]
    t = 0.0
    gap = 0.03
    for i in range(hits):
        f = base * rng.uniform(0.8, 1.25)
        amp = 1.0 - i / (hits + 2)
        place(out, click(0.04, f, 0.006) * amp, t)
        t += gap
        gap *= rng.uniform(1.08, 1.25)
    # final wooden settle
    place(out, drum(220 + v * 30, 0.15, 0.8, 0.4) * 0.6, min(t, dur - 0.16))
    return out


# ─── token move (4) — wooden 'tok' ──────────────────────────────────────────
def move(v):
    dur = 0.14
    f = [700, 900, 560, 1150][v]
    body = sine(sweep(f * 1.3, f, dur), dur) * env_exp(dur, 0.025)
    knock = bandpass(noise(dur), f, f * 4) * env_exp(dur, 0.006) * 0.8
    sub = sine(f / 2, dur) * env_exp(dur, 0.03) * 0.4
    return body + knock + sub


# ─── kill (10) ───────────────────────────────────────────────────────────────
def kill(v):
    if v == 0:  # punchy thud + crack
        d = 0.5
        return mix(drum(70, d, 0.3, 0.6), click(0.08, 1800, 0.02) * 0.8, dur=d)
    if v == 1:  # sword swish + metallic ring
        d = 0.7
        sw = bandpass(noise(0.3), 1500, 7000) * np.sin(np.linspace(0, np.pi, int(SR * 0.3))) ** 2
        ring = bell(1800, d, 0.25, 0.6) * 0.5
        return mix(sw, place(np.zeros(int(SR * d)), ring, 0.18), dur=d)
    if v == 2:  # explosion
        d = 1.1
        n = lowpass(noise(d), 900) * env_exp(d, 0.3, 0.005)
        boom = sine(sweep(120, 35, d), d) * env_exp(d, 0.35)
        return mix(n * 1.4, boom, dur=d)
    if v == 3:  # cartoon bonk (pitch drop)
        d = 0.45
        return (square(sweep(900, 180, d), d, 0.3) * 0.4 + sine(sweep(700, 120, d), d)) * env_exp(d, 0.15)
    if v == 4:  # laser zap
        d = 0.4
        return (square(sweep(2400, 200, d), d) * 0.5 + sine(sweep(1800, 120, d), d)) * env_exp(d, 0.14)
    if v == 5:  # double punch
        d = 0.55
        out = np.zeros(int(SR * d))
        place(out, drum(80, 0.3, 0.3, 0.8), 0)
        place(out, drum(65, 0.3, 0.3, 0.8), 0.16)
        return out
    if v == 6:  # descending 'wah-wah' loser horn
        d = 1.2
        out = np.zeros(int(SR * d))
        for i, m in enumerate([67, 66, 65]):
            seg = (square(NOTE(m), 0.3, 0.4) * 0.5 + tri(NOTE(m), 0.3)) * adsr(0.3, 0.01, 0.05, 0.8, 0.08)
            place(out, lowpass(seg, 1800), i * 0.3)
        f = NOTE(64) * (1 + 0.03 * np.sin(2 * np.pi * 6 * t_axis(0.5)))
        last = (square(f, 0.5, 0.4) * 0.5 + tri(NOTE(64), 0.5)) * adsr(0.5, 0.01, 0.05, 0.8, 0.2)
        place(out, lowpass(last, 1500), 0.9)
        return out
    if v == 7:  # glass smash
        d = 0.9
        n = highpass(noise(d), 3000) * env_exp(d, 0.18, 0.001)
        shards = np.zeros(int(SR * d))
        for _ in range(14):
            place(shards, bell(rng.uniform(2500, 6000), 0.25, 0.08) * 0.3, rng.uniform(0, 0.4))
        return mix(n, shards, drum(90, 0.3, 0.4, 0.2) * 0.5, dur=d)
    if v == 8:  # madal slap combo
        d = 0.6
        out = np.zeros(int(SR * d))
        for i, (f, a) in enumerate([(180, 0.8), (240, 0.7), (110, 1.0)]):
            place(out, drum(f, 0.3, 0.5, 0.6) * a, i * 0.11)
        return out
    # v == 9: whoosh + boom
    d = 0.9
    wh = bandpass(noise(0.45), 400, 4000) * np.linspace(0, 1, int(SR * 0.45)) ** 2
    out = np.zeros(int(SR * d))
    place(out, wh * 0.7, 0)
    place(out, drum(55, 0.45, 0.25, 0.7) * 1.2, 0.42)
    return out


# ─── safe (10) ───────────────────────────────────────────────────────────────
def safe(v):
    if v == 0:  # shield ding
        return bell(NOTE(84), 0.9, 0.45)
    if v == 1:  # temple bell (lower, long)
        return bell(NOTE(69), 1.4, 0.9, 0.8)
    if v == 2:  # sparkle arpeggio
        out = np.zeros(int(SR * 0.9))
        for i, m in enumerate([84, 88, 91, 96]):
            place(out, bell(NOTE(m), 0.5, 0.2) * (0.9 - i * 0.1), i * 0.06)
        return out
    if v == 3:  # two-tone chime
        out = np.zeros(int(SR * 0.8))
        place(out, bell(NOTE(79), 0.6, 0.3), 0)
        place(out, bell(NOTE(84), 0.6, 0.35), 0.12)
        return out
    if v == 4:  # soft pad swell
        d = 0.8
        e = adsr(d, 0.08, 0.1, 0.6, 0.4)
        return sum(sine(NOTE(m), d) for m in [72, 76, 79]) * e
    if v == 5:  # singing bowl
        d = 1.6
        f = NOTE(67)
        wob = 1 + 0.004 * np.sin(2 * np.pi * 4 * t_axis(d))
        return (sine(f * wob, d) + 0.5 * sine(f * 2.71 * wob, d) + 0.25 * sine(f * 5.1, d)) * env_exp(d, 0.7, 0.02)
    if v == 6:  # bubble pop up
        d = 0.25
        return sine(sweep(400, 1400, d), d) * env_exp(d, 0.08)
    if v == 7:  # harp gliss
        out = np.zeros(int(SR * 1.0))
        for i, m in enumerate([72, 74, 76, 79, 81, 84]):
            place(out, pluck(NOTE(m), 0.6, 0.995) * 0.6, i * 0.045)
        return out
    if v == 8:  # coin-like safe
        out = np.zeros(int(SR * 0.4))
        place(out, square(NOTE(88), 0.07, 0.5) * env_exp(0.07, 0.05) * 0.5, 0)
        place(out, square(NOTE(95), 0.3, 0.5) * env_exp(0.3, 0.1) * 0.5, 0.07)
        return lowpass(out, 6000)
    # v == 9: magic shimmer
    d = 1.0
    out = np.zeros(int(SR * d))
    for _ in range(18):
        place(out, bell(rng.uniform(NOTE(84), NOTE(100)), 0.3, 0.1) * 0.25, rng.uniform(0, 0.55))
    return mix(out, bell(NOTE(72), d, 0.4) * 0.5, dur=d)


# ─── six (6) ────────────────────────────────────────────────────────────────
def arpeggio(notes, step, dur_each, voice="bell"):
    total = step * len(notes) + dur_each
    out = np.zeros(int(SR * total))
    for i, m in enumerate(notes):
        if voice == "bell":
            s = bell(NOTE(m), dur_each, 0.3)
        elif voice == "square":
            s = lowpass(square(NOTE(m), dur_each, 0.5), 4000) * adsr(dur_each, 0.005, 0.05, 0.5, 0.05) * 0.5
        else:
            s = pluck(NOTE(m), dur_each)
        place(out, s, i * step)
    return out


def six(v):
    if v == 0:
        return arpeggio([72, 76, 79, 84], 0.07, 0.5)
    if v == 1:
        return arpeggio([67, 71, 74, 79, 83], 0.06, 0.35, "square")
    if v == 2:
        return arpeggio([74, 78, 81, 86, 90], 0.05, 0.6, "pluck")
    if v == 3:  # 'yay' horn stab
        d = 0.6
        chord = sum(lowpass(square(NOTE(m), d, 0.45), 2500) for m in [72, 76, 79])
        return chord * adsr(d, 0.01, 0.1, 0.7, 0.25) * 0.4
    if v == 4:  # drum roll + ding
        out = np.zeros(int(SR * 1.0))
        for i in range(10):
            place(out, drum(200, 0.1, 0.8, 0.5) * (0.4 + i * 0.05), i * 0.04)
        place(out, bell(NOTE(88), 0.6, 0.3), 0.42)
        return out
    return arpeggio([79, 84, 88, 91, 96], 0.045, 0.45)


# ─── home (4) ───────────────────────────────────────────────────────────────
def home(v):
    if v == 0:  # coin
        out = np.zeros(int(SR * 0.45))
        place(out, square(NOTE(83), 0.08, 0.5) * 0.4, 0)
        place(out, square(NOTE(88), 0.35, 0.5) * env_exp(0.35, 0.12) * 0.4, 0.08)
        return lowpass(out, 7000)
    if v == 1:  # level-up
        return arpeggio([60, 64, 67, 72, 76, 79, 84], 0.05, 0.25, "square")
    if v == 2:
        return arpeggio([67, 72, 76, 84], 0.09, 0.8)
    return arpeggio([69, 73, 76, 81], 0.08, 0.7, "pluck")


# ─── win (6) ────────────────────────────────────────────────────────────────
def fanfare(melody, bpm=150, voice="brass"):
    beat = 60 / bpm
    total = sum(d for _, d in melody) * beat + 1.0
    out = np.zeros(int(SR * total))
    t = 0
    for m, d in melody:
        dur = d * beat
        if m is not None:
            if voice == "brass":
                f = NOTE(m)
                s = (lowpass(square(f, dur + 0.2, 0.45), 2200) * 0.5 + tri(f, dur + 0.2)) * adsr(dur + 0.2, 0.02, 0.08, 0.75, 0.15)
                s += 0.3 * sine(f / 2, dur + 0.2) * adsr(dur + 0.2, 0.02, 0.08, 0.75, 0.15)
            elif voice == "bell":
                s = bell(NOTE(m), dur + 0.6, 0.4)
            else:
                s = pluck(NOTE(m), dur + 0.5)
            place(out, s, t)
        t += dur
    return out


def win(v):
    tunes = [
        [(67, .5), (72, .5), (76, .5), (79, 1), (76, .5), (79, 2)],
        [(72, .33), (72, .33), (72, .33), (72, 1), (68, 1), (70, 1), (72, .66), (70, .33), (72, 2)],
        [(60, .5), (64, .5), (67, .5), (72, .5), (76, .5), (79, .5), (84, 2)],
        [(74, .5), (76, .5), (79, 1), (81, .5), (79, .5), (86, 2)],
        [(69, .5), (72, .5), (76, .5), (74, .5), (72, .5), (76, .5), (81, 2)],
        [(79, .25), (81, .25), (83, .25), (84, 1.5), (79, .5), (84, 2)],
    ]
    voice = ["brass", "brass", "bell", "pluck", "bell", "brass"][v]
    out = fanfare(tunes[v], 140 + v * 6, voice)
    # cymbal-ish shimmer at the end
    d = len(out) / SR
    sh = highpass(noise(1.2), 5000) * env_exp(1.2, 0.4) * 0.25
    place(out, sh, max(0, d - 2.0))
    return out


# ─── tap (3) / reaction (4) ─────────────────────────────────────────────────
def tap(v):
    if v == 0:
        return click(0.05, 3200, 0.004) * 0.7 + sine(1200, 0.05) * env_exp(0.05, 0.01) * 0.3
    if v == 1:  # bubble pop
        d = 0.09
        return sine(sweep(500, 1300, d), d) * env_exp(d, 0.03)
    return sine(sweep(1600, 900, 0.06), 0.06) * env_exp(0.06, 0.015)


def reaction(v):
    if v == 0:  # pop
        d = 0.15
        return sine(sweep(300, 1500, d), d) * env_exp(d, 0.05)
    if v == 1:  # slide whistle up
        d = 0.5
        return sine(sweep(600, 2000, d), d) * adsr(d, 0.02, 0.05, 0.8, 0.1)
    if v == 2:  # boing
        d = 0.5
        f = 220 * (1 + 0.5 * np.sin(2 * np.pi * 12 * t_axis(d)) * np.exp(-t_axis(d) * 5))
        return sine(f, d) * env_exp(d, 0.2)
    return arpeggio([79, 84], 0.08, 0.3)


# ─── music (5) — original loops in a Nepali folk flavour ────────────────────
# Madal-style drum pattern + plucked/bansuri melody over a drone.
SCALES = {
    # major-pentatonic-ish modes common in Nepali folk tunes
    "D": [62, 64, 66, 69, 71, 74, 76, 78, 81],
    "G": [67, 69, 71, 74, 76, 79, 81, 83, 86],
    "A": [69, 71, 73, 76, 78, 81, 83, 85, 88],
}


def bansuri(freq, dur):
    t = t_axis(dur)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.2, 0, 1)
    tone = sine(freq * vib, dur) + 0.25 * sine(freq * 2 * vib, dur) + 0.08 * sine(freq * 3 * vib, dur)
    breath = bandpass(noise(dur), freq, freq * 3) * 0.05
    return (tone + breath) * adsr(dur, 0.05, 0.1, 0.8, min(0.15, dur / 3))


def music(v):
    key = ["D", "G", "A", "D", "G"][v]
    bpm = [108, 96, 120, 88, 112][v]
    voice = ["pluck", "flute", "pluck", "flute", "both"][v]
    beat = 60 / bpm
    bars = 16
    total = bars * 4 * beat
    out = np.zeros(int(SR * (total + 1)))
    lrng = np.random.default_rng(100 + v)
    scale = SCALES[key]
    root = scale[0] - 24

    # drone (tanpura-ish): root + fifth
    t = t_axis(total)
    drone = (sine(NOTE(root), total) + 0.6 * sine(NOTE(root + 7), total)
             + 0.3 * sine(NOTE(root + 12), total)) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.25 * t) ** 2)
    place(out, lowpass(drone, 900) * 0.18, 0)

    # madal pattern (dha / ti / na) over 8 eighth-notes per bar
    pattern = [[1, 0, 2, 0, 1, 2, 0, 2], [1, 0, 2, 1, 0, 2, 2, 0],
               [1, 2, 0, 2, 1, 0, 2, 2], [1, 0, 0, 2, 1, 2, 0, 2], [1, 2, 2, 0, 1, 0, 2, 1]][v]
    for bar in range(bars):
        for i, hit in enumerate(pattern):
            at = (bar * 4 + i * 0.5) * beat
            if hit == 1:
                place(out, drum(95, 0.3, 0.45, 0.25) * 0.55, at)
            elif hit == 2:
                place(out, drum(320, 0.12, 0.9, 0.7) * 0.28, at)

    # melody: phrase of 4 bars repeated with variation
    def phrase(seed):
        prng = np.random.default_rng(seed)
        idx = 3
        notes = []
        for _ in range(8):  # 8 notes, each a half-beat to 1.5 beats
            idx = int(np.clip(idx + prng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(scale) - 1))
            notes.append((scale[idx], prng.choice([0.5, 0.5, 1.0, 1.0, 1.5, 2.0])))
        return notes

    a, b = phrase(v * 10 + 1), phrase(v * 10 + 2)
    form = [a, b, a, phrase(v * 10 + 3)]
    pos = 0.0
    for ph in form:
        start = pos
        for m, d in ph:
            dur = d * beat
            vv = voice if voice != "both" else ("flute" if lrng.random() < 0.5 else "pluck")
            if vv == "flute":
                s = bansuri(NOTE(m), dur * 1.05) * 0.35
            else:
                s = pluck(NOTE(m), dur + 0.4, 0.994) * 0.45
            place(out, s, pos)
            pos += dur
        # each phrase occupies 4 bars
        pos = start + 16 * beat
    out = out[: int(SR * total)]
    # gentle loop crossfade
    n = int(SR * 0.3)
    out[:n] *= np.linspace(0, 1, n)
    out[-n:] *= np.linspace(1, 0, n)
    return out


if __name__ == "__main__":
    jobs = {
        "dice": (dice, 6), "move": (move, 4), "kill": (kill, 10),
        "safe": (safe, 10), "six": (six, 6), "home": (home, 4),
        "win": (win, 6), "tap": (tap, 3), "reaction": (reaction, 4),
    }
    for name, (fn, count) in jobs.items():
        for i in range(count):
            save(f"{name}_{i + 1}", fn(i))
            print("ok", name, i + 1)
    for i in range(5):
        save(f"music_{i + 1}", music(i), peak=0.6, bitrate="64k")
        print("ok music", i + 1)
