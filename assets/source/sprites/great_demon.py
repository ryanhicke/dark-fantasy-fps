"""Generates the great demon sprite sheet (front-facing only).

A towering grey rock demon split by cracks that glow yellow from within,
with burning eyes and maw, wearing a broken golden crown. One frame = 6 m
(quad 6x6, origin at the bottom edge).

The scene's four Crack quads (the obelisk "cracks of light") sit at fixed
spots on the sprite, so the body is laid out to put them on the torso and
right thigh: Crack1 ~(51, 38), Crack2 ~(79, 55), Crack3 ~(58, 79),
Crack4 ~(73, 98) in frame pixels.

It never moves, so the "walk" frames are a breathing loop with pulsing
cracks. It dies by crumbling into a heap of rubble.

Run from the project root:
    python assets/source/sprites/great_demon.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import math
import sys

from sheet_tools import (Canvas, add, hash01, mul, norm, rotate, sub, axes, flames, orb, shifted,
                         save_sheet, GROUND)

OUTLINE = (12, 10, 10, 255)
ROCK = ((50, 50, 55, 255), (88, 86, 90, 255), (128, 124, 126, 255))
SEAM = (30, 28, 32, 255)
GLOW = ((150, 80, 10, 255), (240, 170, 30, 255), (255, 236, 140, 255))
GLOW_DIM = ((70, 44, 16, 255), (120, 80, 24, 255), (150, 110, 40, 255))
GOLD = ((120, 84, 20, 255), (196, 150, 46, 255), (244, 214, 110, 255))
FIRE = ((150, 30, 8, 255), (230, 92, 20, 255), (255, 172, 44, 255), (255, 242, 176, 255))

BASE = {
    "head": (64, 17), "neck": (64, 27),
    "sL": (38, 33), "sR": (90, 33),
    "eL": (26, 58), "eR": (102, 58),
    "hL": (24, 84), "hR": (104, 84),
    "pL": (53, 80), "pR": (75, 80),
    "kL": (49, 103), "kR": (79, 103),
    "fL": (47, 121), "fR": (81, 121),
}
UPPER = ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR")


def pose(**overrides):
    p = dict(BASE)
    p.update(glow=1.0, maw=2, blast=None, crumble=0)
    p.update(overrides)
    return p


def breathe(phase):
    rise = (0, -1, -2, -1)[phase]
    p = shifted(pose(glow=(0.8, 0.95, 1.0, 0.9)[phase]), 0, rise, UPPER)
    return p


POSES = [
    pose(),
    breathe(0), breathe(1), breathe(2), breathe(3),
    # windup: arms spread, fire gathering in its open maw
    shifted(pose(eL=(18, 40), hL=(10, 22), eR=(110, 40), hR=(118, 22), maw=5, blast=((64, 26), 5)),
            0, -1, UPPER),
    # attack: the fireball bursts from its jaws
    pose(eL=(22, 50), hL=(18, 70), eR=(106, 50), hR=(110, 70), maw=6, blast=((64, 28), 9)),
    # pain: rocked back, cracks flaring
    shifted(pose(head=(70, 19), eL=(20, 52), hL=(14, 70), eR=(106, 56), hR=(112, 74), maw=4, glow=1.2),
            2, 0, UPPER),
    # death: roaring, light pouring out of every crack
    shifted(pose(head=(64, 14), eL=(16, 36), hL=(8, 18), eR=(112, 36), hR=(120, 18), maw=6, glow=1.4),
            0, 0, UPPER),
    # death: splitting apart, chunks falling
    pose(crumble=1, glow=0.9),
    pose(crumble=2, glow=0.6),
    # corpse: a heap of dark rubble with the crown on top
    pose(crumble=3, glow=0.3),
]


def glow_ramp(level):
    return GLOW if level >= 0.75 else GLOW_DIM


def rock_capsule(c, a, b, r, color):
    """A capsule painted only onto rock, so cracks never hang in the air
    when a limb has moved away from where they run."""
    ab = sub(b, a)
    ab2 = ab[0] ** 2 + ab[1] ** 2 or 1e-9
    for y in range(max(0, int(min(a[1], b[1]) - r) - 1), min(c.h, int(max(a[1], b[1]) + r) + 2)):
        for x in range(max(0, int(min(a[0], b[0]) - r) - 1), min(c.w, int(max(a[0], b[0]) + r) + 2)):
            if c.tag[y][x] != "rock":
                continue
            t = max(0.0, min(1.0, ((x + 0.5 - a[0]) * ab[0] + (y + 0.5 - a[1]) * ab[1]) / ab2))
            dx = x + 0.5 - (a[0] + ab[0] * t)
            dy = y + 0.5 - (a[1] + ab[1] * t)
            if dx * dx + dy * dy <= r * r:
                c.px[y][x] = color


def crack(c, start, direction, length, seed, level, width=1.0):
    """A jagged glowing crack: hot core, darker rim."""
    if level <= 0.05:
        return
    ramp = glow_ramp(level)
    d = norm(direction)
    pts = [start]
    for i in range(1, 7):
        t = i / 6
        jitter = (hash01(i, seed, 3) - 0.5) * 6
        base = add(start, mul(d, length * t))
        pts.append(add(base, mul((-d[1], d[0]), jitter)))
    for a, b in zip(pts, pts[1:]):
        rock_capsule(c, a, b, 1.2 * width, ramp[0])
    for a, b in zip(pts, pts[1:]):
        rock_capsule(c, a, b, 0.6 * width, ramp[1] if level < 1.1 else ramp[2])


def rock_texture(c):
    """Breaks the fills into faceted slabs: jittered-grid Voronoi seams,
    with every few slabs a shade lighter or darker."""
    cell = 9
    for y in range(c.h):
        for x in range(c.w):
            if c.tag[y][x] != "rock":
                continue
            gx, gy = x // cell, y // cell
            best = second = 1e9
            best_id = (0, 0)
            for oy in (-1, 0, 1):
                for ox in (-1, 0, 1):
                    cx, cy = gx + ox, gy + oy
                    px = (cx + hash01(cx, cy, 81)) * cell
                    py = (cy + hash01(cx, cy, 83)) * cell
                    dist = math.hypot(x - px, y - py)
                    if dist < best:
                        best, second, best_id = dist, best, (cx, cy)
                    elif dist < second:
                        second = dist
            if second - best < 1.0:
                c.px[y][x] = SEAM
            else:
                shade = hash01(*best_id, 89)
                if shade < 0.2:
                    c.px[y][x] = ROCK[0]
                elif shade > 0.85 and c.px[y][x] == ROCK[1]:
                    c.px[y][x] = ROCK[2]


def draw_crown(c, head, up, side, tilt=12):
    """A broken golden crown, knocked askew: one prong snapped off."""
    up = rotate(up, (0, 0), tilt)
    side = (-up[1], up[0])
    band = add(head, mul(up, 7))
    c.shaded_polygon([add(add(band, mul(side, -9)), mul(up, -1.5)), add(add(band, mul(side, 9)), mul(up, -1.5)),
                      add(add(band, mul(side, 9)), mul(up, 2.5)), add(add(band, mul(side, -9)), mul(up, 2.5))], GOLD)
    for i, h in enumerate((7, 9, 2.5, 8, 6)):  # the middle-right prong is a snapped stump
        x = -8 + i * 4
        root = add(add(band, mul(side, x)), mul(up, 2))
        c.polygon([add(root, mul(side, -1.8)), add(root, mul(side, 1.8)), add(root, mul(up, h))], GOLD[1])
        c.set(*add(root, mul(up, h * 0.5)), GOLD[2])
    c.set(*add(add(band, mul(side, 2)), mul(up, 1)), (150, 20, 30, 255))  # a ruby left in its setting
    c.capsule(add(add(band, mul(side, 3.5)), mul(up, -1)), add(add(band, mul(side, 5)), mul(up, 2.4)), 0.5, GOLD[0])


def draw_body(c, p):
    up, side = axes(p)
    down = mul(up, -1)
    level = p["glow"]
    # Legs: thick pillars of rock.
    for hip, knee, foot in ((p["pL"], p["kL"], p["fL"]), (p["pR"], p["kR"], p["fR"])):
        c.shaded_capsule(hip, knee, 10, ROCK, "rock")
        c.shaded_capsule(knee, foot, 8.5, ROCK, "rock")
        c.shaded_capsule(add(foot, (-6, 2)), add(foot, (6, 2)), 4.5, ROCK, "rock")
    # Torso: massive chest, a crag-like hump behind the head.
    sL, sR, pL, pR = p["sL"], p["sR"], p["pL"], p["pR"]
    c.shaded_polygon([add(sL, mul(up, 6)), add(p["neck"], mul(up, 10)), add(sR, mul(up, 6)),
                      add(add(sR, mul(side, 4)), mul(down, 22)), add(add(pR, mul(side, 4)), mul(down, 6)),
                      add(add(pL, mul(side, -4)), mul(down, 6)), add(add(sL, mul(side, -4)), mul(down, 22))],
                     ROCK, "rock")
    for s in (sL, sR):
        c.shaded_circle(s, 13, ROCK, "rock")
    # Arms: boulder shoulders, long heavy forearms, blunt fingers.
    for s, e, h in ((sL, p["eL"], p["hL"]), (sR, p["eR"], p["hR"])):
        c.shaded_capsule(s, e, 9.5, ROCK, "rock")
        c.shaded_capsule(e, h, 8, ROCK, "rock")
        c.shaded_circle(h, 7.5, ROCK, "rock")
    # Head: a slab of rock, jutting brow, burning eyes and maw.
    head = p["head"]
    c.shaded_polygon([add(add(head, mul(side, -9)), mul(up, 6)), add(add(head, mul(side, 9)), mul(up, 6)),
                      add(add(head, mul(side, 11)), mul(up, -2)), add(add(head, mul(side, 7)), mul(up, -11)),
                      add(add(head, mul(side, -7)), mul(up, -11)), add(add(head, mul(side, -11)), mul(up, -2))],
                     ROCK, "rock")
    rock_texture(c)
    ramp = glow_ramp(max(level, 0.5))
    if p["crumble"] < 3:
        for s in (-1, 1):
            eye = add(add(head, mul(side, s * 4.5)), mul(up, 1.5))
            c.capsule(add(eye, mul(side, -s * 2.2)), add(add(eye, mul(side, s * 2.2)), mul(up, 1)), 1.6, ramp[0])
            c.capsule(add(eye, mul(side, -s * 1.4)), add(add(eye, mul(side, s * 1.4)), mul(up, 0.6)), 0.8, ramp[2])
        c.capsule(add(add(head, mul(side, -7)), mul(up, 4)), add(add(head, mul(side, 7)), mul(up, 4)), 1.4, SEAM)
        maw = add(head, mul(down, 5))
        c.polygon([add(maw, mul(side, -6)), add(maw, mul(side, 6)), add(add(maw, mul(side, 4)), mul(down, p["maw"])),
                   add(add(maw, mul(side, -4)), mul(down, p["maw"]))], ramp[0])
        c.capsule(add(add(maw, mul(side, -3)), mul(down, p["maw"] * 0.5)),
                  add(add(maw, mul(side, 3)), mul(down, p["maw"] * 0.5)), max(0.6, p["maw"] * 0.3), ramp[1])
        for i in range(-2, 3):  # stone teeth
            c.polygon([add(add(maw, mul(side, i * 2.6 - 1)), mul(up, 0.5)), add(add(maw, mul(side, i * 2.6 + 1)), mul(up, 0.5)),
                       add(add(maw, mul(side, i * 2.6)), mul(down, 2.2))], ROCK[2])
    # Hairline cracks glowing from within (the obelisk cracks are separate quads).
    for i, (start, d, length) in enumerate((((44, 40), (0.3, 1), 22), ((86, 44), (-0.4, 1), 18),
                                            ((60, 58), (0.2, 1), 16), ((32, 50), (-0.2, 1), 26),
                                            ((96, 62), (0.1, 1), 20), ((48, 92), (0.1, 1), 22),
                                            ((70, 36), (-0.6, 1), 12))):
        crack(c, add(start, (0, p["neck"][1] - BASE["neck"][1])), d, length, i + 1, level)
    draw_crown(c, head, up, side)


def draw_rubble(c, stage, level):
    """stage 1: splitting, 2: collapsing, 3: settled heap."""
    height = (70, 46, 24)[stage - 1]
    rocks = 26 if stage < 3 else 22
    for i in range(rocks):
        cx = 18 + hash01(i, 1, 91) * 92
        spread = 1 - abs(cx - 64) / 50
        top = GROUND - height * max(0.15, spread) * hash01(i, 2, 91) - 6
        r = 4 + hash01(i, 3, 91) * 7
        if stage == 1 and hash01(i, 4, 91) < 0.3:
            top -= 16  # chunks still in the air
        c.shaded_circle((cx, top), r, ROCK, "rock")
    rock_texture(c)
    for i in range(6):
        x = 30 + i * 12
        crack(c, (x, GROUND - 6 - hash01(i, 7, 93) * height * 0.5), (0.2, 1), 10, 20 + i, level)
    crown_at = (66, GROUND - height * 0.55 - 10) if stage < 3 else (60, GROUND - 22)
    draw_crown(c, crown_at, (0, -1), (1, 0), tilt=40 if stage == 3 else 25)


def draw_frame(p):
    c = Canvas(128, 128)
    if p["crumble"]:
        draw_rubble(c, p["crumble"], p["glow"])
    else:
        draw_body(c, p)
    if p["blast"]:
        centre, r = p["blast"]
        flames(c, centre, r, FIRE[1:3], 5)
        orb(c, centre, r, FIRE)
    c.outline(OUTLINE)
    return c


if __name__ == "__main__":
    save_sheet("great_demon", [draw_frame(p) for p in POSES], sys.argv[1] if len(sys.argv) > 1 else None)
