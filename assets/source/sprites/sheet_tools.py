"""Shared pose and sheet helpers for the enemy sprite generators.

Every sheet is a 4x4 grid of 128x128 frames laid out as
    0 idle | 1-4 walk | 5 windup | 6 attack | 7 pain | 8-11 death (11 = corpse)
matching the frame lists in each enemy's *_sprites.tres. How many metres a
frame covers is set by that resource's quad, so each script states its scale.

AI-authored (Claude): see docs/placeholders.md.
"""

import os

from pixel_canvas import Canvas, add, hash01, mul, norm, rotate, sub, write_png

FRAME = 128
COLS = 4
ROWS = 4
GROUND = 125

# A standing human at 1.8 m per frame. "L" is the viewer's left (the
# figure's right hand).
HUMAN = {
    "head": (64, 19), "neck": (64, 28),
    "sL": (48, 33), "sR": (80, 33),
    "eL": (43, 50), "eR": (85, 50),
    "hL": (42, 66), "hR": (86, 66),
    "pL": (56, 70), "pR": (72, 70),
    "kL": (55, 96), "kR": (73, 96),
    "fL": (54, 120), "fR": (74, 120),
}
HUMAN_UPPER = ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR", "pL", "pR")


def shifted(p, dx, dy, keys):
    q = dict(p)
    for k in keys:
        q[k] = (q[k][0] + dx, q[k][1] + dy)
    return q


def axes(p):
    """(up, side): up runs hips -> neck; side points to the viewer's right."""
    up = norm(sub(p["neck"], mul(add(p["pL"], p["pR"]), 0.5)))
    return up, (-up[1], up[0])


def fit(p, degrees, joints, ground_gap=6, nudge=0, pivot=(64, 120)):
    """Rotates the body about its feet, centres it and lays it on the ground."""
    q = dict(p)
    for k in joints:
        q[k] = rotate(p[k], pivot, degrees)
    xs = [q[k][0] for k in joints]
    ys = [q[k][1] for k in joints]
    dx = 64 - (min(xs) + max(xs)) / 2 + nudge
    dy = (GROUND - ground_gap) - max(ys)
    return shifted(q, dx, dy, joints)


def human_walk(p, phase):
    """phase 0/2 = contact, 1 = viewer-left leg lifted, 3 = right lifted."""
    if phase in (1, 3):
        p = shifted(p, 0, -2, HUMAN_UPPER)
    if phase == 1:
        p = dict(p, kL=add(p["kL"], (1, -6)), fL=add(p["fL"], (2, -8)))
    elif phase == 3:
        p = dict(p, kR=add(p["kR"], (-1, -6)), fR=add(p["fR"], (-2, -8)))
    return p


def human_reel(p):
    """First death frame: knocked back, knees buckling."""
    p = dict(p, head=(57, 25), neck=(61, 32), eL=(36, 48), hL=(30, 60), eR=(92, 46),
             hR=(98, 56), kL=(51, 98), kR=(77, 98))
    return shifted(p, 0, 4, HUMAN_UPPER)


def human_kneel(p):
    """Second death frame: on the knees, slumping."""
    p = dict(p, head=(66, 31), neck=(65, 38), sL=(49, 42), sR=(80, 42), eL=(47, 60),
             hL=(49, 76), eR=(82, 60), hR=(80, 76), pL=(56, 80), pR=(72, 80),
             kL=(52, 108), kR=(76, 108), fL=(50, 120), fR=(78, 120))
    return shifted(p, 0, 4, HUMAN_UPPER + ("kL", "kR"))


def human_limp(p):
    """Arms hanging, legs together: the base for falling frames."""
    return dict(p, eL=(48, 50), hL=(49, 66), eR=(80, 50), hR=(79, 66),
                kL=(57, 96), kR=(71, 96), fL=(57, 120), fR=(71, 120))


def human_pain(p):
    return dict(p, head=(59, 21), neck=(62, 29), sL=(47, 34), sR=(79, 32), eL=(34, 46),
                hL=(28, 56), eR=(94, 42), hR=(102, 50))


def line(c, a, b, color, tag=None):
    """1px line (strings, chains, cracks)."""
    steps = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
    for i in range(steps + 1):
        t = i / steps
        c.set(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, color, tag)


def orb(c, centre, radius, ramp, tag="noline"):
    """Glowing ball of magic or fire: concentric rings, brightest inside.
    "noline" keeps the outline pass from ringing it in black."""
    for i, color in enumerate(ramp):
        c.circle(centre, radius * (1 - i / (len(ramp) + 0.5)), color, tag)


def flames(c, centre, radius, ramp, seed):
    """Licks of fire rising off an orb."""
    for i in range(5):
        a = -150 + i * 30 + (hash01(i, 1, seed) - 0.5) * 20
        d = rotate((1, 0), (0, 0), a)
        base = add(centre, mul(d, radius * 0.6))
        tip = add(add(centre, mul(d, radius * (1.4 + hash01(i, 2, seed) * 0.6))), (0, -2))
        perp = (-d[1], d[0])
        c.polygon([add(base, mul(perp, 1.6)), add(base, mul(perp, -1.6)), tip],
                  ramp[i % len(ramp)], "noline")


def pool(c, centre_x, half=26, color=(92, 10, 10, 255)):
    """Blood pool under a corpse; drawn first so the body covers it."""
    x = centre_x
    c.polygon([(x - half, GROUND - 1), (x - half * 0.4, GROUND - 5), (x + half * 0.7, GROUND - 5),
               (x + half * 1.15, GROUND - 1), (x + half * 0.3, GROUND + 2), (x - half * 0.7, GROUND + 2)],
              color, "noline")


def splashes(c, centre, seed, count=10, spread=12, ramp=((92, 10, 10, 255), (138, 22, 16, 255))):
    for i in range(count):
        dx = (hash01(i, 1, seed) - 0.5) * spread
        dy = (hash01(i, 2, seed) - 0.5) * spread * 1.15
        c.set(centre[0] + dx, centre[1] + dy, ramp[1] if i % 3 else ramp[0])


def smear_arc(c, centre, radius, start, end, color, width=2.2):
    """Pale arc trailing a weapon swing."""
    steps = 48
    for i in range(steps + 1):
        a = start + (end - start) * i / steps
        r = 0.8 + width * (1 - abs(i / steps - 0.6) * 1.6)
        c.circle(add(centre, mul(rotate((1, 0), (0, 0), a), radius)), max(0.8, r), color, "noline")


def save_sheet(name, frames, preview_dir=None):
    """Packs 12 frames into the 4x4 sheet under assets/sprites/enemies/."""
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(os.path.dirname(here)))
    out_dir = os.path.join(root, "assets", "sprites", "enemies")
    os.makedirs(out_dir, exist_ok=True)
    sheet = [[None] * (FRAME * COLS) for _ in range(FRAME * ROWS)]
    for i, c in enumerate(frames):
        ox, oy = (i % COLS) * FRAME, (i // COLS) * FRAME
        for y in range(FRAME):
            sheet[oy + y][ox:ox + FRAME] = c.px[y]
    write_png(os.path.join(out_dir, name + "_sheet.png"), FRAME * COLS, FRAME * ROWS, sheet)
    if preview_dir:
        scale = 3
        bg = (70, 70, 74, 255)
        big = []
        for row in sheet:
            line_px = []
            for px in row:
                line_px.extend([px or bg] * scale)
            big.extend([line_px] * scale)
        write_png(os.path.join(preview_dir, name + "_preview.png"),
                  FRAME * COLS * scale, FRAME * ROWS * scale, big)


__all__ = ["Canvas", "add", "hash01", "mul", "norm", "rotate", "sub", "FRAME", "GROUND",
           "HUMAN", "HUMAN_UPPER", "shifted", "axes", "fit", "human_walk", "human_reel",
           "human_kneel", "human_limp", "human_pain", "line", "orb", "flames", "pool",
           "splashes", "smear_arc", "save_sheet"]
