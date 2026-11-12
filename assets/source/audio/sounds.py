"""Generates the weapon, spell, world, pickup, and menu sound effects.

Every sound is synthesized (no samples), one WAV each under
assets/audio/sfx/. Enemy voices are in voices.py, music in music.py.

Run from the project root:
    python assets/source/audio/sounds.py
AI-authored (Claude): see docs/placeholders.md.
"""

import math

from audio_tools import (
    SR, TAU, bandpass, decay, drive, envelope, highpass, loopable,
    lowpass, mix, noise, normalize, partials, reverb, save_all, tone,
)

OUT_DIR = "assets/audio/sfx"


# --- Building blocks -------------------------------------------------------

def whoosh(rng, dur, f_start, f_peak, f_end, q=1.5):
    """Air moving past: band-passed noise whose pitch rises and falls."""
    swept = bandpass(noise(dur, rng), [(0, f_start), (0.45, f_peak), (1, f_end)], q)
    return envelope(swept, [(0, 0), (0.4, 1), (1, 0)])


def thud(dur, f_start, f_end, tau):
    """A dull body hit: a sine dropping in pitch."""
    return decay(tone(dur, [(0, f_start), (1, f_end)]), tau)


def burst(rng, dur, cutoff, tau):
    return decay(lowpass(noise(dur, rng), cutoff), tau)


def knock(rng, freq, tau=0.012):
    """One short woody or bony click."""
    body = decay(tone(0.07, [(0, freq), (1, freq * 0.7)], "tri"), tau)
    return mix((body, 1.0, 0.0), (decay(noise(0.01, rng), 0.002), 0.3, 0.0))


def rattle(rng, times, f_low, f_high, tau=0.012):
    """Several knocks at the given times (seconds), random in pitch."""
    return mix(*[
        (knock(rng, rng.uniform(f_low, f_high), tau), rng.uniform(0.6, 1.0), t)
        for t in times
    ])


def bell(freq, dur=0.7, tau=0.25):
    return partials(dur, [(freq, 1.0, tau), (freq * 2, 0.3, tau * 0.6), (freq * 3.01, 0.12, tau * 0.4)])


def clang(rng, dur, base, tau):
    """Struck metal: inharmonic partials, the high ones dying first."""
    ratios = (1.0, 1.59, 2.32, 3.19, 4.02)
    parts = [(base * r, 1.0 / (i + 1), tau / (1 + i * 0.4)) for i, r in enumerate(ratios)]
    click = decay(highpass(noise(0.05, rng), 2000), 0.008)
    return mix((partials(dur, parts, rng), 1.0, 0.0), (click, 0.8, 0.0))


def flutter(rng, buf, rate, depth):
    """Irregular amplitude wobble (fire, grinding stone)."""
    lfo = normalize(lowpass(noise(len(buf) / SR, rng), rate), 1.0)
    return [v * (1.0 - depth + depth * abs(l)) for v, l in zip(buf, lfo)]


def crackle(rng, dur, density):
    """Sparse sharp impulses, thinning out: sparks and electricity."""
    n = int(dur * SR)
    out = [0.0] * n
    for i in range(n):
        if rng.random() < density * (1.0 - i / n) ** 2:
            out[i] = rng.uniform(-1.0, 1.0)
    return lowpass(out, 6000)


def creak(rng, dur):
    """A bow being drawn: a slow pulse train through a woody resonance."""
    src = tone(dur, [(0, 48), (1, 92)], "saw")
    wood = bandpass(src, [(0, 700), (1, 1300)], 4.0)
    return envelope(flutter(rng, wood, 30, 0.5), [(0, 0), (0.08, 0.6), (0.9, 1), (1, 0)])


def grind(rng, dur):
    """Heavy stone or timber dragging."""
    bed = bandpass(lowpass(noise(dur, rng), 500), 220, 1.0)
    return envelope(flutter(rng, bed, 35, 0.6), [(0, 0), (0.1, 1), (0.85, 0.9), (1, 0)])


# --- Weapons ---------------------------------------------------------------

def sword_swing(rng):
    return whoosh(rng, 0.28, 500, 2600, 900)


def sword_hit(rng):
    return mix(
        (thud(0.25, 180, 60, 0.05), 1.0, 0.0),
        (burst(rng, 0.2, 1800, 0.04), 0.8, 0.0),
        (whoosh(rng, 0.1, 2000, 3000, 1500), 0.2, 0.0),
    )


def sword_wall(rng):
    return clang(rng, 0.6, 1450, 0.12)


def hammer_swing(rng):
    return whoosh(rng, 0.42, 200, 1100, 350, 1.2)


def hammer_hit(rng):
    hit = mix(
        (thud(0.4, 120, 40, 0.09), 1.0, 0.0),
        (burst(rng, 0.3, 900, 0.06), 0.9, 0.0),
        (decay(bandpass(noise(0.15, rng), 1500, 1.0), 0.03), 0.3, 0.0),
    )
    return drive(hit, 1.8)


def hammer_wall(rng):
    rubble = rattle(rng, [rng.uniform(0.05, 0.45) for _ in range(8)], 200, 600, 0.02)
    return mix(
        (thud(0.4, 140, 50, 0.07), 1.0, 0.0),
        (partials(0.4, [(420, 0.6, 0.1), (790, 0.4, 0.07), (1130, 0.3, 0.05)]), 0.7, 0.0),
        (rubble, 0.3, 0.0),
    )


def bow_draw(rng):
    return creak(rng, 1.5)


def bow_release(rng):
    string = decay(tone(0.35, [(0, 220), (0.15, 160), (1, 150)], "tri"), 0.08)
    return mix(
        (string, 1.0, 0.0),
        (partials(0.2, [(310, 0.5, 0.05), (620, 0.3, 0.03)]), 0.6, 0.0),
        (whoosh(rng, 0.15, 1500, 3500, 2000), 0.35, 0.0),
    )


def axe_throw(rng):
    spin = whoosh(rng, 0.45, 300, 1500, 600)
    # The tumbling blade beats the air about 14 times a second.
    return [v * (0.55 + 0.45 * math.sin(TAU * 14 * i / SR)) for i, v in enumerate(spin)]


def arrow_impact(rng):
    shaft = decay(tone(0.3, [(0, 95), (1, 85)], "tri"), 0.08)
    quiver = [v * (0.5 + 0.5 * math.sin(TAU * 30 * i / SR)) for i, v in enumerate(shaft)]
    return mix(
        (knock(rng, 260, 0.03), 1.0, 0.0),
        (decay(highpass(noise(0.03, rng), 2000), 0.006), 0.5, 0.0),
        (quiver, 0.4, 0.0),
    )


def axe_impact(rng):
    return mix(
        (thud(0.25, 170, 70, 0.05), 1.0, 0.0),
        (partials(0.3, [(900, 0.4, 0.05), (1700, 0.25, 0.04), (2900, 0.15, 0.03)]), 0.6, 0.0),
        (burst(rng, 0.05, 3000, 0.01), 0.4, 0.0),
    )


# --- Spells ----------------------------------------------------------------

def fireball_cast(rng):
    flare = lowpass(noise(0.55, rng), [(0, 400), (0.3, 3000), (1, 600)])
    return mix(
        (envelope(flare, [(0, 0), (0.15, 1), (1, 0)]), 1.0, 0.0),
        (thud(0.5, 220, 70, 0.18), 0.7, 0.0),
    )


def fireball_flight(rng):
    roar = bandpass(lowpass(noise(1.6, rng), 900), 350, 0.7)
    return loopable(flutter(rng, roar, 25, 0.5), 0.4)


def explosion(rng):
    body = decay(lowpass(noise(1.4, rng), [(0, 5000), (0.2, 1200), (1, 120)]), 0.35)
    blast = drive(mix((body, 1.0, 0.0), (thud(1.2, 95, 28, 0.3), 1.2, 0.0)), 2.0)
    return reverb(blast, 0.3, 0.4)


def missile_cast(rng):
    shape = [(0, 0), (0.1, 1), (1, 0)]
    low = envelope(tone(0.3, [(0, 500), (1, 1700)], "sine", 0.03, 30), shape)
    high = envelope(tone(0.3, [(0, 750), (1, 2550)], "sine", 0.03, 30), shape)
    sparkle = partials(0.3, [(2637, 0.3, 0.08), (3520, 0.2, 0.06)])
    return mix((low, 1.0, 0.0), (high, 0.4, 0.0), (sparkle, 0.5, 0.05))


def missile_impact(rng):
    return mix(
        (decay(tone(0.25, [(0, 1600), (1, 350)], "tri"), 0.06), 1.0, 0.0),
        (decay(highpass(noise(0.2, rng), 2500), 0.04), 0.5, 0.0),
        (partials(0.25, [(2093, 0.4, 0.07), (3136, 0.3, 0.05)]), 0.6, 0.0),
    )


def lightning_cast(rng):
    crack = decay(highpass(noise(0.5, rng), 1500), 0.05)
    bolt = mix(
        (crack, 1.0, 0.0),
        (bandpass(crackle(rng, 0.6, 0.05), 3000, 0.7), 1.5, 0.0),
        (burst(rng, 0.8, 200, 0.3), 1.2, 0.0),
        (decay(tone(0.5, [(0, 60), (1, 50)], "square"), 0.12), 0.3, 0.0),
    )
    return drive(bolt, 1.6)


def lightning_hit(rng):
    hum = tone(0.35, 110, "square")
    sizzle = bandpass([h * n for h, n in zip(hum, noise(0.35, rng))], 2500, 0.8)
    return mix((decay(sizzle, 0.1), 1.0, 0.0), (crackle(rng, 0.3, 0.04), 0.8, 0.0))


def lightning_wall(rng):
    return mix(
        (crackle(rng, 0.3, 0.03), 1.0, 0.0),
        (partials(0.1, [(3000, 0.3, 0.02)]), 0.5, 0.0),
    )


def heal_cast(rng):
    notes = (523.25, 659.25, 783.99, 1046.5)  # C major, rising
    layers = [(bell(f), 1.0, i * 0.1) for i, f in enumerate(notes)]
    shimmer = envelope(bandpass(noise(0.9, rng), 5000, 3.0), [(0, 0), (0.4, 1), (1, 0)])
    return reverb(mix(*layers, (shimmer, 0.08, 0.0)), 0.35, 0.5)


def armor_cast(rng):
    gong = partials(1.0, [
        (196, 1.0, 0.4), (294, 0.6, 0.35), (392.5, 0.5, 0.3),
        (588, 0.3, 0.2), (1245, 0.2, 0.12), (1870, 0.15, 0.1),
    ])
    rise = envelope(tone(0.5, [(0, 800), (1, 2400)]), [(0, 0), (0.5, 1), (1, 0)])
    return reverb(mix((gong, 1.0, 0.0), (rise, 0.15, 0.0)), 0.3, 0.5)


def armor_fading(rng):
    return mix(
        (partials(0.4, [(587.3, 1.0, 0.12), (1174.7, 0.2, 0.08)]), 1.0, 0.0),
        (partials(0.5, [(440.0, 1.0, 0.15), (880.0, 0.2, 0.1)]), 1.0, 0.18),
    )


# --- Pickups ---------------------------------------------------------------

def weapon_pickup(rng):
    shing = partials(0.5, [(2100, 0.6, 0.15), (3170, 0.5, 0.12), (4410, 0.3, 0.1)])
    return mix(
        (thud(0.15, 150, 90, 0.04), 0.8, 0.0),
        (shing, 1.0, 0.02),
        (whoosh(rng, 0.2, 2000, 5000, 4000, 2.0), 0.3, 0.0),
    )


def ammo_pickup(rng):
    return mix(
        (rattle(rng, [0.0, 0.06, 0.11], 500, 900), 1.0, 0.0),
        (thud(0.1, 140, 100, 0.03), 0.6, 0.0),
    )


def health_pickup(rng):
    blips = [
        (envelope(tone(0.07, [(0, 380 + i * 120), (1, 760 + i * 160)]), [(0, 0), (0.3, 1), (1, 0)]), 1.0, i * 0.09)
        for i in range(3)
    ]
    return mix(*blips, (bell(880, 0.5, 0.2), 0.4, 0.22))


def key_pickup(rng):
    pings = [
        (partials(0.35, [(f, 1.0, 0.1), (f * 1.5, 0.4, 0.07)]), 1.0, t)
        for f, t in ((3100, 0.0), (3700, 0.07), (4300, 0.15))
    ]
    return mix(*pings)


# --- Doors, levers, exits --------------------------------------------------

def door_open(rng):
    return mix((thud(0.15, 110, 60, 0.04), 1.0, 0.0), (grind(rng, 1.1), 1.4, 0.05))


def door_close(rng):
    slam = mix((thud(0.35, 90, 40, 0.08), 1.0, 0.0), (burst(rng, 0.2, 700, 0.04), 0.6, 0.0))
    return mix((grind(rng, 0.7), 1.2, 0.0), (slam, 1.0, 0.6))


def door_locked(rng):
    clunk = mix(
        (thud(0.1, 160, 100, 0.025), 1.0, 0.0),
        (partials(0.1, [(650, 0.4, 0.03), (1210, 0.2, 0.02)]), 0.8, 0.0),
    )
    return mix((clunk, 1.0, 0.0), (clunk, 0.8, 0.16))


def lever_pull(rng):
    ratchet = mix(*[(knock(rng, 700 - i * 60, 0.01), 0.7, i * 0.07) for i in range(4)])
    stop = mix((thud(0.2, 130, 70, 0.05), 1.0, 0.0), (partials(0.25, [(480, 0.5, 0.08)]), 0.6, 0.0))
    return mix((ratchet, 1.0, 0.0), (stop, 1.0, 0.3))


def portal_open(rng):
    rise_a = lowpass(tone(1.8, [(0, 60), (1, 240)], "saw"), [(0, 200), (1, 2500)])
    rise_b = lowpass(tone(1.8, [(0, 90.5), (1, 362)], "saw"), [(0, 200), (1, 2500)])
    hiss = bandpass(noise(1.8, rng), [(0, 500), (1, 5000)], 2.0)
    swell = envelope(mix((rise_a, 1.0, 0.0), (rise_b, 0.7, 0.0), (hiss, 0.25, 0.0)), [(0, 0), (0.7, 1), (1, 0)])
    return reverb(mix((swell, 1.0, 0.0), (thud(1.0, 80, 30, 0.3), 0.9, 0.0)), 0.4, 0.8)


def level_exit(rng):
    gong = partials(2.0, [(73.4, 1.0, 0.8), (146.8, 0.6, 0.6), (220, 0.3, 0.5)])
    notes = (293.66, 349.23, 440.0, 587.33)  # D minor, rising
    stabs = [(bell(f, 1.2, 0.45), 0.7, i * 0.12) for i, f in enumerate(notes)]
    return reverb(mix((gong, 1.0, 0.0), *stabs), 0.4, 0.8)


def secret_found(rng):
    notes = (659.25, 830.61, 987.77, 1244.5)  # E major 7th: bright and strange
    return reverb(mix(*[(bell(f, 0.8, 0.3), 1.0, i * 0.09) for i, f in enumerate(notes)]), 0.4, 0.6)


# --- Crystal obelisks ------------------------------------------------------

def obelisk_shatter(rng):
    shards = []
    for _ in range(40):
        freq = rng.uniform(1800, 7000)
        tau = rng.uniform(0.03, 0.12)
        shards.append((partials(0.4, [(freq, 1.0, tau)]), rng.uniform(0.3, 1.0), rng.random() ** 2 * 0.6))
    return mix(
        *shards,
        (decay(highpass(noise(0.3, rng), 3000), 0.05), 3.0, 0.0),
        (thud(0.3, 200, 80, 0.06), 2.0, 0.0),
    )


def obelisk_clink(rng):
    return partials(0.25, [(3300, 1.0, 0.05), (5150, 0.5, 0.04), (7100, 0.3, 0.03)])


# --- Menus -----------------------------------------------------------------

def menu_move(rng):
    return decay(tone(0.05, [(0, 500), (1, 380)], "tri"), 0.012)


def menu_select(rng):
    return mix((partials(0.2, [(392, 1.0, 0.08)]), 1.0, 0.0), (partials(0.3, [(587.3, 1.0, 0.12)]), 1.0, 0.07))


def menu_back(rng):
    return mix((partials(0.2, [(587.3, 1.0, 0.08)]), 1.0, 0.0), (partials(0.3, [(392, 1.0, 0.12)]), 1.0, 0.07))


def intermission_continue(rng):
    toll = partials(1.0, [(293.7, 1.0, 0.4), (587.3, 0.4, 0.3), (811, 0.2, 0.2), (1590, 0.1, 0.1)])
    return reverb(mix((toll, 1.0, 0.0), (thud(0.3, 90, 50, 0.08), 0.8, 0.0)), 0.3, 0.5)


# name: (function, peak level[, loops]). Peak sets how loud each sound is
# relative to the others; the buses set the overall volume.
SOUNDS = {
    "sword_swing": (sword_swing, 0.5),
    "sword_hit": (sword_hit, 0.8),
    "sword_wall": (sword_wall, 0.7),
    "hammer_swing": (hammer_swing, 0.55),
    "hammer_hit": (hammer_hit, 0.9),
    "hammer_wall": (hammer_wall, 0.85),
    "bow_draw": (bow_draw, 0.35),
    "bow_release": (bow_release, 0.7),
    "axe_throw": (axe_throw, 0.55),
    "arrow_impact": (arrow_impact, 0.7),
    "axe_impact": (axe_impact, 0.8),
    "fireball_cast": (fireball_cast, 0.75),
    "fireball_flight": (fireball_flight, 0.45, True),
    "explosion": (explosion, 0.95),
    "missile_cast": (missile_cast, 0.55),
    "missile_impact": (missile_impact, 0.6),
    "lightning_cast": (lightning_cast, 0.9),
    "lightning_hit": (lightning_hit, 0.6),
    "lightning_wall": (lightning_wall, 0.5),
    "heal_cast": (heal_cast, 0.6),
    "armor_cast": (armor_cast, 0.7),
    "armor_fading": (armor_fading, 0.5),
    "weapon_pickup": (weapon_pickup, 0.65),
    "ammo_pickup": (ammo_pickup, 0.55),
    "health_pickup": (health_pickup, 0.55),
    "key_pickup": (key_pickup, 0.55),
    "door_open": (door_open, 0.7),
    "door_close": (door_close, 0.75),
    "door_locked": (door_locked, 0.6),
    "lever_pull": (lever_pull, 0.7),
    "portal_open": (portal_open, 0.8),
    "level_exit": (level_exit, 0.7),
    "secret_found": (secret_found, 0.6),
    "obelisk_shatter": (obelisk_shatter, 0.9),
    "obelisk_clink": (obelisk_clink, 0.5),
    "menu_move": (menu_move, 0.35),
    "menu_select": (menu_select, 0.45),
    "menu_back": (menu_back, 0.45),
    "intermission_continue": (intermission_continue, 0.6),
}


if __name__ == "__main__":
    save_all(SOUNDS, OUT_DIR)
