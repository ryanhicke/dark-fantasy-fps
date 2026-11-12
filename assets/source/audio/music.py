"""Generates the looping music tracks under assets/audio/music/.

Four tracks: the menu, and one per act of the story (levels 1-3 outlaws,
4-6 crypt, 7-8 abyss). Consecutive levels share a track on purpose:
AudioManager keeps a track playing unbroken when the next level asks for
the same one.

Each track is written as notes on a beat grid and rendered into a buffer
that wraps around, so note tails and echoes that run past the end land at
the start and the loop has no seam.

Run from the project root:
    python assets/source/audio/music.py
AI-authored (Claude): see docs/placeholders.md.
"""

import math
import os
import random

from audio_tools import (
    SR, TAU, decay, drive, envelope, highpass, lowpass, noise, normalize,
    partials, tone, write_wav,
)

OUT_DIR = "assets/audio/music"
# Music sits under the sound effects even with both sliders at full.
PEAK = 0.5


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# --- Instruments: each returns the samples for one note --------------------

def pluck(freq, dur):
    """Lute-like: bright at the pick, the high harmonics dying first."""
    return partials(dur + 0.4, [(freq * k, 1.0 / k, 0.45 / k ** 0.8) for k in range(1, 7)])


def bell(freq, dur):
    return partials(dur + 1.5, [
        (freq, 1.0, 0.9), (freq * 2, 0.45, 0.6), (freq * 2.76, 0.3, 0.4), (freq * 5.4, 0.15, 0.2),
    ])


def _held(freq, dur, harmonics, attack, release, detune=0.0):
    total = dur + release
    parts = []
    for mult, amp in harmonics:
        parts.append((freq * mult * (1.0 + detune), amp, None))
        if detune:
            parts.append((freq * mult * (1.0 - detune), amp, None))
    shape = [(0, 0), (min(attack, dur) / total, 1), (dur / total, 1), (1, 0)]
    return envelope(partials(total, parts), shape)


def pad(freq, dur):
    """Slow, soft, slightly detuned: strings or a distant choir."""
    return _held(freq, dur, [(k, 1.0 / k ** 1.6) for k in range(1, 6)], 0.6, 0.9, 0.003)


def organ(freq, dur):
    return _held(freq, dur, [(1, 1.0), (2, 0.6), (3, 0.35), (4, 0.25), (6, 0.12), (8, 0.08)], 0.04, 0.2)


def bass(freq, dur):
    return drive(_held(freq, dur, [(k, 1.0 / k) for k in range(1, 6)], 0.01, 0.08), 1.5)


def lead(freq, dur):
    """A harsh reed for the abyss melody."""
    return drive(_held(freq, dur, [(k, 1.0 / k) for k in range(1, 9)], 0.03, 0.12, 0.002), 1.2)


def drum(rng, f_start=85.0, f_end=42.0, tau=0.16):
    skin = decay(tone(0.5, [(0, f_start), (1, f_end)]), tau)
    slap = decay(lowpass(noise(0.1, rng), 900), 0.02)
    return [a + 0.4 * b for a, b in zip(skin, slap + [0.0] * len(skin))]


def snare(rng):
    return decay(highpass(lowpass(noise(0.2, rng), 5000), 700), 0.05)


def hat(rng):
    return decay(highpass(noise(0.05, rng), 5000), 0.012)


# --- Track: a wrapping buffer on a beat grid -------------------------------

class Track:
    def __init__(self, bpm, beats):
        self.beat = 60.0 / bpm
        self.n = int(round(beats * self.beat * SR))
        self.beats = beats
        self.buf = [0.0] * self.n

    def add(self, at_beat, sound, level=1.0):
        start = int(at_beat * self.beat * SR)
        n, buf = self.n, self.buf
        for i, v in enumerate(sound):
            buf[(start + i) % n] += v * level

    def note(self, instrument, at_beat, midi, length, level=1.0):
        self.add(at_beat, instrument(hz(midi), length * self.beat), level)

    def chord(self, instrument, at_beat, midis, length, level=1.0):
        for midi in midis:
            self.note(instrument, at_beat, midi, length, level)

    def drone(self, midi, level, swells):
        """A held note for the whole loop. The frequency is nudged to a whole
        number of cycles per loop, and the swell too, so it wraps cleanly."""
        seconds = self.n / SR
        freq = round(hz(midi) * seconds) / seconds
        raw = partials(seconds, [(freq, 1.0, None), (freq * 2, 0.4, None), (freq * 3, 0.15, None)])
        for i in range(min(self.n, len(raw))):
            swell = 0.75 + 0.25 * math.sin(TAU * swells * i / self.n)
            self.buf[i] += raw[i] * swell * level

    def finish(self, echo_beats, echo_level):
        """Echo and a gentle top-end roll-off, both run twice around the loop
        so what comes out of the end feeds the beginning."""
        n = self.n
        dry = normalize(self.buf, 1.0)
        d = int(echo_beats * self.beat * SR)
        wet = list(dry)
        for _ in range(2):
            for i in range(n):
                wet[i] = dry[i] + wet[i - d] * 0.4  # negative index wraps
        out = [dry[i] + (wet[i] - dry[i]) * echo_level for i in range(n)]
        y = 0.0
        k = 1.0 - math.exp(-TAU * 6000.0 / SR)
        for lap in range(2):
            for i in range(n):
                y += k * (out[i] - y)
                if lap == 1:
                    out[i] = y
        return normalize(out, PEAK)


# --- The tracks ------------------------------------------------------------

def menu(rng):
    """D minor, slow: a drone, four long chords, and a lonely bell."""
    t = Track(60, 32)
    t.drone(38, 0.5, 4)
    t.drone(45, 0.3, 2)
    chords = [(50, 53, 57), (46, 50, 53), (43, 46, 50), (45, 49, 52)]
    for i, chord in enumerate(chords):
        t.chord(pad, i * 8, chord, 8, 0.22)
    melody = [
        (0, 74), (2, 77), (3, 76), (4, 74), (6, 69),
        (8, 70), (10, 74), (11, 72), (12, 70), (14, 65),
        (16, 67), (18, 70), (19, 69), (20, 67), (22, 62),
        (24, 64), (26, 69), (27, 67), (28, 64), (30, 61),
    ]
    for beat, midi in melody:
        t.note(bell, beat, midi, 1, 0.3)
    for beat in (0, 16):
        t.add(beat, drum(rng, 70, 38, 0.3), 0.6)
    return t.finish(0.75, 0.35)


def outlaws(rng):
    """E minor, a marching pulse with a lute tune: bandits on the road."""
    t = Track(104, 64)
    roots = [40, 40, 48, 50, 40, 40, 48, 47, 43, 50, 40, 48, 45, 47, 40, 40]
    minor = {40, 45}
    for bar, root in enumerate(roots):
        b = bar * 4
        third = 3 if root in minor else 4
        t.chord(pad, b, (root + 12, root + 12 + third, root + 19), 4, 0.12)
        for off, step in ((0, 0), (1, 0), (1.5, 7), (2, 0), (3, 12), (3.5, 7)):
            t.note(bass, b + off, root + step, 0.45, 0.3)
        for off in (0, 1.5, 2):
            t.add(b + off, drum(rng), 0.7)
        for off in (1, 3):
            t.add(b + off, snare(rng), 0.25)
        for half in range(8):
            t.add(b + half * 0.5, hat(rng), 0.12 if half % 2 else 0.06)
    tune = [
        [(0, 64), (1, 67), (1.5, 66), (2, 64), (3, 59)],
        [(0, 64), (1, 67), (2, 71), (3, 69), (3.5, 67)],
        [(0, 64), (1, 67), (1.5, 64), (2, 60), (3, 64)],
        [(0, 66), (1, 69), (2, 62), (3, 66), (3.5, 69)],
        [(0, 71), (1, 67), (1.5, 69), (2, 71), (3, 76)],
        [(0, 74), (0.5, 71), (1, 67), (2, 64), (3, 67)],
        [(0, 64), (1, 60), (2, 64), (2.5, 67), (3, 72)],
        [(0, 71), (1, 66), (2, 63), (3, 66)],
        [(0, 74), (1, 71), (1.5, 67), (2, 71), (3, 74)],
        [(0, 69), (1, 66), (2, 69), (3, 74), (3.5, 71)],
        [(0, 76), (1, 71), (1.5, 67), (2, 71), (3, 76)],
        [(0, 76), (0.5, 74), (1, 72), (2, 67), (3, 72)],
        [(0, 69), (1, 72), (1.5, 71), (2, 69), (3, 64)],
        [(0, 66), (1, 71), (2, 75), (3, 71), (3.5, 66)],
        [(0, 64), (1, 67), (1.5, 66), (2, 64), (3, 59)],
        [(0, 64), (2, 59), (3, 64)],
    ]
    for bar, notes in enumerate(tune):
        for off, midi in notes:
            t.note(pluck, bar * 4 + off, midi, 1, 0.4)
    return t.finish(0.75, 0.2)


def crypt(rng):
    """C minor with a flattened second: organ, tolling bells, a heartbeat."""
    t = Track(66, 48)
    t.drone(36, 0.45, 3)
    t.drone(43, 0.2, 6)
    chords = [(48, 51, 55), (49, 53, 56), (48, 51, 55), (46, 49, 53), (44, 48, 51), (43, 47, 50)]
    for i, chord in enumerate(chords):
        t.chord(organ, i * 8, chord, 7.8, 0.1)
    melody = [
        (0, 72), (1.5, 75), (3, 79), (4, 77), (6, 75), (7, 74),
        (8, 73), (9.5, 77), (11, 80), (12, 77), (14, 73),
        (16, 72), (17.5, 79), (19, 84), (20, 82), (22, 79), (23, 77),
        (24, 77), (25.5, 73), (27, 70), (28, 73), (30, 77),
        (32, 75), (33.5, 72), (35, 68), (36, 72), (38, 75), (39, 77),
        (40, 74), (41.5, 71), (43, 67), (44, 71), (46, 74), (47, 71),
    ]
    for beat, midi in melody:
        t.note(bell, beat, midi, 1, 0.22)
    for beat in (0, 24):
        t.note(bell, beat, 48, 2, 0.5)
    for bar in range(12):
        t.add(bar * 4, drum(rng, 65, 40, 0.12), 0.6)
        t.add(bar * 4 + 0.5, drum(rng, 60, 38, 0.1), 0.4)
    return t.finish(1.0, 0.4)


def abyss(rng):
    """D phrygian, fast and heavy: war drums, a grinding bass, a harsh reed."""
    t = Track(126, 64)
    roots = [38, 38, 39, 38, 38, 38, 41, 39, 38, 38, 39, 38, 34, 36, 38, 38]
    for bar, root in enumerate(roots):
        b = bar * 4
        for i, step in enumerate((0, 0, 12, 0, 0, 12, 7, 12)):
            t.note(bass, b + i * 0.5, root + step, 0.4, 0.3)
        for off in (0, 2.5):
            t.chord(organ, b + off, (root + 12, root + 19, root + 24), 0.9, 0.09)
        fill = bar % 8 == 7
        for off in ((0, 0.75, 2, 2.5, 3, 3.5) if fill else (0, 0.75, 2, 2.5)):
            t.add(b + off, drum(rng, 95, 40, 0.14), 0.8)
        for off in (1, 3):
            t.add(b + off, snare(rng), 0.35)
        for q in range(16):
            t.add(b + q * 0.25, hat(rng), 0.1 if q % 4 == 2 else 0.05)
    for i in range(8):
        t.chord(pad, i * 8, (50, 57), 8, 0.1)
    phrase = [
        (0, 62, 1.5), (1.5, 63, 0.5), (2, 62, 1), (3, 60, 1),
        (4, 62, 2), (6, 65, 1), (7, 63, 1),
        (8, 63, 1.5), (9.5, 65, 0.5), (10, 67, 1), (11, 63, 1),
        (12, 62, 3), (15, 57, 1),
    ]
    answer = [
        (16, 69, 1.5), (17.5, 70, 0.5), (18, 69, 1), (19, 67, 1),
        (20, 65, 2), (22, 67, 1), (23, 69, 1),
        (24, 72, 1.5), (25.5, 70, 0.5), (26, 69, 1), (27, 65, 1),
        (28, 67, 1), (29, 65, 1), (30, 63, 1), (31, 62, 1),
    ]
    ending = [
        (48, 70, 2), (50, 69, 1), (51, 65, 1),
        (52, 72, 2), (54, 70, 1), (55, 67, 1),
        (56, 74, 3), (59, 72, 1),
        (60, 74, 4),
    ]
    raised = [(beat + 32, midi + 12, length) for beat, midi, length in phrase]
    for beat, midi, length in phrase + answer + raised + ending:
        t.note(lead, beat, midi, length * 0.9, 0.16)
    return t.finish(0.75, 0.2)


TRACKS = {"menu": menu, "outlaws": outlaws, "crypt": crypt, "abyss": abyss}


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, make in TRACKS.items():
        samples_out = make(random.Random(name))
        write_wav(os.path.join(OUT_DIR, name + ".wav"), samples_out, loop=True)
        print("%-10s %5.1f s" % (name, len(samples_out) / SR))
