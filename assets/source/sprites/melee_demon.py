"""Generates the melee demon sprite sheet (front-facing only).

Pink-skinned, heavily muscled demon with large red horns, big glowing
white eyes, a fanged mouth, sharp red claws on its hands and on its goat-like
feet, and a ragged hide loincloth. One frame = 2.6 m.

Run from the project root:
    python assets/source/sprites/melee_demon.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import sys

from sheet_tools import (Canvas, add, hash01, mul, norm, rotate, sub, axes, fit, pool,
                         shifted, splashes, save_sheet)

OUTLINE = (24, 8, 12, 255)
SKIN = ((150, 66, 88, 255), (204, 110, 130, 255), (236, 160, 170, 255))
MUSCLE = (128, 52, 72, 255)
HORN = ((96, 12, 12, 255), (164, 30, 26, 255), (214, 74, 56, 255))
CLAW = ((110, 10, 14, 255), (186, 24, 28, 255), (236, 90, 80, 255))
EYE_GLOW = (190, 196, 222, 255)
EYE = (255, 255, 255, 255)
EYE_DEAD = (110, 70, 80, 255)
MOUTH = ((40, 4, 10, 255), (100, 14, 24, 255))
TOOTH = ((176, 166, 140, 255), (236, 230, 210, 255))
HIDE = ((40, 26, 20, 255), (70, 46, 32, 255), (98, 68, 46, 255))
BLOOD = ((80, 6, 10, 255), (130, 16, 20, 255))
SMEAR = (236, 120, 110, 255)

BASE = {
    "head": (64, 30), "neck": (64, 38),
    "sL": (42, 42), "sR": (86, 42),
    "eL": (33, 63), "eR": (95, 63),
    "hL": (31, 84), "hR": (97, 84),
    "pL": (55, 80), "pR": (73, 80),
    "kL": (52, 99), "kR": (76, 99),
    "aL": (51, 111), "aR": (77, 111),  # hocks of the goat-like legs
    "fL": (49, 121), "fR": (79, 121),
}
JOINTS = list(BASE)
UPPER = ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR", "pL", "pR")


def pose(**overrides):
    p = dict(BASE)
    p.update(jaw=3, tilt=0, blood=0, smear=False, dead=False)
    p.update(overrides)
    return p


def run(phase):
    bob = -2 if phase in (1, 3) else 1
    p = shifted(pose(jaw=5), 0, bob, UPPER)
    if phase == 1:
        p.update(kL=(53, 93), aL=(52, 104), fL=(51, 114), eR=(94, 54), hR=(86, 68))
    elif phase == 3:
        p.update(kR=(75, 93), aR=(76, 104), fR=(77, 114), eL=(34, 54), hL=(42, 68))
    return p


def limp():
    return pose(eL=(42, 62), hL=(42, 82), eR=(86, 62), hR=(86, 82),
                kL=(56, 99), kR=(72, 99), aL=(56, 111), aR=(72, 111), fL=(56, 121), fR=(72, 121))


POSES = [
    pose(),
    run(0), run(1), run(2), run(3),
    # windup: claws raised high and wide, roaring
    shifted(pose(eL=(24, 34), hL=(20, 16), eR=(104, 34), hR=(108, 16), jaw=8), 0, 2,
            ("head", "neck", "sL", "sR")),
    # attack: the right hand rakes down across, claw trails behind it
    pose(head=(66, 32), neck=(65, 40), eL=(26, 52), hL=(20, 36), eR=(84, 62), hR=(64, 82),
         jaw=7, smear=True),
    pose(head=(70, 31), neck=(67, 39), tilt=22, eL=(38, 60), hL=(46, 76), eR=(94, 58), hR=(90, 74),
         jaw=7, blood=1),
    shifted(pose(head=(67, 26), neck=(66, 34), tilt=14, eL=(26, 54), hL=(18, 68), eR=(102, 54),
                 hR=(110, 68), kL=(49, 101), kR=(79, 101), jaw=8, blood=1), 0, 3, UPPER),
    shifted(pose(head=(64, 52), neck=(64, 56), sL=(44, 58), sR=(84, 58), eL=(38, 78), hL=(40, 98),
                 eR=(90, 78), hR=(88, 98), pL=(55, 92), pR=(73, 92), kL=(48, 112), kR=(80, 112),
                 aL=(44, 118), aR=(84, 118), fL=(40, 121), fR=(88, 121), jaw=5, blood=1), 0, 1, UPPER),
    dict(fit(limp(), -55, JOINTS, ground_gap=8), blood=1, dead=True),
    dict(fit(limp(), -90, JOINTS, ground_gap=8), blood=2, dead=True, jaw=4),
]


def claws(c, hand, forearm, length=7):
    d = norm(forearm)
    perp = (-d[1], d[0])
    for k in (-1.5, -0.5, 0.5, 1.5):
        base = add(add(hand, mul(d, 3.5)), mul(perp, k * 2.4))
        tip = add(base, mul(rotate(d, (0, 0), k * 12), length))
        c.polygon([add(base, mul(perp, 1.2)), add(base, mul(perp, -1.2)), tip], CLAW[1])
        c.set(*add(base, mul(sub(tip, base), 0.3)), CLAW[2])


def draw_arm(c, shoulder, elbow, hand):
    c.shaded_capsule(shoulder, elbow, 7.0, SKIN, "skin")
    c.shaded_capsule(elbow, hand, 5.6, SKIN, "skin")
    mid = add(shoulder, mul(sub(elbow, shoulder), 0.55))
    d = norm(sub(elbow, shoulder))
    c.capsule(add(mid, mul(d, -4)), add(mid, mul(d, 3)), 0.5, MUSCLE, "skin")  # biceps line
    c.shaded_circle(hand, 5.0, SKIN, "skin")
    claws(c, hand, sub(hand, elbow))


def draw_leg(c, hip, knee, hock, foot):
    c.shaded_capsule(hip, knee, 7.6, SKIN, "skin")
    c.shaded_capsule(knee, hock, 4.8, SKIN, "skin")
    c.shaded_capsule(hock, foot, 3.8, SKIN, "skin")
    for k in (-1.5, 0, 1.5):  # clawed toes
        toe = add(foot, (k * 2, 2.5))
        c.polygon([add(toe, (-1.1, 0)), add(toe, (1.1, 0)), add(toe, (k * 0.6, 5))], CLAW[1])


def draw_torso(c, p, up, side):
    sL, sR, pL, pR = p["sL"], p["sR"], p["pL"], p["pR"]
    down = mul(up, -1)
    torso = [add(sL, mul(up, 4)), add(sR, mul(up, 4)),
             add(add(sR, mul(down, 16)), mul(side, 3)),
             add(add(pR, mul(side, 2)), mul(down, 2)),
             add(add(pL, mul(side, -2)), mul(down, 2)),
             add(add(sL, mul(down, 16)), mul(side, -3))]
    c.shaded_polygon(torso, SKIN, "skin")
    # Trapezius rising to the neck, and big rounded shoulders.
    c.shaded_polygon([add(add(sL, mul(up, 3)), mul(side, 4)), add(p["neck"], mul(up, 5)),
                      add(add(sR, mul(up, 3)), mul(side, -4))], SKIN, "skin")
    c.shaded_circle(sL, 8.0, SKIN, "skin")
    c.shaded_circle(sR, 8.0, SKIN, "skin")
    neck = p["neck"]
    hip_mid = mul(add(pL, pR), 0.5)
    chest = add(neck, mul(down, 15))
    for s in (-1, 1):  # pecs
        c.capsule(add(add(neck, mul(down, 7)), mul(side, s * 15)), add(chest, mul(side, s * 2)), 0.6, MUSCLE, "skin")
        c.capsule(add(add(neck, mul(down, 12)), mul(side, s * 16)), add(add(chest, mul(side, s * 12)), mul(down, 2)),
                  0.5, MUSCLE, "skin")
    c.capsule(chest, add(hip_mid, mul(up, 6)), 0.5, MUSCLE, "skin")
    for i in range(3):  # abs
        y = add(chest, mul(sub(hip_mid, chest), 0.22 + i * 0.22))
        c.capsule(add(y, mul(side, -6)), add(y, mul(side, -2)), 0.5, MUSCLE, "skin")
        c.capsule(add(y, mul(side, 2)), add(y, mul(side, 6)), 0.5, MUSCLE, "skin")
    # Ragged hide loincloth.
    belt_l, belt_r = add(pL, mul(side, -6)), add(pR, mul(side, 6))
    c.capsule(belt_l, belt_r, 2.0, HIDE[0])
    flap = [belt_l, belt_r]
    for i in range(6, -1, -1):
        t = i / 6
        edge = add(belt_l, mul(sub(belt_r, belt_l), t))
        flap.append(add(edge, mul(down, 9 if i % 2 else 5)))
    c.shaded_polygon(flap, HIDE)


def draw_head(c, p, up, side):
    head = p["head"]
    if p["tilt"]:
        up = rotate(up, (0, 0), p["tilt"])
        side = (-up[1], up[0])
    down = mul(up, -1)
    jaw = p["jaw"]
    # Big horns: out from the temples, curling up and forward.
    for s in (-1, 1):
        prev = add(add(head, mul(side, s * 6)), mul(up, 6))
        for i in range(1, 11):
            t = i / 10
            pt = add(add(head, mul(side, s * (6 + 16 * t - 4 * t * t * t))), mul(up, 6 + 4 * t + 16 * t * t))
            c.capsule(prev, pt, 4.2 * (1 - t) + 0.7, HORN[1])
            c.capsule(add(prev, mul(side, -s * 0.8)), add(pt, mul(side, -s * 0.8)), (4.2 * (1 - t) + 0.7) * 0.35,
                      HORN[2])
            prev = pt
    # Pointed ears.
    for s in (-1, 1):
        base = add(add(head, mul(side, s * 8)), mul(up, 1))
        c.polygon([add(base, mul(up, 3)), add(base, mul(up, -3)), add(add(base, mul(side, s * 7)), mul(up, 3))],
                  SKIN[0], "skin")
    c.shaded_circle(add(head, mul(up, 1)), 9.0, SKIN, "skin")
    c.shaded_capsule(head, add(head, mul(down, 5)), 7.4, SKIN, "skin")  # heavy jaw
    # Brow ridge over large, glowing white eyes.
    for s in (-1, 1):
        eye = add(add(head, mul(side, s * 4.4)), mul(up, 1.5))
        if p["dead"]:
            c.capsule(add(eye, mul(side, -1.2)), add(eye, mul(side, 1.2)), 0.7, EYE_DEAD)
        else:
            # Two separate slanted almonds, with dark skin between them.
            c.capsule(add(eye, mul(side, -s * 1.4)), add(add(eye, mul(side, s * 1.6)), mul(up, 1.0)), 1.7, EYE_GLOW)
            c.capsule(add(eye, mul(side, -s * 0.8)), add(add(eye, mul(side, s * 1.0)), mul(up, 0.7)), 0.9, EYE)
            c.set(*add(head, mul(up, 1.5)), MUSCLE)
        c.capsule(add(add(eye, mul(side, -s * 3)), mul(up, 2.2)), add(add(eye, mul(side, s * 3)), mul(up, 4)),
                  1.0, MUSCLE)
    c.set(*add(head, mul(down, 1)), MUSCLE)  # nostrils
    # Fanged mouth.
    lip = add(head, mul(down, 3.5))
    w = 5.5
    c.polygon([add(lip, mul(side, -w)), add(lip, mul(side, w)), add(add(lip, mul(down, jaw)), mul(side, w - 1.5)),
               add(add(lip, mul(down, jaw)), mul(side, -(w - 1.5)))], MOUTH[0])
    c.capsule(add(add(lip, mul(down, jaw * 0.5)), mul(side, -2)), add(add(lip, mul(down, jaw * 0.5)), mul(side, 2)),
              1.0, MOUTH[1])
    for s in (-1, 1):
        root = add(lip, mul(side, s * 3.5))
        c.polygon([add(root, mul(side, -1)), add(root, mul(side, 1)), add(root, mul(down, 2.5 + jaw * 0.3))],
                  TOOTH[1])
        low = add(add(lip, mul(down, jaw)), mul(side, s * 2.5))
        c.polygon([add(low, mul(side, -0.9)), add(low, mul(side, 0.9)), add(low, mul(up, 2.2))], TOOTH[0])


def draw_claw_trails(c):
    for k in range(3):
        a = (106 + k * 3, 30 + k * 4)
        b = (66 + k * 4, 86 + k * 3)
        for i in range(41):
            t = i / 40
            r = 0.4 + 1.0 * (1 - abs(t - 0.45) * 1.6)
            c.circle(add(a, mul(sub(b, a), t)), max(0.8, r), SMEAR, "noline")


def texture(c):
    """Mottled skin so the pink isn't flat plastic."""
    for y in range(c.h):
        for x in range(c.w):
            if c.tag[y][x] == "skin" and c.px[y][x] != MUSCLE and hash01(x // 2, y // 2, 71) < 0.06:
                c.px[y][x] = SKIN[0]


def draw_frame(p):
    c = Canvas(128, 128)
    up, side = axes(p)
    if p["blood"] >= 2:
        pool(c, mul(add(p["pL"], p["neck"]), 0.5)[0], half=30, color=BLOOD[0])
    draw_leg(c, p["pL"], p["kL"], p["aL"], p["fL"])
    draw_leg(c, p["pR"], p["kR"], p["aR"], p["fR"])
    draw_torso(c, p, up, side)
    draw_arm(c, p["sL"], p["eL"], p["hL"])
    draw_arm(c, p["sR"], p["eR"], p["hR"])
    draw_head(c, p, up, side)
    texture(c)
    if p["blood"]:
        splashes(c, mul(add(add(p["sL"], p["sR"]), add(p["pL"], p["pR"])), 0.25), 73, count=14,
                 spread=18, ramp=BLOOD)
    c.outline(OUTLINE)
    if p["smear"]:
        draw_claw_trails(c)
    return c


if __name__ == "__main__":
    save_sheet("melee_demon", [draw_frame(p) for p in POSES], sys.argv[1] if len(sys.argv) > 1 else None)
