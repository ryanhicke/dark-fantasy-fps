"""Generates the bandit sprite sheet (front-facing only).

Muscular, clean-shaven, grimy man in a sleeveless leather jerkin, green
hose, brown boots and a steel cap, armed with a sword.

Run from the project root:
    python assets/source/sprites/bandit.py [preview_dir]

Writes assets/sprites/enemies/bandit_sheet.png: 128x128 frames (one frame
= 1.8 m, matching the bandit's sprite quad) in a 4x4 grid (512x512), laid
out as described by enemies/bandit/bandit_sprites.tres:
    0 idle | 1-4 walk | 5 windup | 6 swing | 7 pain | 8-11 death (11 = corpse)
AI-authored (Claude): see docs/placeholders.md.
"""

import os
import sys

from pixel_canvas import Canvas, add, hash01, mul, norm, rotate, sub, write_png

FRAME = 128
COLS = 4
ROWS = 4
GROUND = 125

OUTLINE = (20, 13, 10, 255)
SKIN = ((122, 80, 60, 255), (170, 120, 90, 255), (204, 156, 120, 255))
GRIME = ((88, 66, 50, 255), (116, 92, 70, 255))
LEATHER = ((56, 36, 22, 255), (94, 62, 36, 255), (128, 88, 52, 255))
STUD = (150, 140, 120, 255)
HOSE = ((30, 50, 26, 255), (52, 80, 40, 255), (78, 106, 56, 255))
BOOT = ((46, 28, 16, 255), (80, 50, 28, 255), (108, 70, 40, 255))
STEEL = ((66, 68, 76, 255), (122, 126, 134, 255), (190, 194, 200, 255))
BELT = ((34, 22, 14, 255), (52, 34, 20, 255), (70, 46, 28, 255))
GRIP = ((44, 26, 16, 255), (70, 42, 24, 255), (92, 58, 34, 255))
EYE = (26, 18, 14, 255)
MOUTH = (96, 54, 44, 255)
BLOOD = ((92, 10, 10, 255), (138, 22, 16, 255))


# --- poses ---------------------------------------------------------------
# Joint names: "L" is the viewer's left (the bandit's right, sword arm).

BASE = {
    "head": (64, 19), "neck": (64, 28),
    "sL": (47, 33), "sR": (81, 33),
    "eL": (41, 50), "eR": (87, 50),
    "hL": (40, 66), "hR": (88, 66),
    "pL": (56, 70), "pR": (72, 70),
    "kL": (54, 96), "kR": (74, 96),
    "fL": (53, 120), "fR": (75, 120),
}
UPPER = ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR", "pL", "pR")


def pose(**overrides):
    p = dict(BASE)
    p.update({"sword": (0.35, 0.94), "sword_front": True, "blood": 0})
    p.update(overrides)
    return p


def shifted(p, dx, dy, keys):
    q = dict(p)
    for k in keys:
        q[k] = (q[k][0] + dx, q[k][1] + dy)
    return q


def walk(phase):
    """phase 0/2 = contact, 1 = viewer-left leg lifted, 3 = right lifted."""
    bob = -2 if phase in (1, 3) else 0
    p = pose(sword=(-0.25, -0.97), eL=(39, 48), hL=(45, 60))
    p = shifted(p, 0, bob, UPPER)
    if phase == 1:
        p.update(kL=(55, 90), fL=(56, 112), hR=(86, 60), eR=(88, 48))
    elif phase == 3:
        p.update(kR=(73, 90), fR=(72, 112), hL=(45, 64))
    return p


def limp():
    """Arms hanging, legs together: the base for falling frames."""
    return pose(eL=(48, 50), hL=(49, 66), eR=(80, 50), hR=(79, 66),
                kL=(57, 96), kR=(71, 96), fL=(57, 120), fR=(71, 120), sword=None)


def fit(p, degrees):
    """Rotates the whole body about its feet, then puts it on the ground."""
    pivot = (64, 120)
    joints = list(BASE)
    q = dict(p)
    for k in joints:
        q[k] = rotate(p[k], pivot, degrees)
    xs = [q[k][0] for k in joints]
    ys = [q[k][1] for k in joints]
    dx = 64 - (min(xs) + max(xs)) / 2
    dy = (GROUND - 6) - max(ys)
    return shifted(q, dx, dy, joints)


POSES = [
    # 0 idle: sword held low and out.
    pose(),
    # 1-4 walk
    walk(0), walk(1), walk(2), walk(3),
    # 5 windup: sword cocked back over the head (drawn behind it).
    pose(sL=(48, 32), eL=(36, 20), hL=(46, 9), sword=(0.93, 0.36), sword_front=False,
         eR=(90, 44), hR=(92, 58)),
    # 6 swing: arm flung across the body, blade low on the viewer's right.
    shifted(pose(eL=(58, 46), hL=(74, 54), sword=(0.62, 0.78), eR=(92, 42), hR=(100, 50)),
            3, 1, UPPER),
    # 7 pain: head snapped aside, arms thrown out.
    pose(head=(59, 21), neck=(62, 29), sL=(46, 34), sR=(80, 32), eL=(34, 46), hL=(28, 56),
         eR=(94, 42), hR=(102, 50), sword=(-0.5, -0.86), blood=1),
    # 8 death: reeling, knees buckling.
    shifted(pose(head=(57, 25), neck=(61, 32), eL=(36, 48), hL=(30, 60), eR=(94, 46),
                 hR=(100, 56), kL=(51, 98), kR=(77, 98), sword=(-0.3, 0.95), blood=1),
            0, 4, UPPER),
    # 9 death: on his knees, slumping, sword gone.
    shifted(pose(head=(66, 31), neck=(65, 38), sL=(48, 42), sR=(81, 42), eL=(46, 60),
                 hL=(48, 76), eR=(83, 60), hR=(80, 76), pL=(56, 80), pR=(72, 80),
                 kL=(52, 108), kR=(76, 108), fL=(50, 120), fR=(78, 120), sword=None,
                 blood=1), 0, 4, UPPER + ("kL", "kR")),
    # 10 death: toppling over, sword on the ground.
    dict(fit(limp(), -55), blood=1, dropped=True),
    # 11 corpse: flat on the ground in a pool of blood.
    dict(fit(limp(), -90), blood=2),
]


# --- drawing -------------------------------------------------------------

def draw_sword(c, hand, direction):
    d = norm(direction)
    perp = (-d[1], d[0])
    c.shaded_circle(add(hand, mul(d, -6)), 2.2, STEEL)          # pommel
    c.capsule(add(hand, mul(d, -4)), add(hand, mul(d, 3)), 1.6, GRIP[1])
    guard = add(hand, mul(d, 4))
    c.capsule(add(guard, mul(perp, -5)), add(guard, mul(perp, 5)), 1.4, STEEL[0])
    tip = add(hand, mul(d, 38))
    c.capsule(add(hand, mul(d, 5)), add(hand, mul(d, 34)), 1.7, STEEL[1])
    c.capsule(add(hand, mul(d, 34)), tip, 0.9, STEEL[1])
    # Fuller: a bright line down the blade's lit side.
    c.capsule(add(add(hand, mul(d, 6)), mul(perp, -0.6)),
              add(add(hand, mul(d, 32)), mul(perp, -0.6)), 0.5, STEEL[2])


def draw_dropped_sword(c, y):
    c.capsule((14, y), (22, y), 1.6, GRIP[1])
    c.capsule((23, y - 4), (23, y + 3), 1.4, STEEL[0])
    c.capsule((24, y), (54, y), 1.6, STEEL[1])
    c.capsule((25, y - 0.6), (52, y - 0.6), 0.5, STEEL[2])


def draw_arm(c, shoulder, elbow, hand):
    c.shaded_capsule(shoulder, elbow, 5.2, SKIN, "skin")       # big biceps
    c.shaded_capsule(elbow, hand, 4.3, SKIN, "skin")           # forearm
    # Leather bracer on the forearm.
    c.shaded_capsule(add(elbow, mul(sub(hand, elbow), 0.45)),
                     add(elbow, mul(sub(hand, elbow), 0.85)), 4.5, LEATHER)
    c.shaded_circle(hand, 3.6, SKIN, "skin")


def draw_leg(c, hip, knee, foot):
    c.shaded_capsule(hip, knee, 6.0, HOSE, "hose")
    c.shaded_capsule(knee, foot, 4.8, HOSE, "hose")
    boot_top = add(knee, mul(sub(foot, knee), 0.45))
    c.shaded_capsule(boot_top, foot, 5.4, BOOT)
    c.capsule(add(boot_top, (-5.5, 0)), add(boot_top, (5.5, 0)), 1.6, BOOT[2])  # cuff
    c.shaded_capsule(add(foot, (-2, 2)), add(foot, (3, 2)), 3.4, BOOT)


def draw_torso(c, p, up, side):
    sL, sR, pL, pR = p["sL"], p["sR"], p["pL"], p["pR"]
    down = mul(up, -1)
    hem = 11
    jerkin = [add(sL, mul(up, 2)), add(sR, mul(up, 2)),
              add(add(pR, mul(side, 3)), mul(down, hem)),
              add(add(pL, mul(side, -3)), mul(down, hem))]
    c.shaded_polygon(jerkin, LEATHER, "leather")
    # Stitched seam and rows of studs.
    neck_base = add(p["neck"], mul(down, 3))
    hip_mid = mul(add(pL, pR), 0.5)
    for i in range(1, 9):
        pt = add(neck_base, mul(sub(hip_mid, neck_base), i / 9))
        c.set(*add(pt, mul(side, 0.5)), LEATHER[0])
    for row in range(3):
        a = add(add(sL, mul(down, 9 + row * 9)), mul(side, 5))
        b = add(add(sR, mul(down, 9 + row * 9)), mul(side, -5))
        for i in range(4):
            c.set(*add(a, mul(sub(b, a), (i + 0.5) / 4)), STUD)
    # Belt with a steel buckle.
    c.capsule(add(pL, mul(side, -3)), add(pR, mul(side, 3)), 2.4, BELT[1])
    c.capsule(add(pL, mul(side, -3)), add(pR, mul(side, 3)), 0.6, BELT[2])
    c.shaded_circle(hip_mid, 2.6, STEEL)
    # Leather pauldrons over the shoulders.
    c.shaded_circle(sL, 6.2, LEATHER, "leather")
    c.shaded_circle(sR, 6.2, LEATHER, "leather")


def draw_head(c, p, up, side):
    head = p["head"]
    down = mul(up, -1)
    c.shaded_capsule(p["neck"], head, 4.6, SKIN, "skin")
    c.shaded_circle(head, 7.6, SKIN, "skin")
    # Square, clean-shaven jaw.
    c.shaded_capsule(head, add(head, mul(down, 4.5)), 6.4, SKIN, "skin")
    # Steel cap: dome over the top half of the head, with a brim.
    dome = []
    for i in range(13):
        v = rotate(up, (0, 0), -90 + i * 15)
        dome.append(add(add(head, mul(up, -0.5)), mul(v, 9.0)))
    c.shaded_polygon(dome, STEEL)
    brim = add(head, mul(up, -0.5))
    c.capsule(add(brim, mul(side, -9.5)), add(brim, mul(side, 9.5)), 1.3, STEEL[0])
    c.set(*add(head, mul(up, 6.5)), STEEL[2])                  # rivet glint
    # Face: brim shadow, eyes, nose, mouth.
    for i in range(-5, 6):
        c.set(*add(add(head, mul(down, 2)), mul(side, i)), SKIN[0], "skin")
    for s in (-3, 3):
        c.set(*add(add(head, mul(down, 3)), mul(side, s)), EYE)
    c.set(*add(add(head, mul(down, 5.5)), mul(side, 0.5)), SKIN[0], "skin")
    for i in (-2, -1, 0, 1, 2):
        c.set(*add(add(head, mul(down, 8.2)), mul(side, i)), MOUTH)


def grime(c):
    """Smears dirt on bare skin and scuffs on leather and hose."""
    for y in range(c.h):
        for x in range(c.w):
            tag = c.tag[y][x]
            n = hash01(x // 3, y // 3, 7)
            if tag == "skin" and n < 0.16:
                c.px[y][x] = GRIME[0] if hash01(x, y, 3) < 0.5 else GRIME[1]
            elif tag in ("leather", "hose") and n < 0.05:
                c.px[y][x] = (58, 44, 32, 255)


def draw_pool(c, p):
    """Blood pool under a corpse; drawn first so the body covers it."""
    mid = mul(add(p["pL"], p["neck"]), 0.5)
    c.polygon([(mid[0] - 26, GROUND - 1), (mid[0] - 10, GROUND - 5), (mid[0] + 18, GROUND - 5),
               (mid[0] + 30, GROUND - 1), (mid[0] + 8, GROUND + 2), (mid[0] - 18, GROUND + 2)],
              BLOOD[0], "noline")


def draw_splashes(c, p):
    chest = mul(add(add(p["sL"], p["sR"]), add(p["pL"], p["pR"])), 0.25)
    for i in range(10):
        dx = (hash01(i, 1, 11) - 0.5) * 12
        dy = (hash01(i, 2, 11) - 0.5) * 14
        c.set(chest[0] + dx, chest[1] + dy, BLOOD[1] if i % 3 else BLOOD[0])


def draw_frame(p):
    c = Canvas(FRAME, FRAME)
    up = norm(sub(p["neck"], mul(add(p["pL"], p["pR"]), 0.5)))
    side = (-up[1], up[0])
    if p["blood"] >= 2:
        draw_pool(c, p)
    if p.get("dropped"):
        draw_dropped_sword(c, GROUND - 2)
    if p["sword"] is not None and not p["sword_front"]:
        draw_sword(c, p["hL"], p["sword"])
    draw_leg(c, p["pL"], p["kL"], p["fL"])
    draw_leg(c, p["pR"], p["kR"], p["fR"])
    draw_torso(c, p, up, side)
    draw_arm(c, p["sR"], p["eR"], p["hR"])
    draw_arm(c, p["sL"], p["eL"], p["hL"])
    draw_head(c, p, up, side)
    if p["sword"] is not None and p["sword_front"]:
        draw_sword(c, p["hL"], p["sword"])
    grime(c)
    if p["blood"]:
        draw_splashes(c, p)
    c.outline(OUTLINE)
    return c


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(os.path.dirname(os.path.dirname(here)))
    out_dir = os.path.join(root, "assets", "sprites", "enemies")
    os.makedirs(out_dir, exist_ok=True)
    sheet = [[None] * (FRAME * COLS) for _ in range(FRAME * ROWS)]
    for i, p in enumerate(POSES):
        c = draw_frame(p)
        ox, oy = (i % COLS) * FRAME, (i // COLS) * FRAME
        for y in range(FRAME):
            sheet[oy + y][ox:ox + FRAME] = c.px[y]
    write_png(os.path.join(out_dir, "bandit_sheet.png"), FRAME * COLS, FRAME * ROWS, sheet)

    if len(sys.argv) > 1:
        # 3x preview on a gray background for eyeballing.
        scale = 3
        bg = (70, 70, 74, 255)
        big = []
        for row in sheet:
            line = []
            for px in row:
                line.extend([px or bg] * scale)
            big.extend([line] * scale)
        write_png(os.path.join(sys.argv[1], "bandit_preview.png"),
                  FRAME * COLS * scale, FRAME * ROWS * scale, big)


if __name__ == "__main__":
    main()
