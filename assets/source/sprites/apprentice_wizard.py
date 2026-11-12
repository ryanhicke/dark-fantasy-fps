"""Generates the apprentice wizard sprite sheet (front-facing only).

Brownish-grey robe with the hood up; no face in the hood's dark, only two
glowing red eyes. Brown belt hung with potion bottles. Casts fireballs.
One frame = 1.8 m.

Run from the project root:
    python assets/source/sprites/apprentice_wizard.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import sys

from sheet_tools import (Canvas, add, mul, rotate, HUMAN, HUMAN_UPPER, axes, fit, human_kneel,
                         human_limp, human_pain, human_reel, human_walk, shifted, pool, splashes,
                         save_sheet)
from robes import draw_belt, draw_fireball, draw_robe, draw_shoes, draw_sleeve

OUTLINE = (14, 11, 10, 255)
ROBE = ((62, 55, 48, 255), (98, 88, 76, 255), (132, 120, 104, 255))
BELT = ((60, 38, 20, 255), (100, 64, 36, 255), (136, 94, 54, 255))
BRASS = ((110, 88, 44, 255), (166, 136, 72, 255), (214, 186, 112, 255))
SHOE = ((40, 28, 20, 255), (66, 46, 30, 255), (92, 66, 44, 255))
SKIN = ((120, 98, 86, 255), (164, 138, 120, 255), (196, 172, 152, 255))
VOID = (8, 6, 6, 255)
EYE_GLOW = (120, 10, 8, 255)
EYE = (255, 44, 30, 255)
EYE_HOT = (255, 190, 160, 255)
EYE_DEAD = (60, 14, 12, 255)
POTIONS = (((120, 20, 24, 255), (210, 50, 50, 255)),
           ((26, 96, 40, 255), (70, 190, 80, 255)),
           ((28, 52, 120, 255), (80, 130, 230, 255)))
GLASS = (226, 236, 240, 255)
CORK = (150, 112, 70, 255)


def pose(**overrides):
    p = dict(HUMAN)
    # Hands folded into the sleeves in front of the belly.
    p.update(eL=(46, 50), hL=(58, 60), eR=(82, 50), hR=(70, 60),
             fireball=None, dead=False, blood=0)
    p.update(overrides)
    return p


def walk(phase):
    p = human_walk(pose(eL=(44, 50), hL=(46, 64), eR=(84, 50), hR=(82, 64)), phase)
    if phase == 1:
        p = dict(p, hR=(80, 60))
    elif phase == 3:
        p = dict(p, hL=(48, 60))
    return p


POSES = [
    pose(),
    walk(0), walk(1), walk(2), walk(3),
    # windup: hands cupped before the chest, a fireball swelling between them
    pose(eL=(42, 46), hL=(54, 46), eR=(86, 46), hR=(74, 46), fireball=((64, 44), 6.5)),
    # attack: one arm thrust at the viewer, the fireball bursting from the palm
    shifted(pose(eL=(48, 40), hL=(58, 36), eR=(88, 48), hR=(90, 62), fireball=((58, 32), 9.5)),
            1, 0, HUMAN_UPPER),
    dict(human_pain(pose()), blood=1),
    dict(human_reel(pose()), blood=1),
    dict(human_kneel(pose()), blood=1, dead=True),
    dict(fit(human_limp(pose()), -55, list(HUMAN)), blood=1, dead=True),
    dict(fit(human_limp(pose()), -90, list(HUMAN)), blood=2, dead=True),
]


def draw_potions(c, p, up, side):
    down = mul(up, -1)
    for i, (dark, bright) in enumerate(POTIONS):
        anchor = add(add(p["pL"], mul(side, -2 + i * 6)), mul(down, 3))
        bottle = add(anchor, mul(down, 4 + (i % 2)))
        c.capsule(anchor, bottle, 0.9, CORK)
        c.circle(bottle, 2.8, dark)
        c.circle(add(bottle, mul(down, 0.6)), 1.9, bright)
        c.set(*add(add(bottle, mul(up, 1)), mul(side, -1)), GLASS)


def draw_hood(c, p, up, side):
    head = p["head"]
    down = mul(up, -1)
    hood = []
    for i in range(15):
        v = rotate(up, (0, 0), -112 + i * (224 / 14))
        hood.append(add(add(head, mul(up, 1)), mul(v, 11)))
    # The hood's tip and its fall onto the shoulders.
    hood.insert(7, add(head, mul(up, 15)))
    hood.append(add(add(head, mul(down, 9)), mul(side, 12)))
    hood.append(add(add(head, mul(down, 9)), mul(side, -12)))
    c.shaded_polygon(hood, ROBE, "robe")
    c.circle(add(head, mul(down, 1)), 6.6, VOID)
    c.capsule(add(add(head, mul(down, 1)), mul(up, 6)), add(add(head, mul(down, 1)), mul(down, 4)), 5.0, VOID)
    # Glowing eyes; dim and lifeless once dead.
    for s in (-1, 1):
        eye = add(add(head, mul(side, s * 2.6)), mul(up, 0.5))
        if p["dead"]:
            c.set(*eye, EYE_DEAD)
            continue
        c.capsule(add(eye, mul(side, -1)), add(eye, mul(side, 1)), 1.3, EYE_GLOW)
        c.capsule(add(eye, mul(side, -0.6)), add(eye, mul(side, 0.6)), 0.6, EYE)
        c.set(*eye, EYE_HOT)


def draw_frame(p):
    c = Canvas(128, 128)
    up, side = axes(p)
    if p["blood"] >= 2:
        pool(c, mul(add(p["pL"], p["neck"]), 0.5)[0])
    draw_shoes(c, p, SHOE)
    draw_robe(c, p, up, side, ROBE)
    draw_belt(c, p, side, BELT, BRASS)
    draw_potions(c, p, up, side)
    draw_hood(c, p, up, side)
    draw_sleeve(c, p["sR"], p["eR"], p["hR"], ROBE, SKIN)
    draw_sleeve(c, p["sL"], p["eL"], p["hL"], ROBE, SKIN)
    if p["fireball"]:
        draw_fireball(c, *p["fireball"])
    if p["blood"]:
        splashes(c, mul(add(add(p["sL"], p["sR"]), add(p["pL"], p["pR"])), 0.25), 29)
    c.outline(OUTLINE)
    return c


if __name__ == "__main__":
    save_sheet("apprentice_wizard", [draw_frame(p) for p in POSES],
               sys.argv[1] if len(sys.argv) > 1 else None)
