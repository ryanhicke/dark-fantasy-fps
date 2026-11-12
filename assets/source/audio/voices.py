"""Generates the enemy voices: alert, attack, pain, and death per enemy.

Voices are a buzzing source (the throat) pushed through three resonances
(the mouth), the classic formant trick. Pitch, mouth size, and roughness
are what tell a bandit from a demon from an imp. One WAV each under
assets/audio/sfx/.

Run from the project root:
    python assets/source/audio/voices.py
AI-authored (Claude): see docs/placeholders.md.
"""

import math

from audio_tools import (
    SR, TAU, bandpass, curve, drive, envelope, lowpass, mix, noise,
    normalize, reverb, save_all, tone,
)
from sounds import clang, creak, rattle, thud, whoosh

OUT_DIR = "assets/audio/sfx"

# Vowel formants: (frequency, sharpness, level) for an adult male mouth.
AH = ((730, 8, 1.0), (1090, 9, 0.5), (2440, 10, 0.25))
EH = ((530, 8, 1.0), (1840, 10, 0.4), (2480, 10, 0.25))
EE = ((270, 8, 1.0), (2290, 12, 0.35), (3010, 12, 0.2))
OH = ((570, 8, 1.0), (840, 9, 0.45), (2410, 10, 0.15))
OO = ((300, 8, 1.0), (870, 9, 0.35), (2240, 10, 0.1))

SHOUT = [(0, 0), (0.06, 1), (0.7, 0.8), (1, 0)]
GRUNT = [(0, 0), (0.05, 1), (0.4, 0.6), (1, 0)]


def voice(rng, dur, pitch, vowel, vowel_end=None, size=1.0, voiced=1.0,
          breath=0.1, rough=0.0, rough_rate=40.0, shape=SHOUT):
    """One utterance.

    pitch: Hz, constant or curve points. vowel -> vowel_end glides the mouth.
    size: under 1 is a bigger creature (lower resonances), over 1 smaller.
    voiced / breath: throat buzz versus air; a whisper is mostly breath.
    rough: 0 clean to 1 growling, at rough_rate flutters per second.
    """
    n = max(1, int(dur * SR))
    pitches = curve(pitch, n)
    src = [0.0] * n
    phase = 0.0
    growl = 0.0
    drift = 0.0
    for i in range(n):
        # A slow random drift keeps the pitch from sounding machine-steady.
        drift = drift * 0.995 + rng.uniform(-1.0, 1.0) * 0.1
        phase = (phase + pitches[i] * (1.0 + 0.03 * drift) / SR) % 1.0
        growl += TAU * rough_rate * (1.0 + 0.4 * drift) / SR
        amp = 1.0 - rough * (0.5 + 0.5 * math.sin(growl))
        src[i] = (2.0 * phase - 1.0) * voiced * amp + rng.uniform(-1.0, 1.0) * breath

    def mouth(formants):
        bands = [(bandpass(src, f * size, q), level, 0.0) for f, q, level in formants]
        return mix(*bands)

    out = mouth(vowel)
    if vowel_end is not None:
        other = mouth(vowel_end)
        out = [a + (b - a) * i / n for i, (a, b) in enumerate(zip(out, other))]
    # Full scale, so the levels given when layering voices mean something.
    return normalize(envelope(out, shape), 1.0)


def bursts(rng, count, gap, make):
    """Several short utterances in a row (a laugh or cackle)."""
    return mix(*[(make(i), 1.0 - 0.1 * i, i * gap) for i in range(count)])


def armor_clank(rng, at):
    return mix((clang(rng, 0.3, 820, 0.05), 1.0, at), (clang(rng, 0.25, 1100, 0.04), 0.7, at + 0.08))


# --- Humans: bandit, archer, mercenary share a voice at different pitches --

def human(pitch, size, armored=False):
    def alert(rng):  # "Hey!"
        v = voice(rng, 0.38, [(0, pitch * 1.1), (0.3, pitch * 1.45), (1, pitch * 1.15)],
                  EH, EE, size, breath=0.08, rough=0.15)
        return mix((v, 1.0, 0.0), (armor_clank(rng, 0.05), 0.25, 0.0)) if armored else v

    def attack(rng):  # "Hah!"
        return voice(rng, 0.22, [(0, pitch * 1.3), (1, pitch * 0.95)], AH, None, size,
                     breath=0.25, rough=0.3, shape=GRUNT)

    def pain(rng):  # "Ugh!"
        v = voice(rng, 0.3, [(0, pitch * 1.4), (1, pitch * 0.85)], OH, OO, size,
                  breath=0.15, rough=0.35, shape=GRUNT)
        return mix((v, 1.0, 0.0), (armor_clank(rng, 0.0), 0.3, 0.0)) if armored else v

    def death(rng):  # "Aaargh..."
        v = voice(rng, 0.95, [(0, pitch * 1.5), (0.2, pitch * 1.6), (1, pitch * 0.7)],
                  AH, OH, size, breath=0.2, rough=0.5, shape=[(0, 0), (0.05, 1), (0.5, 0.8), (1, 0)])
        fall = mix((thud(0.3, 90, 45, 0.07), 0.6, 0.85))
        if armored:
            fall = mix((fall, 1.0, 0.0), (armor_clank(rng, 0.85), 0.5, 0.0))
        return mix((v, 1.0, 0.0), (fall, 1.0, 0.0))

    return alert, attack, pain, death


BANDIT = human(125, 1.0)
ARCHER = human(152, 1.08)
MERCENARY = human(96, 0.9, armored=True)


def archer_attack(rng):
    return creak(rng, 0.45)


# --- Skeleton: no throat, only bones ---------------------------------------

def skeleton_alert(rng):
    hollow = envelope(bandpass(noise(0.6, rng), 450, 6.0), [(0, 0), (0.3, 1), (1, 0)])
    bones = rattle(rng, [i * 0.055 + rng.uniform(0, 0.02) for i in range(10)], 900, 2200)
    return mix((bones, 1.0, 0.0), (hollow, 0.5, 0.0))


def skeleton_attack(rng):
    bones = rattle(rng, [0.0, 0.05, 0.11, 0.16], 900, 2000)
    return mix((bones, 1.0, 0.0), (whoosh(rng, 0.25, 600, 2000, 900), 0.5, 0.05))


def skeleton_pain(rng):
    return rattle(rng, [0.0, 0.04, 0.1], 1200, 2400, 0.015)


def skeleton_death(rng):
    times = sorted(rng.uniform(0.0, 0.9) for _ in range(18))
    falling = mix(*[
        (rattle(rng, [0.0], 2200 - t * 1400, 2400 - t * 1400), 1.0, t) for t in times
    ])
    return mix((falling, 1.0, 0.0), (thud(0.3, 110, 60, 0.06), 0.7, 0.85))


# --- Apprentice wizard: a whispering, faceless thing -----------------------

def wizard_alert(rng):
    return voice(rng, 0.6, [(0, 180), (1, 160)], EE, AH, voiced=0.25, breath=1.0)


def wizard_attack(rng):  # a two-note chant
    chant = voice(rng, 0.5, [(0, 110), (0.45, 110), (0.5, 147), (1, 147)], OH, AH, breath=0.1, rough=0.1)
    return reverb(chant, 0.4, 0.3)


def wizard_pain(rng):
    return voice(rng, 0.3, [(0, 260), (1, 180)], EH, voiced=0.4, breath=0.9, shape=GRUNT)


def wizard_death(rng):
    wail = voice(rng, 1.1, [(0, 330), (0.3, 300), (1, 110)], AH, OO, voiced=0.8, breath=0.5, rough=0.2)
    return reverb(wail, 0.4, 0.5)


# --- Melee demon -----------------------------------------------------------

def demon_alert(rng):
    roar = voice(rng, 0.8, [(0, 60), (0.3, 95), (1, 65)], AH, OH, 0.75, breath=0.3, rough=0.8, rough_rate=28)
    return drive(normalize(roar, 1.0), 3.0)


def demon_attack(rng):
    return voice(rng, 0.3, [(0, 90), (1, 130)], EH, None, 0.75, breath=0.4, rough=0.9, rough_rate=45, shape=GRUNT)


def demon_pain(rng):
    return voice(rng, 0.3, [(0, 140), (1, 80)], AH, None, 0.75, breath=0.2, rough=0.7, rough_rate=30, shape=GRUNT)


def demon_death(rng):
    fall = voice(rng, 1.2, [(0, 110), (0.2, 120), (1, 40)], AH, OO, 0.75, breath=0.3, rough=0.9, rough_rate=24)
    return drive(normalize(fall, 1.0), 3.0)


# --- Imp: small and shrill -------------------------------------------------

def imp_alert(rng):  # a cackle
    return bursts(rng, 5, 0.1, lambda i: voice(
        rng, 0.07, [(0, 620 - i * 30), (1, 520 - i * 30)], EH, None, 1.5, rough=0.2, shape=GRUNT))


def imp_attack(rng):
    squeak = voice(rng, 0.18, [(0, 500), (1, 750)], EE, None, 1.5, shape=GRUNT)
    chirp = envelope(tone(0.15, [(0, 1200), (1, 2400)]), [(0, 0), (0.2, 1), (1, 0)])
    return mix((squeak, 1.0, 0.0), (chirp, 0.08, 0.08))


def imp_pain(rng):
    return voice(rng, 0.25, [(0, 800), (1, 520)], EH, None, 1.5, rough=0.3, shape=GRUNT)


def imp_death(rng):
    return voice(rng, 0.8, [(0, 760), (0.3, 820), (1, 240)], AH, OO, 1.5, rough=0.4)


# --- Necromancer: a deep voice in a big stone room -------------------------

def necromancer_alert(rng):  # a slow laugh
    laugh = bursts(rng, 5, 0.19, lambda i: voice(
        rng, 0.13, [(0, 108 - i * 5), (1, 88 - i * 5)], AH, OH, 0.92, rough=0.3, shape=GRUNT))
    return reverb(laugh, 0.5, 0.7, 1.4)


def necromancer_attack(rng):
    chant = voice(rng, 0.6, [(0, 82), (0.5, 82), (0.55, 98), (1, 73)], OO, OH, 0.92, rough=0.2)
    return reverb(chant, 0.5, 0.5, 1.4)


def necromancer_pain(rng):
    return reverb(voice(rng, 0.4, [(0, 120), (1, 75)], OH, OO, 0.92, rough=0.5, shape=GRUNT), 0.4, 0.4, 1.4)


def necromancer_death(rng):
    cry = voice(rng, 1.6, [(0, 150), (0.15, 175), (1, 55)], AH, OH, 0.92, breath=0.3, rough=0.6)
    return reverb(cry, 0.6, 1.0, 1.4)


# --- Werewolf --------------------------------------------------------------

def werewolf_howl(rng):
    howl = voice(rng, 1.5, [(0, 260), (0.2, 470), (0.7, 500), (1, 330)], OH, OO,
                 breath=0.1, rough=0.08, shape=[(0, 0), (0.12, 1), (0.75, 0.9), (1, 0)])
    return reverb(howl, 0.4, 0.6)


def werewolf_growl(rng):
    """The wake-up sound of a werewolf still in human shape: the only
    warning the player gets, so it must not sound like a human "Hey!"."""
    growl = voice(rng, 0.7, [(0, 75), (0.5, 90), (1, 70)], OH, None, 0.8, breath=0.35, rough=0.9, rough_rate=32)
    return drive(normalize(growl, 1.0), 3.0)


def werewolf_attack(rng):
    return voice(rng, 0.3, [(0, 110), (1, 170)], AH, EH, 0.85, breath=0.5, rough=0.9, rough_rate=50, shape=GRUNT)


def werewolf_pain(rng):  # a yelp
    return voice(rng, 0.22, [(0, 520), (0.3, 640), (1, 330)], EH, None, rough=0.2, shape=GRUNT)


def werewolf_death(rng):
    return voice(rng, 1.0, [(0, 300), (0.3, 240), (1, 80)], OH, OO, 0.9, breath=0.3, rough=0.6)


# --- Great demon: as big as the voice trick will go ------------------------

def _great_voice(rng, dur, pitch, vowel, vowel_end=None, shape=SHOUT):
    throat = voice(rng, dur, pitch, vowel, vowel_end, 0.55, breath=0.5, rough=0.85, rough_rate=22, shape=shape)
    rumble = envelope(lowpass(noise(dur, rng), 120), shape)
    return drive(mix((normalize(throat, 1.0), 3.0, 0.0), (normalize(rumble, 1.0), 0.8, 0.0)), 1.0)


def great_demon_alert(rng):
    return reverb(_great_voice(rng, 2.0, [(0, 45), (0.25, 75), (0.7, 65), (1, 38)], AH, OH), 0.6, 1.2, 1.6)


def great_demon_roar(rng):
    """Rage as an obelisk breaks: higher and longer than the alert."""
    return reverb(_great_voice(rng, 2.4, [(0, 55), (0.2, 95), (0.6, 85), (1, 40)], AH, AH), 0.6, 1.2, 1.6)


def great_demon_attack(rng):
    inhale = envelope(lowpass(noise(0.8, rng), [(0, 300), (1, 3500)]), [(0, 0), (0.9, 1), (1, 0)])
    growl = _great_voice(rng, 0.8, [(0, 50), (1, 85)], OH, None, [(0, 0), (0.8, 1), (1, 0)])
    return mix((inhale, 0.5, 0.0), (growl, 1.0, 0.0))


def great_demon_pain(rng):
    return reverb(_great_voice(rng, 0.5, [(0, 80), (1, 45)], AH, None, GRUNT), 0.4, 0.6, 1.6)


def great_demon_death(rng):
    cry = _great_voice(rng, 2.8, [(0, 80), (0.15, 90), (1, 25)], AH, OO, [(0, 0), (0.04, 1), (0.6, 0.8), (1, 0)])
    # Crumbling to rubble: stones fall faster and faster, then the ground hit.
    stones = rattle(rng, sorted(1.0 + 1.8 * math.sqrt(rng.random()) for _ in range(40)), 100, 400, 0.03)
    whole = mix((cry, 1.0, 0.0), (stones, 0.6, 0.0), (thud(1.0, 70, 25, 0.3), 1.0, 2.3))
    return reverb(whole, 0.6, 1.2, 1.6)


SOUNDS = {
    "werewolf_growl": (werewolf_growl, 0.75),
    "werewolf_alert": (werewolf_howl, 0.8),
    "werewolf_attack": (werewolf_attack, 0.75),
    "werewolf_pain": (werewolf_pain, 0.7),
    "werewolf_death": (werewolf_death, 0.75),
    "archer_attack": (archer_attack, 0.5),
    "great_demon_alert": (great_demon_alert, 0.95),
    "great_demon_roar": (great_demon_roar, 0.95),
    "great_demon_attack": (great_demon_attack, 0.85),
    "great_demon_pain": (great_demon_pain, 0.85),
    "great_demon_death": (great_demon_death, 0.95),
}

_SETS = {
    "bandit": BANDIT,
    "archer": (ARCHER[0], None, ARCHER[2], ARCHER[3]),
    "mercenary": MERCENARY,
    "skeleton": (skeleton_alert, skeleton_attack, skeleton_pain, skeleton_death),
    "wizard": (wizard_alert, wizard_attack, wizard_pain, wizard_death),
    "demon": (demon_alert, demon_attack, demon_pain, demon_death),
    "imp": (imp_alert, imp_attack, imp_pain, imp_death),
    "necromancer": (necromancer_alert, necromancer_attack, necromancer_pain, necromancer_death),
}
for _name, _set in _SETS.items():
    for _kind, _func in zip(("alert", "attack", "pain", "death"), _set):
        if _func is not None:
            SOUNDS["%s_%s" % (_name, _kind)] = (_func, 0.7 if _kind == "attack" else 0.8)


if __name__ == "__main__":
    save_all(SOUNDS, OUT_DIR)
