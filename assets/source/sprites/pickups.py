"""Generates the weapon, health, ammo and key pickup sprites.

Weapons are 64x32 (the pickup quad is 0.7 x 0.35 m), lying on their side
as if dropped on the floor. Health, ammo and keys are 32x32 (0.3 m quads,
0.35 m for keys). Each
sprite is its own PNG under assets/sprites/pickups/.

Run from the project root:
    python assets/source/sprites/pickups.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import math
import os
import sys

from pixel_canvas import Canvas, add, hash01, mul, write_png
from sheet_tools import line, orb

OUTLINE = (14, 10, 12, 255)

WOOD = ((70, 42, 22, 255), (112, 70, 36, 255), (150, 100, 56, 255))
DARK_WOOD = ((40, 24, 16, 255), (66, 42, 26, 255), (96, 64, 40, 255))
PALE_WOOD = ((150, 128, 96, 255), (196, 176, 140, 255), (230, 216, 186, 255))
LEATHER = ((50, 30, 20, 255), (84, 52, 32, 255), (112, 74, 46, 255))
IRON = ((60, 62, 70, 255), (110, 114, 124, 255), (176, 180, 190, 255))
STEEL_EDGE = (214, 218, 226, 255)
SILVER = ((120, 124, 134, 255), (180, 184, 194, 255), (236, 238, 244, 255))
GOLD = ((130, 86, 20, 255), (200, 150, 40, 255), (250, 214, 100, 255))
STRING = (210, 200, 170, 255)
FIRE = ((150, 40, 10, 255), (230, 100, 20, 255), (255, 180, 60, 255), (255, 240, 180, 255))
FROST = ((60, 100, 180, 255), (120, 170, 240, 255), (190, 220, 255, 255), (245, 250, 255, 255))
VERDANT = ((20, 110, 40, 255), (60, 190, 80, 255), (150, 245, 150, 255), (235, 255, 235, 255))
CRYSTAL = ((70, 110, 170, 255), (150, 190, 235, 255), (215, 235, 255, 255))
SPARK = (250, 252, 255, 255)
GLASS = ((120, 140, 150, 255), (170, 190, 200, 255), (230, 240, 245, 255))
CORK = ((90, 60, 34, 255), (140, 100, 60, 255), (180, 140, 90, 255))
DRAUGHT = ((150, 40, 44, 255), (220, 90, 90, 255), (255, 160, 150, 255))
POTION = ((70, 4, 12, 255), (140, 10, 24, 255), (200, 40, 50, 255))


def shaded_line(c, a, b, r, ramp, tag=None):
    """Haft or limb: dark edge, mid body, a lit stripe on the upper side."""
    dark, mid, light = ramp
    c.capsule(a, b, r, dark, tag)
    c.capsule(add(a, (0, -r * 0.3)), add(b, (0, -r * 0.3)), r * 0.65, mid, tag)
    if r >= 1.4:
        line(c, add(a, (0, -r * 0.55)), add(b, (0, -r * 0.55)), light, tag)


def bands(c, a, b, ts, color):
    """Metal or leather wraps across a haft at fractions ts along a->b."""
    for t in ts:
        p = add(a, mul((b[0] - a[0], b[1] - a[1]), t))
        c.capsule(add(p, (-0.5, -1.6)), add(p, (0.5, 1.6)), 0.9, color)


def bow():
    c = Canvas(64, 32)
    # Lying flat: limbs arch upward, string runs straight underneath.
    tips = ((6, 23), (58, 23))
    line(c, tips[0], tips[1], STRING, "noline")
    pts = []
    for i in range(25):
        t = i / 24
        x = 6 + 52 * t
        y = 23 - 15 * math.sin(math.pi * t) + 3 * math.sin(math.pi * t) ** 6
        pts.append((x, y))
    for a, b in zip(pts, pts[1:]):
        c.capsule(a, b, 1.8, WOOD[0])
    for a, b in zip(pts, pts[1:]):
        c.capsule(add(a, (0, -0.4)), add(b, (0, -0.4)), 1.0, WOOD[1])
    for a, b in zip(pts[2:-2], pts[3:-2]):
        line(c, add(a, (0, -1.3)), add(b, (0, -1.3)), WOOD[2])
    # Leather grip at the middle of the arch.
    c.capsule((28, 10), (36, 10), 2.4, LEATHER[0])
    c.capsule((28, 9.5), (36, 9.5), 1.5, LEATHER[1])
    for x in (29, 31, 33, 35):
        c.set(x, 9, LEATHER[2])
    # Horn nocks on the tips.
    for t in tips:
        c.circle(t, 1.6, PALE_WOOD[1])
    # An arrow laid across it, fletching to the left.
    a, b = (12, 27), (54, 18)
    shaded_line(c, a, b, 0.8, PALE_WOOD)
    c.polygon([(53, 16), (59, 16.8), (55, 21)], IRON[1])
    c.set(55, 17, IRON[2])
    c.polygon([(10, 25), (16, 22.6), (17, 25.5), (12, 28)], (170, 30, 30, 255))
    c.polygon([(11, 28.5), (16, 26.6), (17, 28), (12, 30)], (220, 220, 210, 255))
    c.outline(OUTLINE)
    return c


def francisca():
    c = Canvas(64, 32)
    # A short throwing axe, head up-right.
    for off, ramp in (((-2, 1), WOOD),):
        a = add((8, 28), off)
        b = add((44, 11), off)
        shaded_line(c, a, b, 1.6, ramp)
        bands(c, a, b, (0.08, 0.16), LEATHER[1])
        # Bearded head: thin at the haft, curving down into a wide edge.
        h = add((44, 11), off)
        head = [add(h, p) for p in ((-3, -3), (4, -6), (9, -7), (12, -4), (13, 2),
                                    (11, 8), (7, 10), (5, 5), (1, 3), (-3, 3))]
        c.polygon(head, IRON[1])
        c.polygon([add(h, p) for p in ((-2, -2), (4, -5), (8, -6), (4, -2), (0, 0))], IRON[2])
        c.polygon([add(h, p) for p in ((5, 3), (9, 0), (11, 4), (9, 8), (7, 8))], IRON[0])
        for p in ((12, -4), (13, -1), (13, 2), (12, 5), (11, 8)):
            c.set(*add(h, p), STEEL_EDGE)
        c.outline(OUTLINE)
    return c


def warhammer():
    c = Canvas(64, 32)
    a, b = (4, 26), (48, 13)
    shaded_line(c, a, b, 1.8, DARK_WOOD)
    bands(c, a, b, (0.04, 0.1, 0.16), LEATHER[2])
    c.capsule(add(a, (-1, 0.3)), add(a, (0.5, 0)), 2.2, IRON[0])
    # Iron head, set across the haft's end; flat face down, spike up.
    h = (49, 13)
    face = [add(h, p) for p in ((-5, -10), (5, -12), (8, 7), (-2, 9))]
    c.polygon(face, IRON[0])
    c.polygon([add(h, p) for p in ((-4, -9), (3, -10.5), (5, 5), (-1, 6))], IRON[1])
    c.polygon([add(h, p) for p in ((-4, -9), (0, -10), (2, 4), (-1, 5))], IRON[2])
    c.polygon([add(h, p) for p in ((5, -2), (14, -5), (6, 2))], IRON[1])
    c.set(*add(h, (12, -4)), STEEL_EDGE)
    for p in ((-4, -7), (2, -8), (0, 4)):
        c.set(*add(h, p), IRON[0])
    c.outline(OUTLINE)
    return c


def staff_with_orb(ramp_wood, orb_ramp, tag_seed, claws=True):
    c = Canvas(64, 32)
    a, b = (3, 27), (50, 13)
    shaded_line(c, a, b, 1.6, ramp_wood)
    # Knots along the gnarled shaft.
    for t in (0.25, 0.5, 0.7):
        p = add(a, mul((b[0] - a[0], b[1] - a[1]), t))
        c.circle(add(p, (0, 0.5)), 1.9, ramp_wood[0])
        c.set(p[0], p[1] - 1, ramp_wood[2])
    centre = (55, 11)
    glow = orb_ramp[0][:3] + (255,)
    c.circle(centre, 7.2, glow, "noline")
    orb(c, centre, 6.2, orb_ramp)
    if claws:
        # Wooden prongs curling round the orb.
        for tip in ((50, 3), (61, 4), (61, 18)):
            c.capsule((50, 13), tip, 1.1, ramp_wood[0])
            c.set(tip[0], tip[1], ramp_wood[2])
    for i in range(6):
        ang = hash01(i, 1, tag_seed) * math.tau
        d = 7.5 + hash01(i, 2, tag_seed) * 3
        c.set(centre[0] + math.cos(ang) * d, centre[1] + math.sin(ang) * d,
              orb_ramp[-1], "noline")
    c.outline(OUTLINE)
    return c


def fire_staff():
    c = staff_with_orb(WOOD, FIRE, 3)
    # Flame licking up out of the orb.
    for i, (x, h) in enumerate(((52, 4), (55, 6), (58, 4))):
        c.polygon([(x - 1.5, 7), (x + 1.5, 7), (x + 0.5, 7 - h)], FIRE[2 + i % 2], "noline")
    return c


def wand(tip_ramp, body_ramp, band_ramp, seed):
    c = Canvas(64, 32)
    a, b = (14, 24), (46, 12)
    shaded_line(c, a, b, 1.3, body_ramp)
    # Pommel and silver bands.
    c.circle(add(a, (-1, 0.5)), 2.2, band_ramp[1])
    c.set(a[0] - 2, a[1] - 1, band_ramp[2])
    bands(c, a, b, (0.18, 0.3, 0.86), band_ramp[1])
    c.outline(OUTLINE)
    tip = (49, 11)
    c.circle(tip, 4.4, tip_ramp[0][:3] + (255,), "noline")
    orb(c, tip, 3.4, tip_ramp)
    # A few motes drifting off the tip.
    for i in range(5):
        ang = -math.pi * (0.1 + 0.8 * hash01(i, 1, seed))
        d = 5.5 + hash01(i, 2, seed) * 4
        c.set(tip[0] + math.cos(ang) * d, tip[1] + math.sin(ang) * d, tip_ramp[-1], "noline")
    return c


def magic_wand():
    return wand(FROST, DARK_WOOD, SILVER, 5)


def healing_wand():
    return wand(VERDANT, PALE_WOOD, GOLD, 9)


def lightning():
    c = Canvas(64, 32)
    # A jagged shard of pale crystal lying on its side.
    shard = [(6, 20), (14, 13), (26, 10), (40, 7), (54, 9), (60, 14), (52, 19),
             (40, 24), (26, 25), (14, 25)]
    c.polygon(shard, CRYSTAL[1])
    c.polygon([(8, 19), (14, 14), (26, 11), (40, 8), (54, 10), (40, 14), (26, 17), (14, 19)],
              CRYSTAL[2])
    c.polygon([(14, 25), (26, 25), (40, 24), (52, 19), (40, 21), (26, 22)], CRYSTAL[0])
    # Facet lines.
    for a, b in (((26, 11), (28, 24)), ((40, 8), (38, 23)), ((14, 14), (16, 24))):
        line(c, a, b, CRYSTAL[0])
    c.outline((20, 30, 60, 255))
    # Crackle running through and out of it.
    bolt = [(4, 14), (12, 17), (18, 13), (27, 16), (34, 12), (44, 15), (50, 11), (58, 13), (63, 9)]
    for a, b in zip(bolt, bolt[1:]):
        line(c, a, b, SPARK, "noline")
    for p in ((2, 18), (61, 4), (62, 18), (33, 4), (20, 28)):
        c.set(*p, SPARK, "noline")
    return c


def armor_spell():
    c = Canvas(64, 32)
    # Chain looping up from the amulet.
    for i in range(18):
        t = i / 17
        ang = math.pi * (1.05 + 0.9 * t)
        p = (32 + math.cos(ang) * 14, 15 + math.sin(ang) * 11)
        c.set(*p, GOLD[1] if i % 2 else GOLD[0])
    centre = (32, 19)
    c.circle(centre, 9.5, IRON[0])
    c.circle(add(centre, (-0.6, -0.6)), 8.3, IRON[1])
    c.circle(add(centre, (-0.6, -0.6)), 7.0, GOLD[1])
    c.circle(add(centre, (-0.6, -0.6)), 5.6, IRON[1])
    # Rune ticks round the rim.
    for k in range(8):
        ang = k * math.tau / 8
        c.set(centre[0] + math.cos(ang) * 6.6, centre[1] + math.sin(ang) * 6.6, GOLD[2])
    c.circle(centre, 3.4, GOLD[0])
    c.circle(add(centre, (-0.5, -0.5)), 2.6, GOLD[1])
    c.circle(add(centre, (-1, -1)), 1.2, GOLD[2])
    c.set(centre[0] - 1.5, centre[1] - 1.5, (255, 250, 220, 255))
    c.outline(OUTLINE)
    return c


def flask(body_r, neck_w, liquid, fill_top):
    """Round-bottomed glass flask; liquid fills from fill_top downward."""
    c = Canvas(32, 32)
    centre = (16, 31 - body_r - 1)
    neck_top = centre[1] - body_r - 6
    # Glass first, then liquid inside it, then highlights.
    c.circle(centre, body_r, GLASS[0])
    c.polygon([(16 - neck_w, neck_top), (16 + neck_w, neck_top),
               (16 + neck_w, centre[1]), (16 - neck_w, centre[1])], GLASS[0])
    for y in range(32):
        for x in range(32):
            if (x + 0.5 - centre[0]) ** 2 + (y + 0.5 - centre[1]) ** 2 <= (body_r - 1) ** 2 \
                    and y >= fill_top:
                shade = liquid[0] if x > 18 or y > centre[1] + body_r * 0.55 else liquid[1]
                if x < 13 and y < centre[1]:
                    shade = liquid[2]
                c.set(x, y, shade)
    # Surface line and glints.
    for x in range(32):
        if c.px[fill_top][x] in liquid:
            c.set(x, fill_top, liquid[2])
    c.capsule((centre[0] - body_r * 0.55, centre[1] - body_r * 0.35),
              (centre[0] - body_r * 0.35, centre[1] - body_r * 0.6), 0.8, GLASS[2], "noline")
    # Lip and cork.
    c.capsule((16 - neck_w - 1, neck_top), (16 + neck_w + 1, neck_top), 1.0, GLASS[1])
    c.polygon([(16 - neck_w + 0.5, neck_top - 4), (16 + neck_w - 0.5, neck_top - 4),
               (16 + neck_w - 0.5, neck_top), (16 - neck_w + 0.5, neck_top)], CORK[1])
    c.set(16 - neck_w + 1, neck_top - 3, CORK[2])
    c.set(16 + neck_w - 1, neck_top - 1, CORK[0])
    c.outline(OUTLINE)
    return c


def health_small():
    return flask(7, 2, DRAUGHT, 18)


def health_large():
    c = flask(11, 3, POTION, 12)
    # Twine wrapped round the neck and a wax seal tag.
    for x in range(13, 20):
        c.set(x, 8, (190, 170, 120, 255) if x % 2 else (140, 120, 80, 255))
    c.capsule((20, 9), (22, 13), 0.9, (190, 170, 120, 255))
    c.circle((22, 14), 1.6, (60, 6, 8, 255))
    return c


FLETCH = ((120, 20, 20, 255), (170, 30, 30, 255), (220, 220, 210, 255))
TWINE = ((140, 120, 80, 255), (190, 170, 120, 255))
MANA = ((30, 50, 140, 255), (60, 110, 220, 255), (140, 190, 255, 255), (235, 245, 255, 255))
BONE = ((150, 140, 110, 255), (206, 198, 170, 255), (240, 234, 214, 255))


def ammo_arrows():
    c = Canvas(32, 32)
    # A bundle of three arrows, heads up-right, fanned slightly and tied.
    for i, (off, fan) in enumerate((((-2.6, -2.6), -2), ((0, 0), 0), ((2.6, 2.6), 2))):
        a = add((7, 26), off)
        b = add((23 - fan, 9 + fan), off)
        line(c, a, b, PALE_WOOD[0])
        line(c, add(a, (0, -1)), add(b, (0, -1)), PALE_WOOD[1])
        # Broad iron head.
        c.polygon([add(b, (-2, -1)), add(b, (1, 2)), add(b, (3, -3))], IRON[1])
        c.set(*add(b, (1, -1)), IRON[2])
        # Red-and-white vanes either side of the nock.
        vane = FLETCH[1] if i != 1 else FLETCH[2]
        c.polygon([add(a, (-1, -1)), add(a, (3, -5)), add(a, (4, -3)), add(a, (1, 0))], vane)
        c.polygon([add(a, (1, 1)), add(a, (5, -3)), add(a, (6, -1)), add(a, (2, 2))], FLETCH[0])
    for k in range(-4, 5):
        c.set(14 + k * 0.75, 17 + k * 0.75, TWINE[k % 2])
        c.set(15 + k * 0.75, 17 + k * 0.75, TWINE[1 - k % 2])
    c.outline(OUTLINE)
    return c


def ammo_axes():
    c = Canvas(32, 32)
    # Two small franciscas crossed, heads at the top.
    for flip in (1, -1):
        def m(p):
            return (16 + (p[0] - 16) * flip, p[1])
        a, b = m((5, 29)), m((22, 8))
        shaded_line(c, a, b, 1.2, WOOD)
        h = b
        pts = ((-2, -2), (2, -4), (6, -5), (8, -2), (8, 2), (6, 6), (4, 3), (0, 2))
        c.polygon([add(h, (p[0] * flip, p[1])) for p in pts], IRON[1])
        c.polygon([add(h, (p[0] * flip, p[1])) for p in ((-1, -1), (2, -3), (5, -4), (2, -1))],
                  IRON[2])
        for p in ((8, -2), (8, 0), (8, 2)):
            c.set(*add(h, (p[0] * flip - (1 if flip < 0 else 0), p[1])), STEEL_EDGE)
    c.outline(OUTLINE)
    return c


def ammo_mana():
    c = Canvas(32, 32)
    # A standing crystal with a smaller one leaning on it.
    small = [(19, 29), (21, 19), (25, 17), (26, 22), (24, 29)]
    c.polygon(small, MANA[0])
    c.polygon([(21, 28), (22, 20), (25, 18), (23, 24)], MANA[1])
    big = [(10, 29), (9, 12), (16, 3), (22, 12), (21, 29)]
    c.polygon(big, MANA[1])
    c.polygon([(10, 28), (10, 12), (16, 4), (14, 13), (14, 28)], MANA[2])
    c.polygon([(18, 28), (18, 13), (16, 4), (22, 12), (21, 28)], MANA[0])
    line(c, (16, 5), (15, 26), MANA[3])
    c.outline((10, 16, 50, 255))
    for p in ((5, 8), (27, 6), (4, 20), (28, 13), (12, 2)):
        c.set(*p, MANA[3], "noline")
    return c


def key(ramp, ornament):
    """Upright key: bow (handle) on top, bit at the bottom."""
    c = Canvas(32, 32)
    # Bow ring.
    c.circle((16, 9), 6.5, ramp[0])
    c.circle((15.5, 8.5), 5.3, ramp[1])
    c.circle((15, 8), 3.6, ramp[2])
    c.circle((16, 9), 3.0, None)
    c.circle((16, 9), 2.0, None)
    # Shaft and collar.
    c.capsule((16, 15), (16, 28), 1.6, ramp[0])
    c.capsule((15.6, 15), (15.6, 28), 0.9, ramp[1])
    line(c, (15, 16), (15, 27), ramp[2])
    c.capsule((13, 17), (19, 17), 1.0, ramp[1])
    # Bit: two teeth sticking out to the right.
    c.polygon([(17, 23), (22, 23), (22, 29), (20, 29), (20, 27), (17, 27)], ramp[1])
    c.polygon([(17, 23), (22, 23), (22, 24), (17, 24)], ramp[2])
    ornament(c)
    c.outline(OUTLINE)
    return c


def key_gold():
    def ornament(c):
        c.circle((16, 3), 1.6, GOLD[2])
        c.set(16, 3, (200, 30, 30, 255))
    return key(GOLD, ornament)


def key_silver():
    def ornament(c):
        for p in ((10, 9), (22, 9), (16, 3)):
            c.circle(p, 1.3, SILVER[2])
    return key(SILVER, ornament)


def key_bone():
    def ornament(c):
        # Skull for a bow: eye sockets and teeth punched into the ring.
        c.circle((16, 9), 3.0, BONE[1])
        c.set(14, 8, OUTLINE)
        c.set(18, 8, OUTLINE)
        c.set(16, 10, BONE[0])
        for x in (14, 16, 18):
            c.set(x, 12, BONE[0])
        # Knuckle where the shaft joins, like the end of a bone.
        c.circle((15, 28), 1.8, BONE[1])
        c.circle((17.5, 28.5), 1.6, BONE[0])
    return key(BONE, ornament)


SPRITES = {
    "weapon_bow": bow,
    "weapon_francisca": francisca,
    "weapon_warhammer": warhammer,
    "weapon_fire_staff": fire_staff,
    "weapon_magic_wand": magic_wand,
    "weapon_healing_wand": healing_wand,
    "weapon_lightning": lightning,
    "weapon_armor_spell": armor_spell,
    "health_small": health_small,
    "health_large": health_large,
    "ammo_arrows": ammo_arrows,
    "ammo_axes": ammo_axes,
    "ammo_mana": ammo_mana,
    "key_gold": key_gold,
    "key_silver": key_silver,
    "key_bone": key_bone,
}


def main(preview_dir=None):
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(os.path.dirname(here)))
    out_dir = os.path.join(root, "assets", "sprites", "pickups")
    os.makedirs(out_dir, exist_ok=True)
    canvases = {}
    for name, make in SPRITES.items():
        c = make()
        canvases[name] = c
        write_png(os.path.join(out_dir, name + ".png"), c.w, c.h, c.px)
    if preview_dir:
        # Every sprite at 6x on a grey strip, one per row.
        scale, pad = 6, 4
        bg = (70, 70, 74, 255)
        width = 64 * scale + pad * 2
        rows = []
        for c in canvases.values():
            rows.extend([[bg] * width for _ in range(pad)])
            for y in range(c.h):
                row = [bg] * pad
                for px in c.px[y]:
                    row.extend([px or bg] * scale)
                row.extend([bg] * (width - len(row)))
                rows.extend([row] * scale)
        rows.extend([[bg] * width for _ in range(pad)])
        write_png(os.path.join(preview_dir, "pickups_preview.png"), width, len(rows), rows)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
