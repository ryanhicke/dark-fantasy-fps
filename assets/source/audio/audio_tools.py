"""Tiny pure-Python synthesis toolkit shared by sounds.py and music.py.

No dependencies (the standard library only), so the sounds can be rebuilt
on any machine with Python 3. Everything is a plain list of floats in
-1..1 at SR samples per second, mono.

AI-authored (Claude): see docs/placeholders.md.
"""

import math
import struct
from array import array

# 22.05 kHz mono keeps the files small and suits the low-fi look.
SR = 22050
TAU = 2.0 * math.pi


def samples(seconds):
    return max(1, int(seconds * SR))


def curve(value, n):
    """A per-sample list from a constant or [(time 0..1, value), ...]."""
    if not isinstance(value, (list, tuple)):
        return [float(value)] * n
    out = [0.0] * n
    points = list(value)
    for (t0, v0), (t1, v1) in zip(points, points[1:]):
        i0, i1 = int(t0 * n), int(t1 * n)
        span = max(1, i1 - i0)
        for i in range(i0, min(i1, n)):
            out[i] = v0 + (v1 - v0) * (i - i0) / span
    last = int(points[-1][0] * n)
    for i in range(last, n):
        out[i] = points[-1][1]
    return out


def tone(dur, freq, shape="sine", vibrato=0.0, vib_rate=6.0):
    """An oscillator. freq is a constant or a curve() point list."""
    n = samples(dur)
    freqs = curve(freq, n)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        f = freqs[i]
        if vibrato:
            f *= 1.0 + vibrato * math.sin(TAU * vib_rate * i / SR)
        phase = (phase + f / SR) % 1.0
        if shape == "sine":
            out[i] = math.sin(TAU * phase)
        elif shape == "saw":
            out[i] = 2.0 * phase - 1.0
        elif shape == "square":
            out[i] = 1.0 if phase < 0.5 else -1.0
        else:  # triangle
            out[i] = 4.0 * abs(phase - 0.5) - 1.0
    return out


def noise(dur, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(samples(dur))]


def partials(dur, parts, rng=None):
    """Sum of sines, each (freq, amp, decay seconds or None for steady).

    Uses a two-multiply resonator instead of sin() per sample, which is
    what makes the music renderable in pure Python.
    """
    n = samples(dur)
    out = [0.0] * n
    for freq, amp, tau in parts:
        if freq >= SR * 0.48:
            continue
        w = TAU * freq / SR
        phase = rng.uniform(0.0, TAU) if rng else 0.0
        c = 2.0 * math.cos(w)
        s1 = math.sin(phase - w)
        s2 = math.sin(phase - 2.0 * w)
        d = math.exp(-1.0 / (tau * SR)) if tau else 1.0
        a = amp
        for i in range(n):
            s = c * s1 - s2
            s2 = s1
            s1 = s
            out[i] += s * a
            a *= d
    return out


def lowpass(buf, cutoff):
    """One-pole low-pass. cutoff is a constant or a curve() point list."""
    n = len(buf)
    cuts = curve(cutoff, n)
    out = [0.0] * n
    y = 0.0
    k = 0.0
    for i in range(n):
        if i % 16 == 0:
            k = 1.0 - math.exp(-TAU * cuts[i] / SR)
        y += k * (buf[i] - y)
        out[i] = y
    return out


def highpass(buf, cutoff):
    low = lowpass(buf, cutoff)
    return [a - b for a, b in zip(buf, low)]


def bandpass(buf, freq, q):
    """Biquad band-pass with 0 dB peak gain. freq may be a point list."""
    n = len(buf)
    freqs = curve(freq, n)
    out = [0.0] * n
    x1 = x2 = y1 = y2 = 0.0
    b0 = a1 = a2 = 0.0
    for i in range(n):
        if i % 16 == 0:
            w = TAU * min(freqs[i], SR * 0.45) / SR
            alpha = math.sin(w) / (2.0 * q)
            a0 = 1.0 + alpha
            b0 = alpha / a0
            a1 = -2.0 * math.cos(w) / a0
            a2 = (1.0 - alpha) / a0
        x = buf[i]
        y = b0 * (x - x2) - a1 * y1 - a2 * y2
        x2, x1 = x1, x
        y2, y1 = y1, y
        out[i] = y
    return out


def envelope(buf, points):
    """Multiplies by a piecewise-linear envelope [(time 0..1, level), ...]."""
    env = curve(points, len(buf))
    return [a * b for a, b in zip(buf, env)]


def decay(buf, tau, attack=0.002):
    """Exponential decay with a short linear attack (seconds)."""
    rise = max(1, int(attack * SR))
    d = math.exp(-1.0 / (tau * SR))
    out = [0.0] * len(buf)
    a = 1.0
    for i, v in enumerate(buf):
        out[i] = v * a * (i / rise if i < rise else 1.0)
        a *= d
    return out


def fade(buf, fade_in=0.002, fade_out=0.01):
    """Short ramps at both ends so a sound never starts or ends on a click."""
    out = list(buf)
    n = len(out)
    a = min(n // 2, int(fade_in * SR))
    b = min(n // 2, int(fade_out * SR))
    for i in range(a):
        out[i] *= i / a
    for i in range(b):
        out[n - 1 - i] *= i / b
    return out


def gain(buf, amount):
    return [v * amount for v in buf]


def mix(*layers):
    """Sums (buf, gain, offset seconds) layers into one buffer."""
    length = max(int(offset * SR) + len(buf) for buf, _g, offset in layers)
    out = [0.0] * length
    for buf, amount, offset in layers:
        start = int(offset * SR)
        for i, v in enumerate(buf):
            out[start + i] += v * amount
    return out


def drive(buf, amount):
    """Soft clipping, for growls and blasts."""
    return [math.tanh(v * amount) for v in buf]


def normalize(buf, peak=0.9):
    top = max(max(buf), -min(buf), 1e-9)
    scale = peak / top
    return [v * scale for v in buf]


def reverb(buf, amount=0.3, tail=0.6, size=1.0):
    """A cheap hall: four damped feedback combs added to the dry sound."""
    n = len(buf) + samples(tail)
    dry = list(buf) + [0.0] * (n - len(buf))
    wet = [0.0] * n
    for delay_s in (0.0297, 0.0371, 0.0411, 0.0437):
        d = int(delay_s * size * SR)
        line = [0.0] * n
        damp = 0.0
        for i in range(n):
            echo = line[i - d] if i >= d else 0.0
            damp += 0.45 * (echo - damp)
            line[i] = dry[i] + damp * 0.78
            wet[i] += line[i - d] if i >= d else 0.0
    return fade([dry[i] + wet[i] * amount * 0.25 for i in range(n)], 0.0, tail * 0.5)


def loopable(buf, overlap):
    """Crossfades the tail into the head so the result loops seamlessly.

    The result is shorter than buf by the overlap (seconds).
    """
    x = int(overlap * SR)
    n = len(buf) - x
    out = buf[:n]
    for i in range(x):
        t = i / x
        # Equal-power, since the two ends of a noise bed are uncorrelated.
        out[i] = buf[i] * math.sqrt(t) + buf[n + i] * math.sqrt(1.0 - t)
    return out


def write_wav(path, buf, loop=False):
    """16-bit mono WAV. loop adds a 'smpl' chunk marking the whole file as a
    forward loop, which Godot's importer picks up (Loop Mode: Detect From
    WAV), so no import settings need changing by hand."""
    pcm = array("h", (int(max(-1.0, min(1.0, v)) * 32767) for v in buf))
    data = pcm.tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(data)) + data
    if loop:
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, len(buf) - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    with open(path, "wb") as handle:
        handle.write(b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks)


def save_all(table, folder):
    """Renders {name: (function(rng), peak[, loop])} into folder/name.wav.

    Each sound gets its own generator seeded from its name, so one sound
    can be retuned without changing any of the others.
    """
    import os
    import random
    import zlib

    os.makedirs(folder, exist_ok=True)
    for name, entry in table.items():
        func, peak = entry[0], entry[1]
        loop = len(entry) > 2 and entry[2]
        buf = normalize(func(random.Random(zlib.crc32(name.encode()))), peak)
        if not loop:
            buf = fade(buf)
        write_wav(os.path.join(folder, name + ".wav"), buf, loop)
        print("%-28s %5.2f s" % (name, len(buf) / SR))
