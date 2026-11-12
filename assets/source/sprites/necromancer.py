"""Generates the necromancer sprite sheet (front-facing only).

Black robes with the hood down around his shoulders, gaunt pale face,
slicked black hair and a pointed black beard, a skull medallion on a chain,
green belt and green leather shoes. Casts fireballs from a raised hand.
One frame = 2.1 m (he stands a head taller than his apprentices).

Run from the project root:
    python assets/source/sprites/necromancer.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import sys

from sheet_tools import (Canvas, add, mul, HUMAN, HUMAN_UPPER, axes, fit, human_kneel,
                         human_limp, human_pain, human_reel, human_walk, line, pool, shifted,
                         splashes, save_sheet)
from robes import draw_belt, draw_fireball, draw_robe, draw_shoes, draw_sleeve

OUTLINE = (8, 7, 9, 255)
ROBE = ((16, 16, 20, 255), (36, 34, 42, 255), (64, 60, 74, 255))
GREEN = ((26, 74, 34, 255), (46, 120, 56, 255), (90, 168, 88, 255))
SHOE = ((20, 56, 26, 255), (38, 96, 46, 255), (70, 140, 72, 255))
SILVER = ((96, 96, 104, 255), (150, 150, 160, 255), (210, 210, 218, 255))
SKIN = ((150, 128, 118, 255), (196, 176, 160, 255), (222, 206, 190, 255))
HAIR = ((10, 9, 11, 255), (26, 24, 28, 255), (52, 48, 56, 255))
BONE = ((150, 140, 112, 255), (212, 204, 178, 255), (240, 236, 220, 255))
EYE = (40, 120, 50, 255)
SOCKET = (20, 16, 14, 255)
MOUTH = (90, 50, 50, 255)


def pose(**overrides):
    p = dict(HUMAN)
    p.update(eL=(42, 50), hL=(41, 66), eR=(86, 50), hR=(87, 66), fireball=None, blood=0, dead=False)
    p.update(overrides)
    return p


def walk(phase):
    p = human_walk(pose(), phase)
    if phase == 1:
        p = dict(p, hL=(44, 62), hR=(86, 68))
    elif phase == 3:
        p = dict(p, hL=(40, 68), hR=(84, 62))
    return p


POSES = [
    pose(),
    walk(0), walk(1), walk(2), walk(3),
    # windup: right hand raised high, a fireball kindling above it
    pose(eL=(36, 26), hL=(34, 12), fireball=((34, 6), 5.5), eR=(88, 48), hR=(80, 58)),
    # attack: hurls it at the viewer, palm out
    shifted(pose(eL=(46, 42), hL=(54, 36), fireball=((54, 32), 9), eR=(90, 46), hR=(96, 58)),
            1, 0, HUMAN_UPPER),
    dict(human_pain(pose()), blood=1),
    dict(human_reel(pose()), blood=1),
    dict(human_kneel(pose()), blood=1, dead=True),
    dict(fit(human_limp(pose()), -55, list(HUMAN)), blood=1, dead=True),
    dict(fit(human_limp(pose()), -90, list(HUMAN)), blood=2, dead=True),
]


def draw_lowered_hood(c, p, up, side):
    """The hood bunched behind his neck and over the shoulders."""
    neck = p["neck"]
    down = mul(up, -1)
    # A thick roll of cloth across the shoulders, sitting below the jaw line.
    c.shaded_capsule(add(add(neck, mul(side, -9)), mul(down, 2)), add(add(neck, mul(side, 9)), mul(down, 2)),
                     5.5, ROBE, "robe")
    c.capsule(add(add(neck, mul(side, -8)), mul(down, 4)), add(add(neck, mul(side, 8)), mul(down, 4)),
              0.6, ROBE[0], "robe")


def draw_head(c, p, up, side):
    head = p["head"]
    down = mul(up, -1)
    c.shaded_capsule(p["neck"], head, 3.8, SKIN, "skin")
    c.shaded_circle(head, 7.0, SKIN, "skin")
    # Gaunt cheeks, slicked-back black hair with a widow's peak.
    for s in (-1, 1):
        c.set(*add(add(head, mul(side, s * 4)), mul(down, 2)), SKIN[0])
    c.shaded_polygon([add(add(head, mul(side, -7.4)), mul(up, 1)), add(add(head, mul(side, -6)), mul(up, 6)),
                      add(head, mul(up, 7.8)), add(add(head, mul(side, 6)), mul(up, 6)),
                      add(add(head, mul(side, 7.4)), mul(up, 1)), add(add(head, mul(side, 3)), mul(up, 4)),
                      add(head, mul(up, 2.2)), add(add(head, mul(side, -3)), mul(up, 4))], HAIR)
    # Heavy-lidded eyes with a sickly green glint.
    for s in (-1, 1):
        eye = add(add(head, mul(side, s * 2.6)), mul(up, 0.6))
        c.capsule(add(eye, mul(side, -1)), add(eye, mul(side, 1)), 0.6, SOCKET)
        if not p["dead"]:
            c.set(*eye, EYE)
        c.capsule(add(add(eye, mul(up, 1.6)), mul(side, -s * 1.5)), add(add(eye, mul(up, 2.4)), mul(side, s * 1.5)),
                  0.5, HAIR[0])
    c.set(*add(head, mul(down, 1.4)), SKIN[0])
    # Moustache and a long pointed beard.
    for s in (-1, 1):  # thin moustache drooping at the corners
        c.capsule(add(add(head, mul(down, 3.4)), mul(side, s * 0.5)),
                  add(add(head, mul(down, 4.6)), mul(side, s * 3)), 0.5, HAIR[1])
    c.shaded_polygon([add(add(head, mul(down, 5.4)), mul(side, -3.2)), add(add(head, mul(down, 5.4)), mul(side, 3.2)),
                      add(head, mul(down, 16))], HAIR)
    for i in (-1, 0, 1):
        c.set(*add(add(head, mul(down, 4.4)), mul(side, i)), MOUTH)


def draw_medallion(c, p, up, side):
    neck = p["neck"]
    down = mul(up, -1)
    pendant = add(neck, mul(down, 16))
    line(c, add(add(neck, mul(side, -6)), mul(down, 2)), pendant, SILVER[1])
    line(c, add(add(neck, mul(side, 6)), mul(down, 2)), pendant, SILVER[1])
    skull = add(pendant, mul(down, 3))
    c.shaded_circle(skull, 3.4, BONE)
    c.capsule(add(skull, mul(down, 1)), add(skull, mul(down, 3)), 2.0, BONE[1])
    for s in (-1, 1):
        c.set(*add(add(skull, mul(side, s * 1.3)), mul(down, 0.3)), SOCKET)
    c.set(*add(skull, mul(down, 2.6)), SOCKET)


def draw_frame(p):
    c = Canvas(128, 128)
    up, side = axes(p)
    if p["blood"] >= 2:
        pool(c, mul(add(p["pL"], p["neck"]), 0.5)[0])
    draw_shoes(c, p, SHOE)
    draw_robe(c, p, up, side, ROBE, flare=10)
    draw_lowered_hood(c, p, up, side)
    draw_belt(c, p, side, GREEN, SILVER)
    draw_medallion(c, p, up, side)
    draw_head(c, p, up, side)
    draw_sleeve(c, p["sR"], p["eR"], p["hR"], ROBE, SKIN)
    draw_sleeve(c, p["sL"], p["eL"], p["hL"], ROBE, SKIN)
    if p["fireball"]:
        draw_fireball(c, *p["fireball"], seed=3)
    if p["blood"]:
        splashes(c, mul(add(add(p["sL"], p["sR"]), add(p["pL"], p["pR"])), 0.25), 31)
    c.outline(OUTLINE)
    return c


if __name__ == "__main__":
    save_sheet("necromancer", [draw_frame(p) for p in POSES], sys.argv[1] if len(sys.argv) > 1 else None)
