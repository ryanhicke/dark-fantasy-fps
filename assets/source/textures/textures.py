"""Generates every map texture (64x64, tileable) and points the materials at them.

Each material in assets/textures/<set>/<name>.tres gets a <name>.png next to
it. Textures are painted at a readable mid brightness; the material's
albedo_color becomes a plain grey multiplier that brings the surface back to
the brightness the level was tuned at with the old tinted checker
(tint luminance x CHECKER_LUMA). Lower or raise BRIGHTNESS to relight every
level at once, or edit one material's grey by hand. Unshaded materials
(fire, lava, candles...) keep a white multiplier: their texture is the final
color.

Run from the project root:
    python assets/source/textures/textures.py [preview_dir]

AI-authored (Claude): see docs/placeholders.md.
"""

import math
import os
import re
import sys

from texture_tools import (S, Tex, bayer, clamp01, disc, edge_light, fbm, field, grime,
                           hash01, hexc, logs, lum, masonry, mix, moss, pick, planks, ramp,
                           rect, rock, save_preview, shade_ramp, speckle, voronoi)

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
TEX_DIR = os.path.join(ROOT, "assets", "textures")

# Mean luminance of addons/func_godot/textures/default_texture.png, which the
# levels were lit and tinted against before these textures existed.
CHECKER_LUMA = 0.258
# Global brightness knob applied on top of the matched brightness.
BRIGHTNESS = 1.0

# Tints the materials had with the checker (copied before conversion), so the
# script stays repeatable after it has rewritten albedo_color.
OLD_TINTS = {
    "camp/bone_token": (0.92, 0.88, 0.75), "camp/fire": (1, 0.55, 0.2),
    "camp/ground": (0.38, 0.34, 0.27), "camp/rug": (0.45, 0.16, 0.12),
    "camp/tent": (0.55, 0.5, 0.4), "camp/tent_inner": (0.5, 0.44, 0.34),
    "cave/ceiling": (0.22, 0.2, 0.18), "cave/floor": (0.3, 0.27, 0.24),
    "cave/floor_dirt": (0.36, 0.28, 0.2), "cave/floor_straw": (0.55, 0.47, 0.26),
    "cave/rock": (0.36, 0.32, 0.29), "crypt/ceiling": (0.17, 0.16, 0.16),
    "crypt/floor": (0.26, 0.25, 0.24), "crypt/pedestal": (0.45, 0.43, 0.4),
    "crypt/pillar": (0.36, 0.34, 0.32), "crypt/robe": (0.25, 0.22, 0.4),
    "crypt/tomb": (0.5, 0.48, 0.44), "crypt/wall": (0.3, 0.29, 0.28),
    "door/bone_gate": (0.85, 0.8, 0.66), "door/gold": (0.95, 0.78, 0.25),
    "door/hell": (0.3, 0.12, 0.1), "door/silver": (0.75, 0.78, 0.82),
    "forest/cliff": (0.62, 0.6, 0.55), "forest/cliff_night": (0.38, 0.4, 0.42),
    "forest/ground": (0.5, 0.62, 0.38), "forest/ground_night": (0.3, 0.36, 0.3),
    "forest/tree": (0.3, 0.24, 0.18), "gold/coins": (1, 0.85, 0.3),
    "hell/cage": (0.4, 0.36, 0.3), "hell/ceiling": (0.1, 0.08, 0.08),
    "hell/demon_shape": (0.35, 0.08, 0.06), "hell/fortress_floor": (0.26, 0.2, 0.2),
    "hell/fortress_wall": (0.14, 0.12, 0.13), "hell/ground": (0.34, 0.16, 0.12),
    "hell/lava": (1, 0.38, 0.1), "hell/pillar": (0.2, 0.15, 0.15),
    "hell/railing": (0.12, 0.1, 0.1), "hell/rock": (0.18, 0.12, 0.11),
    "lair/bookshelf": (0.36, 0.24, 0.16), "lair/carpet": (0.4, 0.1, 0.14),
    "lair/ceiling": (0.2, 0.18, 0.21), "lair/feast": (0.42, 0.45, 0.22),
    "lair/floor": (0.3, 0.28, 0.3), "lair/lab_bench": (0.33, 0.3, 0.26),
    "lair/potion": (0.3, 0.9, 0.4), "lair/table": (0.4, 0.28, 0.18),
    "lair/wall": (0.34, 0.31, 0.36), "monastery/altar": (0.65, 0.62, 0.55),
    "monastery/ceiling": (0.3, 0.28, 0.25), "monastery/floor": (0.42, 0.39, 0.35),
    "monastery/pillar": (0.55, 0.52, 0.46), "monastery/wall": (0.52, 0.48, 0.42),
    "mountain/grave_dirt": (0.36, 0.32, 0.28), "mountain/gravestone": (0.55, 0.55, 0.56),
    "mountain/mausoleum": (0.45, 0.45, 0.47), "mountain/rock": (0.5, 0.5, 0.52),
    "mountain/snow": (0.82, 0.84, 0.88), "outpost/anvil": (0.2, 0.2, 0.22),
    "outpost/bed": (0.55, 0.5, 0.42), "outpost/black_wax": (0.06, 0.05, 0.06),
    "outpost/forge": (0.3, 0.28, 0.27), "outpost/gate": (0.48, 0.34, 0.2),
    "outpost/gate_lintel": (0.4, 0.3, 0.2), "outpost/mud": (0.42, 0.34, 0.24),
    "outpost/palisade": (0.55, 0.42, 0.28), "outpost/plank_floor": (0.36, 0.27, 0.18),
    "outpost/plank_wall": (0.4, 0.3, 0.2), "outpost/stone_floor": (0.34, 0.33, 0.32),
    "outpost/straw": (0.62, 0.53, 0.3), "outpost/thatch": (0.3, 0.26, 0.16),
    "outpost/tower": (0.5, 0.38, 0.25), "ritual/candle": (1, 0.8, 0.45),
    "ritual/floor": (0.32, 0.18, 0.18), "ritual/portal_frame": (0.15, 0.1, 0.12),
    "town/ash_ground": (0.36, 0.33, 0.31), "town/burnt_wall": (0.3, 0.24, 0.2),
    "town/captain_body": (0.6, 0.12, 0.1), "town/charred_beam": (0.16, 0.13, 0.11),
    "town/embers": (1, 0.45, 0.15), "town/well": (0.45, 0.43, 0.4),
    "wood/cart": (0.5, 0.36, 0.22), "wood/crate": (0.6, 0.44, 0.26),
    "wood/door": (0.52, 0.36, 0.2), "wood/fence": (0.46, 0.34, 0.21),
    "wood/grain_sack": (0.75, 0.66, 0.45), "wood/planks": (0.42, 0.3, 0.2),
    "wood/strongbox": (0.35, 0.22, 0.14),
}

UNSHADED = {"camp/fire", "hell/lava", "lair/potion", "ritual/candle", "town/embers"}


def base(tint, floor=0.5):
    """Tint scaled up to at least `floor` luminance, as 0-255 RGB."""
    c = tuple(v * 255 for v in tint)
    k = max(1.0, floor / max(0.02, lum(c)))
    return tuple(min(255, v * k) for v in c)


def tramp(name, n=5, lo=0.45, hi=1.45, floor=0.5):
    return shade_ramp(base(OLD_TINTS[name], floor), n, lo, hi)


# --- shared ramps ------------------------------------------------------------

STONE = ramp("2a2a30", "45444a", "605e62", "7c7a7a", "9a9690")
WARM_STONE = ramp("2e2824", "4a423a", "665c50", "847866", "a29680")
MORTAR = ramp("1a1816", "26231f", "302c27")
WOOD = ramp("2a180e", "4a2c18", "6a4224", "8a5a32", "a87444")
DARK_WOOD = ramp("1c120c", "2e1e14", "42301e", "584028", "6e5236")
IRON = ramp("16161a", "2a2a30", "44444c", "62626a", "8a8a90")
RUST = ramp("2a160e", "4a2614", "6a3a1c", "8a5028")
MOSS = ramp("1e2a12", "2e3e18", "3e5220", "566a2a")
SOOT = ramp("0e0c0c", "1a1716", "26221f", "332e2a")
BONE = ramp("5a5040", "8a7e66", "b4a888", "d4caa8", "ece4c8")
GOLD = ramp("4a2e08", "7a5214", "b07e22", "dcac3a", "f8dc78", "fff4c0")
SILVER = ramp("34363e", "5a5e68", "868a94", "b0b4bc", "dadde2", "f6f8fa")
FIRE = ramp("3a0804", "7a1806", "c03a0a", "f06a14", "ffa830", "ffe070", "fff8d0")
STRAW = ramp("4a3814", "6e5420", "92722e", "b4923e", "d4b45a")
CLOTH_RED = ramp("2a0a0a", "4e1410", "742018", "9a3022", "b84a32")
BLOOD = ramp("1e0404", "3e0806", "600e0a")


def crack(t, x, y, length, seed, color, dir_x=0.0, dir_y=1.0, light=None):
    """Thin wandering crack, with an optional lit lip on its lower-right."""
    for s in range(length):
        t.set(x, y, color)
        if light:
            t.set(x + 1, y + 1, light)
        r = hash01(s, seed, 77)
        if r < 0.3:
            x += -1 if dir_y else 0
            y += -1 if dir_x else 0
        elif r > 0.7:
            x += 1 if dir_y else 0
            y += 1 if dir_x else 0
        x += dir_x
        y += dir_y


def scatter_cracks(t, n, seed, color, length=(6, 14)):
    for i in range(n):
        x = int(hash01(i, 1, seed) * S)
        y = int(hash01(i, 2, seed) * S)
        ln = int(length[0] + hash01(i, 3, seed) * (length[1] - length[0]))
        horiz = hash01(i, 4, seed) < 0.5
        crack(t, x, y, ln, seed + i, color, 1 if horiz else 0, 0 if horiz else 1)


def rivet(t, x, y, rmp):
    t.set(x, y, rmp[-2])
    t.set(x - 1, y - 1, rmp[-1])
    t.set(x + 1, y + 1, rmp[0])
    t.set(x + 1, y, rmp[1])
    t.set(x, y + 1, rmp[1])


def metal_plate(rmp, seed, rough=0.25, scratches=10):
    t = field(lambda x, y, ix, iy: 0.5 + (fbm(x, y, 4, octaves=3, seed=seed) - 0.5) * rough * 2
              + (fbm(x, y, 2, 16, octaves=1, seed=seed + 1) - 0.5) * 0.15, rmp)
    for i in range(scratches):
        x = hash01(i, 0, seed) * S
        y = hash01(i, 1, seed) * S
        ln = 3 + int(hash01(i, 2, seed) * 6)
        dx = 1 if hash01(i, 3, seed) < 0.5 else -1
        for k in range(ln):
            t.set(x + k * dx, y + k * 0.4, rmp[-1] if k % 3 else rmp[-2])
    return t


# --- base (test map) -------------------------------------------------------

def base_wall():
    t, _ = masonry(STONE, MORTAR, 8, 4, 11)
    return t


def base_floor():
    t, _ = masonry(WARM_STONE, MORTAR, 4, 4, 12, offset=0.5, var=0.12)
    return t


def base_ceiling():
    return planks(DARK_WOOD, 4, 13, nails=False)


def base_door():
    return wood_door()


def base_door_gold():
    return gold_door()


# --- camp --------------------------------------------------------------------

def bone_surface(name, seed):
    rmp = BONE

    def fn(x, y, ix, iy):
        return 0.6 + (fbm(x, y, 4, octaves=3, seed=seed) - 0.5) * 0.7 \
            + (fbm(x, y, 2, 16, octaves=1, seed=seed + 1) - 0.5) * 0.3

    t = field(fn, rmp)
    # Pores and the dark grain of old bone.
    speckle(t, [rmp[1], rmp[0]], 0.025, seed + 2)
    scatter_cracks(t, 7, seed + 3, rmp[0], (4, 10))
    grime(t, 0.35, seed + 4, px=4, dark=0.7)
    return t


def camp_bone_token():
    return bone_surface("camp/bone_token", 21)


def camp_fire():
    rmp = FIRE

    def fn(x, y, ix, iy):
        n = fbm(x, y, 4, 2, octaves=3, seed=31)
        streak = fbm(x, y, 8, 1, octaves=2, seed=32)
        return 0.25 + (n - 0.5) * 1.3 + (streak - 0.5) * 0.9 + 0.25 * math.sin(y / S * math.pi * 2) ** 2

    t = field(fn, rmp)
    speckle(t, [rmp[-1], rmp[-2]], 0.02, 33)
    return t


def ground(rmp, seed, pebble_rmp=None, pebbles=0.02, blades=None, blade_density=0.0, patch=None):
    def fn(x, y, ix, iy):
        return 0.5 + (fbm(x, y, 4, octaves=4, seed=seed) - 0.5) * 1.2

    t = field(fn, rmp)
    if patch:
        prmp, amount = patch
        for y in range(S):
            for x in range(S):
                n = fbm(x + 0.5, y + 0.5, 2, octaves=3, seed=seed + 50)
                if n > 1 - amount:
                    t.set(x, y, pick(prmp, 0.4 + (fbm(x, y, 8, seed=seed + 51) - 0.5), x, y))
    if blades:
        for i in range(int(S * S * blade_density)):
            x = int(hash01(i, 0, seed + 7) * S)
            y = int(hash01(i, 1, seed + 7) * S)
            h = 2 + int(hash01(i, 2, seed + 7) * 3)
            lean = 1 if hash01(i, 3, seed + 7) < 0.5 else -1
            for k in range(h):
                t.set(x + (lean if k == h - 1 else 0), y - k, blades[min(len(blades) - 1, k + 1)])
            t.set(x, y + 1, blades[0])
    if pebble_rmp:
        for i in range(int(S * S * pebbles)):
            x = int(hash01(i, 0, seed + 9) * S)
            y = int(hash01(i, 1, seed + 9) * S)
            t.set(x, y, pebble_rmp[2])
            t.set(x + 1, y, pebble_rmp[1])
            t.set(x, y - 1, pebble_rmp[3])
            t.set(x + 1, y + 1, pebble_rmp[0])
    return t


def camp_ground():
    rmp = tramp("camp/ground")
    grass = ramp("2a3016", "3e4620", "52582a", "6a6e36")
    return ground(rmp, 41, STONE, 0.012, blades=grass, blade_density=0.02)


def camp_rug():
    rmp = CLOTH_RED
    gold = ramp("4a3010", "7a5a20", "a88438", "c8a656")
    navy = ramp("101420", "1c2234", "2a3248")
    t = Tex()
    for y in range(S):
        for x in range(S):
            weave = 0.08 if (x + y) % 2 else -0.04
            n = (fbm(x + 0.5, y + 0.5, 8, seed=42) - 0.5) * 0.4
            # Border band near the tile edge (rug pattern repeats every 2 m).
            bx = min(x, S - 1 - x)
            by = min(y, S - 1 - y)
            b = min(bx, by)
            cx, cy = abs(x - 31.5), abs(y - 31.5)
            diamond = cx + cy
            if b < 2:
                c = pick(navy, 0.5 + n + weave, x, y)
            elif b < 6:
                stripe = ((x + y) // 2) % 3 == 0 if bx > by else ((x - y) // 2) % 3 == 0
                c = pick(gold if stripe else navy, 0.5 + n + weave, x, y)
            elif b < 7:
                c = pick(gold, 0.6 + n, x, y)
            elif diamond < 6:
                c = pick(gold, 0.7 + n + weave, x, y)
            elif diamond < 9:
                c = pick(navy, 0.5 + n + weave, x, y)
            elif abs(diamond - 18) < 1.5 or (diamond < 24 and (cx < 1 or cy < 1)):
                c = pick(gold, 0.4 + n + weave, x, y)
            else:
                c = pick(rmp, 0.55 + n + weave, x, y)
            t.set(x, y, c)
    grime(t, 0.3, 43, dark=0.65)
    return t


def canvas(rmp, seed, seams=True, stains=0.3, vertical_seams=True):
    def fn(x, y, ix, iy):
        weave = 0.07 if (ix % 2) ^ (iy % 2) else -0.05
        fold = 0.12 * math.sin((x / S) * math.pi * 4 + fbm(x, y, 2, seed=seed) * 3)
        return 0.55 + weave + fold + (fbm(x, y, 8, octaves=2, seed=seed + 1) - 0.5) * 0.4

    t = field(fn, rmp)
    if seams:
        for y in range(S):
            for sx in (0, 32):
                x = sx if vertical_seams else y
                yy = y if vertical_seams else sx
                t.set(x, yy, rmp[0])
                if y % 4 == 1:
                    t.set(x + 1, yy, rmp[-1])
    grime(t, stains, seed + 2, px=3, dark=0.6, bottom_bias=0.6)
    return t


def camp_tent():
    return canvas(tramp("camp/tent", lo=0.5, hi=1.35), 51)


def camp_tent_inner():
    return canvas(tramp("camp/tent_inner", lo=0.45, hi=1.25), 52, stains=0.4)


# --- cave --------------------------------------------------------------------

CAVE_ROCK = ramp("1c1a1a", "2e2a28", "433d38", "5a524a", "726858", "8a7e6c")


def cave_rock():
    t, _ = rock(CAVE_ROCK, 5, 5, 61, crack=1.0, facet=0.5)
    moss(t, MOSS, 0.12, 62, px=3)
    grime(t, 0.3, 63, dark=0.6)
    return t


def cave_ceiling():
    t, _ = rock(CAVE_ROCK, 4, 4, 71, crack=1.3, facet=0.6, rough=0.6)
    grime(t, 0.45, 72, dark=0.5)
    # Damp drips catching light.
    speckle(t, [CAVE_ROCK[4]], 0.006, 73)
    return t


def cave_floor():
    t, _ = rock(CAVE_ROCK, 6, 6, 81, crack=0.9, facet=0.25, rough=0.4)
    speckle(t, [CAVE_ROCK[1]], 0.03, 82)
    return t


def cave_floor_dirt():
    rmp = tramp("cave/floor_dirt")
    return ground(rmp, 91, CAVE_ROCK, 0.02)


def straw(rmp, seed, density=1.0, base_rmp=None):
    t = field(lambda x, y, ix, iy: 0.3 + (fbm(x, y, 4, seed=seed) - 0.5) * 0.6, base_rmp or rmp)
    n = int(S * S * 0.11 * density)
    for i in range(n):
        x = hash01(i, 0, seed + 1) * S
        y = hash01(i, 1, seed + 1) * S
        ang = hash01(i, 2, seed + 1) * math.pi
        ln = 5 + int(hash01(i, 3, seed + 1) * 9)
        v = 0.35 + hash01(i, 4, seed + 1) * 0.65
        dx, dy = math.cos(ang), math.sin(ang)
        for k in range(ln):
            px, py = int(x + dx * k), int(y + dy * k)
            t.set(px, py, pick(rmp, v - (0.25 if k in (0, ln - 1) else 0), px, py, 0.3))
    return t


def cave_floor_straw():
    return straw(STRAW, 101, base_rmp=tramp("cave/floor_dirt", floor=0.35))


# --- crypt -------------------------------------------------------------------

CRYPT = ramp("18181c", "28282e", "3a3a40", "4e4c50", "646064", "7c7876")


def crypt_wall():
    t, _ = masonry(CRYPT, MORTAR, 8, 3, 111, offset=None, var=0.2, rough=0.35, jagged=True)
    scatter_cracks(t, 6, 112, CRYPT[0])
    moss(t, ramp("1a2214", "263020", "34402a"), 0.1, 113, px=3)
    grime(t, 0.35, 114, dark=0.55, bottom_bias=0.5)
    return t


def crypt_floor():
    t, _ = masonry(CRYPT, MORTAR, 2, 2, 121, offset=0.5, var=0.15, rough=0.3, mortar=1)
    scatter_cracks(t, 8, 122, CRYPT[0], (8, 20))
    grime(t, 0.4, 123, dark=0.6)
    return t


def crypt_ceiling():
    t, _ = masonry(CRYPT, MORTAR, 4, 2, 131, offset=0.5, var=0.12, rough=0.45)
    grime(t, 0.55, 132, dark=0.45)
    return t


def carved_panel(rmp, seed, border=4, inset=10, rough=0.25):
    """Smooth dressed stone with a raised border and a sunken panel."""
    def fn(x, y, ix, iy):
        return 0.55 + (fbm(x, y, 4, octaves=3, seed=seed) - 0.5) * rough * 2

    t = field(fn, rmp)
    for y in range(S):
        for x in range(S):
            d = min(x, y, S - 1 - x, S - 1 - y)
            if d == 0:
                t.tint(x, y, 0.55)
            elif d == border:
                t.tint(x, y, 0.75 if (x < S / 2 and y < S / 2) or x == d or y == d else 1.15)
            elif d == inset:
                lit = x == d or y == d
                t.tint(x, y, 0.65 if lit else 1.2)
            elif d > inset:
                t.tint(x, y, 0.88)
    return t


def crypt_tomb():
    rmp = ramp("2e2c2a", "4a4642", "666058", "827a70", "9e968a", "b8b0a2")
    t = carved_panel(rmp, 141)
    # A carved cross inside the panel, the necromancer's mark scratched over it.
    for y in range(18, 46):
        for x in range(30, 34):
            t.tint(x, y, 0.7 if x == 30 else 0.85)
    for y in range(24, 28):
        for x in range(22, 42):
            t.tint(x, y, 0.7 if y == 24 else 0.85)
    scatter_cracks(t, 4, 142, rmp[0])
    grime(t, 0.3, 143, dark=0.6)
    return t


def crypt_pedestal():
    rmp = ramp("2a2826", "44403c", "5e5852", "7a7268", "968c80")
    t = carved_panel(rmp, 151, border=3, inset=7)
    for y in range(S):
        if y % 16 in (0, 1):
            for x in range(S):
                t.tint(x, y, 0.7 if y % 16 == 0 else 1.15)
    grime(t, 0.3, 152, dark=0.6)
    return t


def fluted(rmp, seed, flutes=4, bands=True):
    w = S / flutes

    def fn(x, y, ix, iy):
        lv = (x % w) / w
        shade = math.cos((lv - 0.4) * math.pi)
        return 0.15 + 0.7 * shade + (fbm(x, y, 4, octaves=3, seed=seed) - 0.5) * 0.4

    t = field(fn, rmp)
    if bands:
        for x in range(S):
            for y in (0, 1, 2):
                t.set(x, y, pick(rmp, (0.9, 0.6, 0.2)[y], x, y))
    return t


def crypt_pillar():
    t = fluted(CRYPT, 161)
    scatter_cracks(t, 3, 162, CRYPT[0])
    grime(t, 0.35, 163, dark=0.55, bottom_bias=0.6)
    return t


def crypt_robe():
    rmp = tramp("crypt/robe", lo=0.4, hi=1.4)

    def fn(x, y, ix, iy):
        folds = math.sin(x / S * math.pi * 6 + fbm(x, y, 2, 4, seed=171) * 4)
        return 0.5 + folds * 0.3 + (fbm(x, y, 8, seed=172) - 0.5) * 0.3 + (0.04 if (ix + iy) % 2 else 0)

    t = field(fn, rmp)
    grime(t, 0.3, 173, dark=0.6)
    return t


# --- doors -------------------------------------------------------------------

def framed_door(face, frame_rmp, seed, stud_rmp, plank_count=4, bands=(10, 52)):
    """Planked or plated face with a metal frame, two straps and studs."""
    t = face
    for y in range(S):
        for x in range(S):
            d = min(x, S - 1 - x)
            if d < 3 or any(abs(y - b) < 3 for b in bands):
                n = (fbm(x + 0.5, y + 0.5, 8, seed=seed) - 0.5) * 0.4
                edge = 0.25 if (d == 0 or any(y - b == 2 for b in bands)) else (0.8 if any(y - b == -2 for b in bands) or d == 2 else 0.55)
                t.set(x, y, pick(frame_rmp, edge + n, x, y))
    for b in bands:
        for x in range(6, S, 8):
            rivet(t, x, b, stud_rmp)
    for y in range(6, S, 8):
        rivet(t, 1, y, stud_rmp)
        rivet(t, S - 2, y, stud_rmp)
    return t


def wood_door():
    face = planks(WOOD, 4, 181, vertical=True, nails=False, joints=1)
    return framed_door(face, IRON, 182, IRON)


def gold_door():
    face = metal_plate(GOLD, 191, rough=0.2)
    # Engraved diamond lattice.
    for y in range(S):
        for x in range(S):
            if (x + y) % 16 == 0 or (x - y) % 16 == 0:
                face.tint(x, y, 0.7)
            elif (x + y) % 16 == 1 or (x - y) % 16 == 1:
                face.tint(x, y, 1.12)
    return framed_door(face, ramp("2e1a06", "5a3a10", "8a6018", "b48a30"), 192, GOLD)


def silver_door():
    face = metal_plate(SILVER, 201, rough=0.18)
    for y in range(S):
        for x in range(S):
            dx, dy = abs(x - 31.5), abs(y - 31.5)
            if abs(max(dx, dy) - 12) < 0.6 or abs(dx + dy - 10) < 0.6:
                face.tint(x, y, 0.72)
    return framed_door(face, ramp("1e2026", "34363e", "50545c", "6e7280"), 202, SILVER)


def bone_gate():
    t = field(lambda x, y, ix, iy: 0.3 + (fbm(x, y, 4, seed=211) - 0.5) * 0.5,
              ramp("0e0c0a", "1a1612", "26201a"))

    def bone(x0, y0, length, horizontal, seed):
        for k in range(length):
            for w in range(-1, 2):
                x, y = (x0 + k, y0 + w) if horizontal else (x0 + w, y0 + k)
                v = 0.65 - w * 0.25 + (hash01(k, w, seed) - 0.5) * 0.25
                t.set(x, y, pick(BONE, v, x, y, 0.5))
        for end in (0, length - 1):
            for a in (-2, 2):
                for b in (-1, 0, 1):
                    x, y = (x0 + end + b, y0 + a) if horizontal else (x0 + a, y0 + end + b)
                    t.set(x, y, pick(BONE, 0.7 - a * 0.1, x, y, 0.5))

    for i in range(4):
        bone(i * 16 + 8, 0, 64, False, 212 + i)
    for j in range(2):
        bone(0, j * 32 + 16, 64, True, 220 + j)
    # Skulls at the crossings of the upper bar.
    for i in range(4):
        cx, cy = i * 16 + 8, 16
        disc(t, cx, cy, 4.5, lambda x, y, dx, dy: pick(BONE, 0.7 - (dx + dy) * 0.05, x, y))
        for ex in (-2, 1):
            t.set(cx + ex, cy, BONE[0])
            t.set(cx + ex + 1, cy, BONE[0])
        t.set(cx, cy + 2, BONE[0])
        for tx in range(-2, 3):
            t.set(cx + tx, cy + 4, BONE[1] if tx % 2 else BONE[3])
    grime(t, 0.3, 230, dark=0.6)
    return t


def hell_door():
    rmp = ramp("100808", "1e0e0c", "301614", "46201c", "5c2a24")
    face = metal_plate(rmp, 241, rough=0.3, scratches=4)
    glow = ramp("6a0e04", "b42808", "f05a10", "ffb040")
    # Glowing runes: short strokes on a grid.
    for i in range(10):
        cx = 8 + (i % 5) * 12
        cy = 20 if i < 5 else 44
        for k in range(6):
            r = hash01(i, k, 242)
            x, y = cx + int((r - 0.5) * 6), cy + k - 3
            face.set(x, y, glow[2])
            face.set(x + 1, y, glow[1])
            if r > 0.6:
                face.set(x - 1, y, glow[3])
    t = framed_door(face, ramp("0a0606", "1a0e0c", "2c1a16", "40261e"), 243, IRON, bands=(4, 32, 60))
    return t


# --- forest ------------------------------------------------------------------

def cliff(rmp, seed, moss_rmp, moss_amt):
    t, mask = rock(rmp, 3, 8, seed, crack=1.0, facet=0.45, var=0.2)
    for y in range(S):
        if y % 8 == 0:
            for x in range(S):
                if hash01(x // 3, y, seed) < 0.8:
                    t.set(x, y, rmp[0])
                    t.set(x, y + 1, rmp[-1] if hash01(x, y, seed + 1) < 0.5 else rmp[-2])
    moss(t, moss_rmp, moss_amt, seed + 2, px=3)
    return t


def forest_cliff():
    return cliff(ramp("2c2a26", "46423c", "605a52", "7c7468", "988e80", "b2a898"), 251,
                 MOSS, 0.16)


def forest_cliff_night():
    return cliff(ramp("181c24", "262c36", "363e4a", "48505c", "5c6470", "707884"), 251,
                 ramp("141e1a", "1e2a24", "28382e"), 0.16)


def forest_ground():
    rmp = ramp("26341a", "36481e", "4a5e26", "607432", "788a3e", "92a24c")
    blades = ramp("2a3a18", "4a6226", "6a8234", "8ea646")
    dirt = ramp("2e2418", "44362a", "5a4836")
    return ground(rmp, 261, STONE, 0.006, blades=blades, blade_density=0.06, patch=(dirt, 0.18))


def forest_ground_night():
    rmp = ramp("141c18", "1c2820", "26342a", "324034", "3e4e40")
    blades = ramp("18221c", "263428", "344634", "425842")
    dirt = ramp("16141a", "201e24", "2a282e")
    return ground(rmp, 261, STONE, 0.004, blades=blades, blade_density=0.06, patch=(dirt, 0.18))


def bark(rmp, seed):
    def fn(x, y, ix, iy):
        n = fbm(x, y, 8, 2, octaves=3, seed=seed)
        ridge = 1 - abs(n - 0.5) * 2
        return 0.2 + ridge * 0.75 + (fbm(x, y, 16, 8, seed=seed + 1) - 0.5) * 0.3

    t = field(fn, rmp)
    # Deep grooves run up the trunk every 8 px, pushed sideways by noise so
    # they wander and merge like real bark plates.
    for y in range(S):
        for x in range(S):
            wobble = (fbm(x + 0.5, y + 0.5, 4, 2, octaves=2, seed=seed + 2) - 0.5) * 12
            d = (x + wobble) % 8
            if d < 1.6:
                t.set(x, y, rmp[0])
            elif d < 2.6:
                t.tint(x, y, 1.2)
    return t


def forest_tree():
    t = bark(ramp("140e0a", "26180e", "3a2616", "50361e", "684828"), 271)
    moss(t, MOSS, 0.1, 272, px=2)
    return t


def gold_coins():
    t = field(lambda x, y, ix, iy: 0.3 + (fbm(x, y, 8, seed=281) - 0.5) * 0.5, GOLD[:3])
    for i in range(70):
        cx = hash01(i, 0, 282) * S
        cy = hash01(i, 1, 282) * S
        r = 3 + hash01(i, 2, 282) * 1.6
        tilt = 0.55 + hash01(i, 3, 282) * 0.45

        def col(x, y, dx, dy, r=r, tilt=tilt):
            if (dx * dx) + (dy / tilt) ** 2 > r * r:
                return None
            rim = (dx * dx) + (dy / tilt) ** 2 > (r - 1.2) ** 2
            v = 0.6 - (dx + dy) / (r * 4) + (0.15 if rim and dx + dy < 0 else 0) - (0.25 if rim and dx + dy > 0 else 0)
            return pick(GOLD, v, x, y, 0.5)

        disc(t, int(cx), int(cy), r, col)
        # Outline the lower edge so stacked coins read separately.
        for dx in range(-int(r), int(r) + 1):
            dy = int(tilt * math.sqrt(max(0, r * r - dx * dx))) + 1
            t.set(cx + dx, cy + dy, GOLD[0])
    speckle(t, [GOLD[-1]], 0.012, 283)
    return t


# --- hell --------------------------------------------------------------------

HELL_ROCK = ramp("0c0606", "1c0c0a", "2e1410", "421c16", "58261c", "703224")
EMBER = ramp("5a0c04", "a02008", "e04a10", "ff8a24", "ffd060")


def glowing_cracks(t, mask, glow, seed, chance=0.6):
    for y in range(S):
        for x in range(S):
            if mask[y][x] and fbm(x + 0.5, y + 0.5, 4, seed=seed) > 1 - chance:
                v = fbm(x + 0.5, y + 0.5, 8, seed=seed + 1)
                t.set(x, y, pick(glow, v, x, y))


def hell_rock():
    t, mask = rock(HELL_ROCK, 5, 5, 291, crack=1.1, facet=0.55)
    glowing_cracks(t, mask, EMBER[:3], 292, 0.4)
    return t


def hell_ceiling():
    t, mask = rock(HELL_ROCK, 4, 4, 301, crack=1.0, facet=0.5)
    grime(t, 0.5, 302, dark=0.5)
    glowing_cracks(t, mask, EMBER[:2], 303, 0.25)
    return t


def hell_ground():
    rmp = ramp("1a0806", "2e100a", "441a10", "5c2616", "74321c")

    def fn(x, y, ix, iy):
        return 0.5 + (fbm(x, y, 4, octaves=4, seed=311) - 0.5) * 1.1

    t = field(fn, rmp)
    mask = [[False] * S for _ in range(S)]
    for y in range(S):
        for x in range(S):
            f1, f2, _, _ = voronoi(x + 0.5, y + 0.5, 4, 4, 312)
            if f2 - f1 < 0.9:
                mask[y][x] = True
                t.set(x, y, rmp[0])
    edge_light(t, mask, 1.2, 0.8)
    glowing_cracks(t, mask, EMBER[:3], 313, 0.35)
    speckle(t, [ramp("221010")[0]], 0.03, 314)
    return t


def hell_lava():
    rmp = ramp("3a0604", "8a1806", "d03a08", "f87010", "ffb030", "ffe680")

    def fn(x, y, ix, iy):
        f1, f2, _, vec = voronoi(x, y, 4, 4, 321)
        edge = clamp01((f2 - f1) / 8)
        n = fbm(x, y, 4, octaves=3, seed=322)
        # Cooled crust in cell centres, bright molten seams between them.
        return 0.95 - edge * 0.9 + (n - 0.5) * 0.5

    return field(fn, rmp)


def hell_fortress_wall():
    rmp = ramp("0e0c0e", "1c181c", "2a2428", "3a3236", "4a4044")
    mortar = ramp("2a0806", "4a1008", "6a1a0a")
    t, _ = masonry(rmp, mortar, 8, 2, 331, offset=0.5, var=0.18, rough=0.3)
    scatter_cracks(t, 5, 332, rmp[0])
    return t


def hell_fortress_floor():
    rmp = ramp("1a1212", "2a1c1c", "3a2828", "4c3434", "5e4040")
    t, _ = masonry(rmp, ramp("120808", "1c0c0a", "2a100c"), 4, 4, 341, offset=0, var=0.1, rough=0.25, mortar=2)
    # Iron grate in the centre of every fourth slab.
    scatter_cracks(t, 6, 342, rmp[0], (6, 12))
    grime(t, 0.3, 343, dark=0.6)
    return t


def hell_pillar():
    rmp = ramp("100a0a", "1e1414", "2e1e1e", "402a28", "523632")
    t = fluted(rmp, 351, flutes=2)
    for y in range(4, S, 16):
        for x in range(S):
            for k in range(3):
                t.set(x, y + k, pick(IRON, (0.8, 0.5, 0.2)[k], x, y + k))
        for x in range(4, S, 8):
            # Small spikes on the iron bands.
            t.set(x, y - 1, IRON[3])
            t.set(x, y - 2, IRON[4])
    return t


def bars(rmp, back, seed, spacing=8, width=3, cross=(0, 32), rust_amt=0.3):
    t = field(lambda x, y, ix, iy: 0.4 + (fbm(x, y, 4, seed=seed) - 0.5) * 0.6, back)
    for y in range(S):
        for x in range(S):
            lx = x % spacing
            on_bar = lx < width
            on_cross = any(abs(y - c) < 2 or abs(y - c - S) < 2 for c in cross)
            if on_bar or on_cross:
                if on_bar and not on_cross:
                    v = (0.85, 0.55, 0.25, 0.15)[min(lx, 3)]
                else:
                    v = 0.75 if (y in cross) or ((y - 1) in cross) else 0.35
                n = fbm(x + 0.5, y + 0.5, 8, seed=seed + 1)
                c = pick(rmp, v + (n - 0.5) * 0.3, x, y)
                if n > 1 - rust_amt:
                    c = pick(RUST, v, x, y)
                t.set(x, y, c)
    for x in range(0, S, spacing):
        for c in cross:
            rivet(t, x + 1, c, rmp)
    return t


def hell_cage():
    return bars(IRON, ramp("0a0606", "140c0a", "1e1410"), 361, spacing=8, cross=(4, 36), rust_amt=0.4)


def hell_railing():
    return bars(ramp("0e0c0e", "1e1a1e", "302a2e", "463e40", "5a5052"),
                ramp("080606", "100c0a", "181210"), 371, spacing=16, width=4, cross=(2, 34), rust_amt=0.25)


def hell_demon_shape():
    rmp = ramp("1a0404", "320806", "4e100a", "6a1a10", "882818", "a63a22")

    def fn(x, y, ix, iy):
        f1, f2, _, vec = voronoi(x, y, 6, 4, 381, 0.9)
        return 0.6 - (vec[0] + vec[1]) * 0.4 + (fbm(x, y, 8, seed=382) - 0.5) * 0.5 - (0.4 if f2 - f1 < 1.5 else 0)

    t = field(fn, rmp)
    vein = ramp("ff7a1a", "ffc040")
    for i in range(6):
        crack(t, int(hash01(i, 0, 383) * S), int(hash01(i, 1, 383) * S), 18, 384 + i, vein[0], 0, 1)
    return t


# --- lair --------------------------------------------------------------------

LAIR_STONE = ramp("1a161c", "2a242e", "3c3442", "504656", "665a6c", "7c6e82")


def lair_wall():
    t, _ = masonry(LAIR_STONE, MORTAR, 4, 2, 391, offset=0.5, var=0.15, rough=0.28)
    scatter_cracks(t, 4, 392, LAIR_STONE[0])
    grime(t, 0.3, 393, dark=0.6, bottom_bias=0.5)
    return t


def lair_floor():
    t = Tex()
    light = LAIR_STONE
    dark = ramp("141016", "201a24", "2c2432", "3a3040")
    for y in range(S):
        for x in range(S):
            tx, ty = x // 16, y // 16
            lx, ly = x % 16, y % 16
            rmp = light if (tx + ty) % 2 == 0 else dark
            v = 0.55 + (fbm(x + 0.5, y + 0.5, 8, seed=401) - 0.5) * 0.5
            if lx == 0 or ly == 0:
                t.set(x, y, MORTAR[0])
                continue
            if lx == 1 or ly == 1:
                v += 0.2
            elif lx == 15 or ly == 15:
                v -= 0.2
            t.set(x, y, pick(rmp, v, x, y))
    scatter_cracks(t, 5, 402, MORTAR[0], (4, 10))
    grime(t, 0.3, 403, dark=0.6)
    return t


def lair_ceiling():
    t, _ = masonry(LAIR_STONE, MORTAR, 4, 2, 411, offset=0.5, var=0.12, rough=0.35)
    # Heavy dark beams every 2 m.
    for y in range(S):
        for x in range(S):
            if y < 10:
                v = (0.8 if y == 0 else (0.15 if y == 9 else 0.5)) + (fbm(x + 0.5, y + 0.5, 2, 16, seed=412) - 0.5) * 0.5
                t.set(x, y, pick(DARK_WOOD, v, x, y))
    grime(t, 0.5, 413, dark=0.5)
    return t


def lair_bookshelf():
    t = Tex()
    spines = [ramp("2a0a0a", "4a1410", "6a2018"), ramp("0e1a12", "182a1e", "243c2a"),
              ramp("10142a", "1a2040", "282e58"), ramp("2a1a0c", "462e16", "624220"),
              ramp("1e1610", "322418", "463424")]
    gold = ramp("6a4a18", "b08a3a")
    for shelf in range(2):
        y0 = shelf * 32
        # Back of the shelf.
        for y in range(y0, y0 + 32):
            for x in range(S):
                t.set(x, y, pick(DARK_WOOD[:2], 0.3, x, y))
        x = 0
        i = 0
        while x < S:
            w = 3 + int(hash01(i, shelf, 421) * 4)
            w = min(w, S - x)
            h = 18 + int(hash01(i, shelf + 5, 421) * 9)
            rmp = spines[int(hash01(i, shelf + 9, 421) * len(spines))]
            gap = hash01(i, shelf + 13, 421) < 0.08
            if not gap:
                top = y0 + 28 - h
                for yy in range(top, y0 + 28):
                    for xx in range(x, x + w):
                        lx = xx - x
                        v = 0.8 if lx == 0 else (0.15 if lx == w - 1 else 0.5)
                        c = pick(rmp, v, xx, yy, 0.4)
                        if yy - top in (2, h - 4) and lx not in (0, w - 1):
                            c = gold[1] if lx == 1 else gold[0]
                        t.set(xx, yy, c)
                for xx in range(x, x + w):
                    t.set(xx, top, rmp[2])
            x += w
            i += 1
        # Shelf board.
        for y in range(y0 + 28, y0 + 32):
            for xx in range(S):
                v = (0.85, 0.55, 0.45, 0.15)[y - y0 - 28]
                t.set(xx, y, pick(WOOD, v + (fbm(xx + 0.5, y + 0.5, 2, 16, seed=422) - 0.5) * 0.3, xx, y))
    grime(t, 0.3, 423, dark=0.65)
    return t


def lair_carpet():
    rmp = ramp("1e0408", "36080e", "520e18", "6e1822", "8a2430")
    gold = ramp("3a2a10", "6a5020", "9a7a36")
    t = Tex()
    for y in range(S):
        for x in range(S):
            weave = 0.07 if (x + y) % 2 else -0.04
            n = (fbm(x + 0.5, y + 0.5, 8, seed=431) - 0.5) * 0.35
            cx, cy = (x % 32) - 15.5, (y % 32) - 15.5
            ring = abs(math.hypot(cx, cy) - 9)
            if ring < 1.2 or (abs(cx) < 1 and abs(cy) < 4) or (abs(cy) < 1 and abs(cx) < 4):
                c = pick(gold, 0.6 + n, x, y)
            elif min(x % 32, y % 32) < 2:
                c = pick(gold, 0.3 + n + weave, x, y)
            else:
                c = pick(rmp, 0.55 + n + weave, x, y)
            t.set(x, y, c)
    grime(t, 0.3, 432, dark=0.6)
    return t


def stained_wood(rmp, seed, stains, burns=0):
    t = planks(rmp, 4, seed, nails=False, knots=1, var=0.1, grain=0.45)
    for i in range(stains):
        cx = hash01(i, 0, seed + 1) * S
        cy = hash01(i, 1, seed + 1) * S
        r = 2 + hash01(i, 2, seed + 1) * 4
        disc(t, int(cx), int(cy), r, lambda x, y, dx, dy: mix(t.get(x, y), (20, 14, 10), 0.45))
    for i in range(burns):
        cx = hash01(i, 0, seed + 2) * S
        cy = hash01(i, 1, seed + 2) * S
        disc(t, int(cx), int(cy), 2.5, lambda x, y, dx, dy: (12, 10, 8) if dx * dx + dy * dy < 3 else mix(t.get(x, y), (16, 12, 10), 0.6))
    return t


def lair_table():
    return stained_wood(WOOD, 441, 4)


def lair_lab_bench():
    rmp = ramp("201a14", "362c22", "4c4030", "62543e", "786a50")
    t = stained_wood(rmp, 451, 3, burns=4)
    acid = ramp("2e4a18", "4a7020")
    for i in range(3):
        cx = hash01(i, 0, 452) * S
        cy = hash01(i, 1, 452) * S
        disc(t, int(cx), int(cy), 3, lambda x, y, dx, dy: acid[(x + y) % 2] if bayer(x, y) < 0.6 else None)
    return t


def lair_feast():
    cloth = ramp("2a2c14", "40421e", "565a28", "6c7032", "84883e")
    t = canvas(cloth, 461, seams=False, stains=0.45)
    plate = ramp("2e2c2a", "56524c", "86827a", "aaa69c")
    meat = ramp("2a0e08", "4a1a10", "6a2c1a", "8a4426")
    rot = ramp("2a3410", "445218", "607028")
    bread = ramp("4a2c12", "7a4e22", "a87638")
    wine = ramp("1a040a", "3a0a14")
    items = [(14, 14, "plate"), (46, 18, "bread"), (30, 40, "plate"), (54, 50, "goblet"),
             (8, 46, "apples"), (40, 4, "goblet")]
    for i, (cx, cy, kind) in enumerate(items):
        if kind == "plate":
            disc(t, cx, cy, 8, lambda x, y, dx, dy: pick(plate, 0.75 - (dx + dy) * 0.03 if dx * dx + dy * dy > 30 else 0.4, x, y, 0.5))
            disc(t, cx, cy, 5, lambda x, y, dx, dy: pick(meat, 0.6 - (dx + dy) * 0.08, x, y) if hash01(x, y, 462) > 0.15 else rot[1])
            disc(t, cx + 2, cy + 1, 2.5, lambda x, y, dx, dy: pick(rot, 0.5 - (dx + dy) * 0.1, x, y))
        elif kind == "bread":
            disc(t, cx, cy, 6, lambda x, y, dx, dy: pick(bread, 0.7 - (dx + dy) * 0.07 - (0.3 if dx == 1 else 0), x, y, 0.5))
            disc(t, cx - 2, cy + 2, 2, lambda x, y, dx, dy: rot[0] if bayer(x, y) < 0.6 else None)
        elif kind == "goblet":
            disc(t, cx, cy, 4, lambda x, y, dx, dy: pick(GOLD, 0.75 - (dx + dy) * 0.08, x, y, 0.5))
            disc(t, cx, cy, 2.5, lambda x, y, dx, dy: wine[1] if dx + dy > -2 else wine[0])
        elif kind == "apples":
            for k, (ox, oy) in enumerate(((0, 0), (5, 2), (2, 5))):
                disc(t, cx + ox, cy + oy, 2.5, lambda x, y, dx, dy: pick(ramp("2a1a08", "4a3410", "605020"), 0.6 - (dx + dy) * 0.12, x, y))
    return t


def lair_potion():
    glass = ramp("082a10", "125020", "1e8a34", "3ac85a", "8af0a0", "e0ffe8")
    t = field(lambda x, y, ix, iy: 0.12 + (fbm(x, y, 4, seed=471) - 0.5) * 0.25, glass)
    for i in range(8):
        cx = 4 + (i % 4) * 16 + int(hash01(i, 0, 472) * 6)
        cy = 14 if i < 4 else 46
        r = 4 + hash01(i, 1, 472) * 2
        neck = int(r + 4)
        disc(t, cx, cy + 4, r, lambda x, y, dx, dy: pick(glass, 0.75 - (dx + dy) / (r * 3) + (0.25 if dx == -2 and dy == -2 else 0), x, y, 0.5))
        for k in range(neck):
            for w in (-1, 0, 1):
                t.set(cx + w, cy + 4 - int(r) - k, pick(glass, 0.6 - w * 0.2, cx + w, cy - k, 0.3))
        for w in (-2, -1, 0, 1, 2):
            t.set(cx + w, cy + 4 - int(r) - neck, (90, 60, 34))
    return t


# --- monastery ---------------------------------------------------------------

PALE_STONE = ramp("3a3630", "58524a", "766e62", "948a7c", "b0a696", "c8beac")


def monastery_wall():
    t, _ = masonry(PALE_STONE, ramp("2a2620", "36322a", "423c34"), 4, 2, 481, offset=0.5, var=0.12, rough=0.22)
    grime(t, 0.25, 482, dark=0.7, bottom_bias=0.5)
    scatter_cracks(t, 3, 483, PALE_STONE[0])
    return t


def monastery_floor():
    t = Tex()
    for y in range(S):
        for x in range(S):
            # Diagonal tile pattern in two stones.
            u, v = (x + y) % 32, (x - y) % 32
            rmp = PALE_STONE if ((x + y) // 32 + (x - y) // 32) % 2 == 0 else WARM_STONE
            val = 0.55 + (fbm(x + 0.5, y + 0.5, 8, seed=491) - 0.5) * 0.4
            if u == 0 or v == 0:
                t.set(x, y, MORTAR[1])
                continue
            if u == 1 or v == 1:
                val += 0.15
            t.set(x, y, pick(rmp, val, x, y))
    grime(t, 0.3, 492, dark=0.7)
    return t


def monastery_ceiling():
    t = planks(DARK_WOOD, 4, 501, nails=False)
    for y in range(S):
        for x in range(S):
            if (y % 32) < 6:
                v = (0.85, 0.65, 0.55, 0.5, 0.35, 0.1)[y % 32] + (fbm(x + 0.5, y + 0.5, 2, 16, seed=502) - 0.5) * 0.3
                t.set(x, y, pick(WOOD, v, x, y))
    return t


def monastery_pillar():
    t = fluted(PALE_STONE, 511, flutes=4)
    grime(t, 0.25, 512, dark=0.7, bottom_bias=0.6)
    return t


def monastery_altar():
    t = carved_panel(PALE_STONE, 521, border=3, inset=8)
    cloth = CLOTH_RED
    for y in range(0, 14):
        for x in range(S):
            v = 0.5 + (0.1 if (x + y) % 2 else 0) - (0.3 if y == 13 else 0)
            c = pick(cloth, v, x, y)
            if y in (10, 11):
                c = GOLD[3] if (x // 2) % 2 else GOLD[2]
            t.set(x, y, c)
    # A gold sunburst on the front.
    for a in range(16):
        ang = a / 16 * math.pi * 2
        for r in range(4, 12 if a % 2 else 9):
            x, y = 32 + math.cos(ang) * r, 38 + math.sin(ang) * r
            t.set(x, y, GOLD[3] if r < 8 else GOLD[2])
    disc(t, 32, 38, 3.5, lambda x, y, dx, dy: pick(GOLD, 0.8 - (dx + dy) * 0.1, x, y))
    return t


# --- mountain ----------------------------------------------------------------

MOUNTAIN = ramp("26282e", "3a3c44", "50525a", "686a72", "82848c", "9c9ea4")
SNOW = ramp("8a92a4", "a8b0c0", "c4cad6", "dce0ea", "f0f2f8")


def mountain_rock():
    t, _ = rock(MOUNTAIN, 4, 5, 531, crack=1.0, facet=0.5, var=0.2)
    # Snow caught on ledges: lit tops of chunks.
    for y in range(S):
        for x in range(S):
            f1, f2, cid, vec = voronoi(x + 0.5, y + 0.5, 4, 5, 531, 0.9)
            if vec[1] < -0.32 and f2 - f1 > 1.5 and hash01(cid, 3, 532) < 0.6:
                t.set(x, y, pick(SNOW, 0.5 + (fbm(x + 0.5, y + 0.5, 8, seed=533) - 0.5), x, y))
    return t


def mountain_snow():
    def fn(x, y, ix, iy):
        return 0.6 + (fbm(x, y, 4, octaves=4, seed=541) - 0.5) * 0.9

    t = field(fn, SNOW)
    speckle(t, [SNOW[-1]], 0.02, 542)
    return t


def mountain_gravestone():
    rmp = ramp("2e3036", "4a4c54", "666870", "84868c", "a2a4a8")
    t = carved_panel(rmp, 551, border=2, inset=6, rough=0.3)
    # Weathered inscription lines.
    for line_y in (20, 26, 32, 38):
        for x in range(14, 50):
            if hash01(x // 2, line_y, 552) < 0.7:
                t.tint(x, line_y, 0.65)
                t.tint(x, line_y + 1, 1.1)
    moss(t, ramp("2a3420", "3a4628", "4c5832"), 0.18, 553, px=3)
    grime(t, 0.3, 554, dark=0.65, bottom_bias=0.6)
    return t


def mountain_mausoleum():
    rmp = ramp("26282e", "3e4048", "565860", "6e7078", "888a90")
    t, _ = masonry(rmp, MORTAR, 2, 2, 561, offset=0.5, var=0.12, rough=0.25, mortar=1)
    scatter_cracks(t, 5, 562, rmp[0], (8, 18))
    moss(t, ramp("2a3420", "3a4628", "4c5832"), 0.12, 563, px=3)
    grime(t, 0.35, 564, dark=0.6, bottom_bias=0.6)
    return t


def mountain_grave_dirt():
    rmp = ramp("201a16", "302822", "40362c", "52463a", "645848")
    t = ground(rmp, 571, MOUNTAIN, 0.02)
    speckle(t, [SNOW[1], SNOW[2]], 0.01, 572)
    return t


# --- outpost -----------------------------------------------------------------

def outpost_anvil():
    t = metal_plate(IRON, 581, rough=0.3, scratches=14)
    for y in range(S):
        if y % 32 in (0, 1):
            for x in range(S):
                t.set(x, y, IRON[4] if y % 32 == 0 else IRON[0])
    return t


def outpost_bed():
    wool = ramp("2a241a", "433a2c", "5c503e", "766852", "8e8066")
    t = canvas(wool, 591, seams=False, stains=0.3)
    for y in range(S):
        for x in range(S):
            if (y // 4) % 4 == 0:
                t.blend(x, y, (90, 40, 30), 0.35)
    return t


def outpost_black_wax():
    rmp = ramp("060506", "100e10", "1c181c", "2c262c", "4a4048")

    def fn(x, y, ix, iy):
        n = fbm(x, y, 2, octaves=3, seed=601)
        return 0.3 + (n - 0.5) * 0.9

    t = field(fn, rmp)
    # Glossy highlights on the drips.
    for i in range(10):
        cx, cy = hash01(i, 0, 602) * S, hash01(i, 1, 602) * S
        t.set(cx, cy, rmp[-1])
        t.set(cx + 1, cy, rmp[-2])
    # Pressed seal ring.
    for a in range(48):
        ang = a / 48 * math.pi * 2
        t.set(32 + math.cos(ang) * 10, 32 + math.sin(ang) * 10, rmp[0])
        t.set(33 + math.cos(ang) * 10, 33 + math.sin(ang) * 10, rmp[3])
    return t


def outpost_forge():
    t, _ = masonry(WARM_STONE, MORTAR, 8, 4, 611, offset=None, var=0.2, rough=0.35, jagged=True)
    grime(t, 0.6, 612, dark=0.35, bottom_bias=-0.8)
    speckle(t, [EMBER[2], EMBER[3]], 0.006, 613)
    return t


def outpost_gate():
    face = planks(WOOD, 4, 621, vertical=True, nails=False, joints=1)
    return framed_door(face, IRON, 622, IRON, bands=(8, 40))


def outpost_gate_lintel():
    return logs(WOOD, 2, 631, vertical=False)


def outpost_mud():
    rmp = ramp("1e160e", "2e2216", "40301e", "524028", "665034")
    t = ground(rmp, 641, None, 0.0)
    # Puddles and ruts.
    for y in range(S):
        for x in range(S):
            n = fbm(x + 0.5, y + 0.5, 3, octaves=2, seed=642)
            if n > 0.68:
                t.set(x, y, pick(ramp("1a1a1e", "2a2a30", "3e3e46"), (n - 0.68) * 3, x, y))
            if abs(((x + 8) % 32) - 4) < 1 and n < 0.6:
                t.tint(x, y, 0.7)
    return t


def outpost_palisade():
    return logs(ramp("2a1a0e", "46301a", "644628", "805c36", "9c7446"), 4, 651, lash_rmp=ramp("3a3020", "5a4a30", "7a6644"))


def outpost_tower():
    return logs(ramp("261a10", "40301c", "5c4428", "785a34", "927042"), 4, 661, vertical=False,
                lash_rmp=ramp("3a3020", "5a4a30", "7a6644"))


def outpost_plank_floor():
    t = planks(ramp("221610", "38261a", "4e3624", "664830", "7c5a3c"), 4, 671, joints=2)
    grime(t, 0.35, 672, dark=0.6)
    return t


def outpost_plank_wall():
    t = planks(ramp("261a10", "3e2c1c", "564028", "6e5434", "866840"), 4, 681, vertical=True)
    grime(t, 0.25, 682, dark=0.65, bottom_bias=0.6)
    return t


def outpost_stone_floor():
    t, _ = rock(STONE, 6, 6, 691, crack=1.6, facet=0.3, var=0.15, jitter=0.6)
    grime(t, 0.3, 692, dark=0.6)
    return t


def outpost_straw():
    return straw(STRAW, 701, base_rmp=ramp("3a2c12", "4a3818", "5a4620"))


def outpost_thatch():
    rmp = ramp("1e180c", "322a14", "4a3e1e", "625428", "7a6a34")
    t = Tex()
    for y in range(S):
        row = y // 8
        for x in range(S):
            ly = y % 8
            n = fbm(x + 0.5, y + 0.5, 32, 2, octaves=2, seed=711 + row)
            v = 0.25 + (ly / 8) * 0.55 + (n - 0.5) * 0.7
            if ly == 7:
                v -= 0.3
            t.set(x, y, pick(rmp, v, x, y))
    grime(t, 0.3, 712, dark=0.6)
    return t


# --- ritual ------------------------------------------------------------------

def ritual_candle():
    wax = ramp("a07850", "c8a070", "e8c890", "f8e4b0", "fff6d8")

    def fn(x, y, ix, iy):
        drip = fbm(x, y, 8, 1, octaves=2, seed=721)
        return 0.55 + (drip - 0.5) * 0.9 + (0.15 if (ix % 16) < 3 else 0)

    t = field(fn, wax)
    for i in range(10):
        x = int(hash01(i, 0, 722) * S)
        y0 = int(hash01(i, 1, 722) * S)
        ln = 4 + int(hash01(i, 2, 722) * 10)
        for k in range(ln):
            t.set(x, y0 + k, wax[-1])
            t.set(x + 1, y0 + k, wax[2])
        t.set(x, y0 + ln, wax[3])
        t.set(x + 1, y0 + ln, wax[3])
    return t


def ritual_floor():
    rmp = ramp("1c0e0e", "2e1616", "422020", "562c2a", "6a3834")
    t, _ = masonry(rmp, ramp("100808", "180c0c", "201010"), 2, 2, 731, offset=0.5, var=0.12, rough=0.3)
    chalk = ramp("8a7a70", "b0a090", "d0c4b4")
    blood = BLOOD
    # Arcs of the summoning circle and a pentagram-free rune ring (the full
    # circle is drawn by tiling across several brushes).
    for a in range(256):
        ang = a / 256 * math.pi * 2
        for r, col in ((26, chalk), (22, blood)):
            x, y = 32 + math.cos(ang) * r, 32 + math.sin(ang) * r
            if hash01(a, r, 732) < 0.85:
                t.set(x, y, col[1])
    for i in range(12):
        ang = i / 12 * math.pi * 2
        cx, cy = 32 + math.cos(ang) * 24, 32 + math.sin(ang) * 24
        for k in range(3):
            t.set(cx + (k - 1), cy + (1 if i % 2 else -1) * (k - 1), chalk[2])
    for i in range(5):
        cx, cy = hash01(i, 0, 733) * S, hash01(i, 1, 733) * S
        disc(t, int(cx), int(cy), 2 + hash01(i, 2, 733) * 3, lambda x, y, dx, dy: blood[(x + y) % 2])
    return t


def ritual_portal_frame():
    rmp = ramp("08060a", "120e14", "1e1820", "2c2430", "3e3444")

    def fn(x, y, ix, iy):
        f1, f2, _, vec = voronoi(x, y, 3, 6, 741)
        return 0.45 - (vec[0] + vec[1]) * 0.6 + (fbm(x, y, 8, seed=742) - 0.5) * 0.3

    t = field(fn, rmp)
    glow = ramp("7a0a06", "c42010", "ff5a2a", "ffb080")
    for i in range(8):
        cy = 4 + i * 8
        cx = 32
        for k in range(5):
            r = hash01(i, k, 743)
            x = cx + int((r - 0.5) * 8)
            t.set(x, cy + k - 2, glow[1])
            t.set(x + 1, cy + k - 2, glow[2])
            if r > 0.7:
                t.set(x - 1, cy + k - 2, glow[3])
    return t


# --- town --------------------------------------------------------------------

ASH = ramp("1c1a1a", "2e2a28", "403c38", "54504a", "6a645c", "807a70")


def town_ash_ground():
    t = ground(ASH, 751, ASH, 0.02)
    speckle(t, [SOOT[0], SOOT[1]], 0.04, 752)
    speckle(t, [EMBER[1]], 0.002, 753)
    return t


def town_burnt_wall():
    t = planks(ramp("1c1410", "302218", "443024", "5a4030", "6e5240"), 4, 761, vertical=True)
    grime(t, 0.6, 762, dark=0.25, bottom_bias=-0.9)
    for y in range(S):
        for x in range(S):
            if fbm(x + 0.5, y + 0.5, 8, 2, octaves=2, seed=763) > 0.7:
                t.set(x, y, pick(SOOT, (x * 7 + y) % 4 / 3, x, y))
    return t


def town_charred_beam():
    rmp = SOOT + [ramp("403830")[0]]
    t = Tex()
    for y in range(S):
        for x in range(S):
            # Alligator-skin char: blocky cells with glowing seams here and there.
            f1, f2, cid, vec = voronoi(x + 0.5, y + 0.5, 8, 4, 771, 0.6)
            if f2 - f1 < 1.0:
                c = EMBER[1] if fbm(x + 0.5, y + 0.5, 4, seed=772) > 0.68 else rmp[0]
            else:
                c = pick(rmp, 0.6 - (vec[0] + vec[1]) * 0.6 + (hash01(cid, 0, 773) - 0.5) * 0.3, x, y)
            t.set(x, y, c)
    return t


def town_captain_body():
    tunic = ramp("2a0806", "48100c", "681a12", "88281a", "a63a26")

    def fn(x, y, ix, iy):
        folds = math.sin(x / S * math.pi * 4 + fbm(x, y, 2, 4, seed=781) * 4)
        return 0.5 + folds * 0.25 + (fbm(x, y, 8, seed=782) - 0.5) * 0.35 + (0.04 if (ix + iy) % 2 else 0)

    t = field(fn, tunic)
    # Mail showing at the hem and a belt, with dark blood soaked through.
    for y in range(40, 46):
        for x in range(S):
            t.set(x, y, pick(LEATHER_RMP, 0.6 - (0.3 if y == 45 else 0), x, y))
    for x in range(28, 36):
        for y in range(40, 46):
            t.set(x, y, pick(GOLD[:4], 0.6 if x in (28, 35) or y in (40, 45) else 0.2, x, y))
    for y in range(46, S):
        for x in range(S):
            if (x + y) % 2 == 0:
                t.set(x, y, pick(IRON, 0.6 - (y % 3) * 0.2, x, y))
    for y in range(S):
        for x in range(S):
            if fbm(x + 0.5, y + 0.5, 3, octaves=2, seed=783) > 0.62:
                t.set(x, y, pick(BLOOD, (x + y) % 3 / 2, x, y))
    return t


LEATHER_RMP = ramp("1e140c", "36241a", "4e3626", "664a34")


def town_embers():
    def fn(x, y, ix, iy):
        f1, f2, _, _ = voronoi(x, y, 8, 8, 791, 0.9)
        glow = clamp01(1 - f1 / 5)
        return 0.15 + glow * 0.6 + (fbm(x, y, 4, seed=792) - 0.5) * 0.6

    return field(fn, ramp("1a0804", "4a1006", "8a2008", "d04a10", "ff8a24", "ffd060"))


def town_well():
    t, _ = masonry(WARM_STONE, MORTAR, 8, 4, 801, offset=0.5, var=0.18, rough=0.3)
    moss(t, MOSS, 0.15, 802, px=3)
    grime(t, 0.3, 803, dark=0.6, bottom_bias=0.6)
    return t


# --- wood --------------------------------------------------------------------

def wood_planks():
    t = planks(ramp("24180e", "3a2818", "523a24", "6a4c30", "82603c"), 4, 811, joints=2)
    grime(t, 0.25, 812, dark=0.65)
    return t


def wood_crate():
    rmp = ramp("2e1e10", "4a321c", "664828", "825e34", "9c7442")
    t = planks(rmp, 4, 821, nails=False, knots=1)
    # Frame and diagonal brace, two crates per 2 m tile.
    for y in range(S):
        for x in range(S):
            lx, ly = x % 32, y % 32
            frame = lx < 4 or ly < 4 or lx > 27 or ly > 27
            brace = abs(lx - ly) < 3 and not frame
            if frame or brace:
                if frame:
                    d = min(lx, ly, 31 - lx, 31 - ly)
                    v = (0.85, 0.6, 0.5, 0.2)[min(d, 3)]
                else:
                    v = 0.75 if lx - ly == -2 else (0.2 if lx - ly == 2 else 0.55)
                v += (fbm(x + 0.5, y + 0.5, 2, 16, seed=822) - 0.5) * 0.3
                t.set(x, y, pick(rmp, v, x, y))
    for cy in (2, 29):
        for cx in (2, 29):
            for oy in (0, 32):
                for ox in (0, 32):
                    rivet(t, cx + ox, cy + oy, IRON)
    return t


def wood_cart():
    t = planks(ramp("26180e", "40281a", "5a3c24", "745030", "8c643e"), 4, 831, joints=1)
    for x in range(S):
        for y in (0, 1, 2):
            t.set(x, y + 30, pick(IRON, (0.8, 0.5, 0.15)[y], x, y))
    for x in range(4, S, 16):
        rivet(t, x, 31, IRON)
    grime(t, 0.4, 832, dark=0.55, bottom_bias=0.8)
    return t


def wood_door_tex():
    return wood_door()


def wood_fence():
    t = planks(ramp("2a2016", "403224", "584632", "6e5a42", "847052"), 4, 841, vertical=True, joints=1, var=0.2)
    moss(t, MOSS, 0.1, 842, px=3)
    grime(t, 0.35, 843, dark=0.6, bottom_bias=0.7)
    return t


def wood_grain_sack():
    rmp = ramp("4a3c24", "6a5636", "8a7448", "a68e5a", "c0a66c")

    def fn(x, y, ix, iy):
        weave = 0.12 if ((ix // 2) % 2) ^ ((iy // 2) % 2) else -0.08
        bulge = math.sin((x % 32) / 32 * math.pi) * math.sin((y % 32) / 32 * math.pi)
        return 0.25 + bulge * 0.55 + weave + (fbm(x, y, 8, seed=851) - 0.5) * 0.25

    t = field(fn, rmp)
    for y in range(S):
        for x in range(S):
            if y % 32 == 31 or x % 32 == 31:
                t.set(x, y, rmp[0])
    # Stencilled grain mark.
    for a in range(24):
        ang = a / 24 * math.pi * 2
        for oy in (0, 32):
            for ox in (0, 32):
                t.set(16 + ox + math.cos(ang) * 5, 16 + oy + math.sin(ang) * 5, (60, 30, 20))
    return t


def wood_strongbox():
    rmp = ramp("1a0e08", "2c1a10", "402818", "583820", "6e4a2c")
    t = planks(rmp, 4, 861, nails=False, knots=1)
    for y in range(S):
        for x in range(S):
            if x % 16 < 3:
                v = (0.85, 0.5, 0.15)[x % 16]
                t.set(x, y, pick(IRON, v + (fbm(x + 0.5, y + 0.5, 8, seed=862) - 0.5) * 0.3, x, y))
    for y in range(4, S, 8):
        for x in range(1, S, 16):
            rivet(t, x, y, IRON)
    # Lock plate.
    rect(t, 26, 22, 12, 14, lambda x, y, lx, ly: pick(IRON, 0.8 if lx == 0 or ly == 0 else (0.15 if lx == 11 or ly == 13 else 0.5), x, y))
    for y in range(26, 32):
        t.set(32, y, (6, 6, 8))
    t.set(31, 27, (6, 6, 8))
    t.set(33, 27, (6, 6, 8))
    return t


# --- registry ----------------------------------------------------------------

TEXTURES = {
    "base/wall": base_wall, "base/floor": base_floor, "base/ceiling": base_ceiling,
    "base/door": base_door, "base/door_gold": base_door_gold,
    "camp/bone_token": camp_bone_token, "camp/fire": camp_fire, "camp/ground": camp_ground,
    "camp/rug": camp_rug, "camp/tent": camp_tent, "camp/tent_inner": camp_tent_inner,
    "cave/ceiling": cave_ceiling, "cave/floor": cave_floor, "cave/floor_dirt": cave_floor_dirt,
    "cave/floor_straw": cave_floor_straw, "cave/rock": cave_rock,
    "crypt/ceiling": crypt_ceiling, "crypt/floor": crypt_floor, "crypt/pedestal": crypt_pedestal,
    "crypt/pillar": crypt_pillar, "crypt/robe": crypt_robe, "crypt/tomb": crypt_tomb,
    "crypt/wall": crypt_wall,
    "door/bone_gate": bone_gate, "door/gold": gold_door, "door/hell": hell_door,
    "door/silver": silver_door,
    "forest/cliff": forest_cliff, "forest/cliff_night": forest_cliff_night,
    "forest/ground": forest_ground, "forest/ground_night": forest_ground_night,
    "forest/tree": forest_tree, "gold/coins": gold_coins,
    "hell/cage": hell_cage, "hell/ceiling": hell_ceiling, "hell/demon_shape": hell_demon_shape,
    "hell/fortress_floor": hell_fortress_floor, "hell/fortress_wall": hell_fortress_wall,
    "hell/ground": hell_ground, "hell/lava": hell_lava, "hell/pillar": hell_pillar,
    "hell/railing": hell_railing, "hell/rock": hell_rock,
    "lair/bookshelf": lair_bookshelf, "lair/carpet": lair_carpet, "lair/ceiling": lair_ceiling,
    "lair/feast": lair_feast, "lair/floor": lair_floor, "lair/lab_bench": lair_lab_bench,
    "lair/potion": lair_potion, "lair/table": lair_table, "lair/wall": lair_wall,
    "monastery/altar": monastery_altar, "monastery/ceiling": monastery_ceiling,
    "monastery/floor": monastery_floor, "monastery/pillar": monastery_pillar,
    "monastery/wall": monastery_wall,
    "mountain/grave_dirt": mountain_grave_dirt, "mountain/gravestone": mountain_gravestone,
    "mountain/mausoleum": mountain_mausoleum, "mountain/rock": mountain_rock,
    "mountain/snow": mountain_snow,
    "outpost/anvil": outpost_anvil, "outpost/bed": outpost_bed, "outpost/black_wax": outpost_black_wax,
    "outpost/forge": outpost_forge, "outpost/gate": outpost_gate, "outpost/gate_lintel": outpost_gate_lintel,
    "outpost/mud": outpost_mud, "outpost/palisade": outpost_palisade,
    "outpost/plank_floor": outpost_plank_floor, "outpost/plank_wall": outpost_plank_wall,
    "outpost/stone_floor": outpost_stone_floor, "outpost/straw": outpost_straw,
    "outpost/thatch": outpost_thatch, "outpost/tower": outpost_tower,
    "ritual/candle": ritual_candle, "ritual/floor": ritual_floor, "ritual/portal_frame": ritual_portal_frame,
    "town/ash_ground": town_ash_ground, "town/burnt_wall": town_burnt_wall,
    "town/captain_body": town_captain_body, "town/charred_beam": town_charred_beam,
    "town/embers": town_embers, "town/well": town_well,
    "wood/cart": wood_cart, "wood/crate": wood_crate, "wood/door": wood_door_tex,
    "wood/fence": wood_fence, "wood/grain_sack": wood_grain_sack, "wood/planks": wood_planks,
    "wood/strongbox": wood_strongbox,
}


def grey_for(name, tex):
    """Grey albedo multiplier that restores the brightness the level had."""
    if name in UNSHADED or name not in OLD_TINTS:
        return 1.0
    target = lum(tuple(v * 255 for v in OLD_TINTS[name])) * CHECKER_LUMA * BRIGHTNESS
    have = lum(tex.average())
    return max(0.05, min(1.0, target / max(0.01, have)))


EXT_RE = re.compile(r'(\[ext_resource type="Texture2D" path=")[^"]*(" id="1_tex"\])')
COLOR_RE = re.compile(r"^albedo_color = Color\([^)]*\)$", re.M)


def update_material(name, grey):
    path = os.path.join(TEX_DIR, *name.split("/")) + ".tres"
    if not os.path.exists(path):
        return False
    with open(path, encoding="utf-8") as f:
        text = f.read()
    new = EXT_RE.sub(r"\g<1>res://assets/textures/%s.png\g<2>" % name, text)
    g = "%.3g" % grey
    color = "albedo_color = Color(%s, %s, %s, 1)" % (g, g, g)
    new = COLOR_RE.sub(color, new)
    if new != text:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(new)
    return True


def main():
    preview_dir = sys.argv[1] if len(sys.argv) > 1 else None
    named = []
    for name, fn in TEXTURES.items():
        tex = fn()
        out = os.path.join(TEX_DIR, *name.split("/")) + ".png"
        os.makedirs(os.path.dirname(out), exist_ok=True)
        tex.save(out)
        grey = grey_for(name, tex)
        had_mat = update_material(name, grey)
        named.append((name, tex))
        print("%-24s grey %.3f%s" % (name, grey, "" if had_mat else "  (no .tres: FuncGodot default material)"))
    if preview_dir:
        os.makedirs(preview_dir, exist_ok=True)
        save_preview(os.path.join(preview_dir, "textures_contact_sheet.png"), named)
        with open(os.path.join(preview_dir, "textures_contact_sheet.txt"), "w") as f:
            for i, (name, _) in enumerate(named):
                f.write("%2d (row %d, col %d) %s\n" % (i, i // 8 + 1, i % 8 + 1, name))


if __name__ == "__main__":
    main()
