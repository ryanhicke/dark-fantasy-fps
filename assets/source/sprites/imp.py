"""Generates the imp sprite sheet (front-facing only).

A small blue-skinned demon with white horns, a black pointed goatee and a
wicked grin. No wings: it floats on a swirl of violet magic under its
dangling feet. Throws magic missiles. One frame = 1.2 m; the frame's bottom
edge is the enemy's origin, so the corpse lands on the floor.

Run from the project root:
    python assets/source/sprites/imp.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import sys

from sheet_tools import (Canvas, add, hash01, mul, norm, rotate, sub, axes, fit, orb, pool,
                         shifted, splashes, save_sheet)

OUTLINE = (10, 10, 24, 255)
SKIN = ((34, 54, 120, 255), (64, 98, 184, 255), (116, 148, 224, 255))
HORN = ((150, 146, 136, 255), (214, 210, 200, 255), (246, 244, 236, 255))
GOATEE = ((8, 8, 10, 255), (22, 22, 26, 255), (44, 44, 52, 255))
CLAW = (30, 22, 40, 255)
EYE = (255, 214, 40, 255)
EYE_GLOW = (170, 120, 20, 255)
EYE_DEAD = (60, 60, 80, 255)
MOUTH = (16, 6, 20, 255)
TOOTH = (232, 230, 220, 255)
MAGIC = ((90, 30, 150, 255), (150, 70, 230, 255), (210, 150, 255, 255), (250, 230, 255, 255))
MISSILE = ((140, 30, 160, 255), (220, 80, 255, 255), (250, 190, 255, 255), (255, 250, 255, 255))
BLOOD = ((60, 10, 40, 255), (100, 20, 60, 255))

# Squat, big-headed proportions: about 0.75 m from horns to toes.
BASE = {
    "head": (64, 42), "neck": (64, 54),
    "sL": (55, 57), "sR": (73, 57),
    "eL": (48, 66), "eR": (80, 66),
    "hL": (46, 76), "hR": (82, 76),
    "pL": (59, 73), "pR": (69, 73),
    "kL": (57, 83), "kR": (71, 83),
    "fL": (56, 93), "fR": (72, 93),
}
JOINTS = list(BASE)
UPPER = ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR", "pL", "pR")
ALL = tuple(JOINTS)


def pose(**overrides):
    p = dict(BASE)
    p.update(grin=2, aura=0, missile=None, blood=0, dead=False, flying=True)
    p.update(overrides)
    return p


def hover(phase):
    """Bobbing in the air; the aura swirls round from frame to frame."""
    bob = (0, -2, -3, -1)[phase]
    p = shifted(pose(aura=phase), 0, bob, ALL)
    sway = (-1, 0, 1, 0)[phase]
    p.update(fL=add(p["fL"], (sway, 0)), fR=add(p["fR"], (sway, 0)),
             hL=add(p["hL"], (0, -sway)), hR=add(p["hR"], (0, sway)))
    return p


def limp():
    return pose(eL=(54, 66), hL=(55, 76), eR=(74, 66), hR=(73, 76), kL=(60, 83), kR=(68, 83),
                fL=(60, 93), fR=(68, 93), flying=False, dead=True)


POSES = [
    pose(),
    hover(0), hover(1), hover(2), hover(3),
    # windup: a missile crackles in the raised right hand
    pose(eL=(44, 54), hL=(42, 42), missile=((42, 36), 5.5), eR=(84, 62), hR=(88, 70), grin=4),
    # attack: flings it at the viewer
    pose(eL=(50, 60), hL=(56, 56), missile=((56, 52), 7.5), eR=(86, 60), hR=(92, 66), grin=4),
    # pain
    pose(head=(69, 43), neck=(66, 54), eL=(42, 60), hL=(36, 66), eR=(86, 60), hR=(92, 66), grin=1, blood=1),
    # death: the magic gutters out
    dict(shifted(pose(head=(60, 46), eL=(42, 58), hL=(36, 50), eR=(86, 58), hR=(92, 50), grin=3, blood=1,
                      dead=True), 0, 6, ALL), aura=-1),
    # death: tumbling out of the air
    dict(fit(limp(), 60, JOINTS, ground_gap=34), blood=1),
    dict(fit(limp(), 85, JOINTS, ground_gap=14), blood=1),
    # corpse on the floor
    dict(fit(limp(), 90, JOINTS, ground_gap=4), blood=2),
]


def draw_aura(c, p, phase):
    """Swirling violet magic it floats on, below the feet."""
    feet = mul(add(p["fL"], p["fR"]), 0.5)
    centre = add(feet, (0, 10))
    strength = 1.0 if phase >= 0 else 0.35
    # A glowing disc, then rings of motes spinning round it.
    if strength == 1.0:
        for r, color in ((13, MAGIC[0]), (9, MAGIC[1]), (4, MAGIC[2])):
            c.polygon([add(centre, (r * x, r * 0.3 * y)) for x, y in
                       ((rotate((1, 0), (0, 0), a)[0], rotate((1, 0), (0, 0), a)[1]) for a in range(0, 360, 30))],
                      color, "noline")
    for ring in range(3):
        rx = 18 - ring * 4
        ry = 5 - ring
        for i in range(12):
            a = i * 30 + phase * 22 + ring * 50
            d = rotate((1, 0), (0, 0), a)
            pt = add(centre, (d[0] * rx, d[1] * ry - ring * 5))
            if hash01(i, ring, 7 + phase) < 0.8 * strength:
                c.circle(pt, 1.7 - ring * 0.3, MAGIC[1 + (i + ring) % 3], "noline")
    for i in range(4):
        x = centre[0] - 8 + i * 5 + (phase % 2) * 2
        top = centre[1] - 14 - hash01(i, phase, 9) * 6
        if hash01(i, 5, phase) < 0.8 * strength:
            c.capsule((x, centre[1] + 2), (x + 1, top), 0.6, MAGIC[2], "noline")


def draw_head(c, p, up, side):
    head = p["head"]
    up = norm(sub(head, p["neck"]))
    side = (-up[1], up[0])
    down = mul(up, -1)
    # White horns sweeping back and up.
    for s in (-1, 1):
        prev = add(add(head, mul(side, s * 5)), mul(up, 7))
        for i in range(1, 7):
            t = i / 6
            pt = add(add(head, mul(side, s * (5 + 6 * t))), mul(up, 7 + 9 * t))
            c.capsule(prev, pt, 2.4 * (1 - t) + 0.5, HORN[1])
            prev = pt
        c.set(*add(add(head, mul(side, s * 6)), mul(up, 9)), HORN[2])
    # Long pointed ears.
    for s in (-1, 1):
        base = add(add(head, mul(side, s * 9)), mul(up, 1))
        c.polygon([add(base, mul(up, 3)), add(base, mul(up, -3)), add(add(base, mul(side, s * 8)), mul(up, 4))],
                  SKIN[1], "skin")
    # Big head on a small body: wide cranium, narrow chin.
    c.shaded_circle(add(head, mul(up, 1)), 10.5, SKIN, "skin")
    c.shaded_capsule(head, add(head, mul(down, 6)), 6.5, SKIN, "skin")
    for s in (-1, 1):
        eye = add(add(head, mul(side, s * 4)), mul(up, 2))
        if p["dead"]:
            c.capsule(add(eye, mul(side, -1.2)), add(eye, mul(side, 1.2)), 0.6, EYE_DEAD)
        else:
            c.capsule(add(eye, mul(side, -s * 1.6)), add(add(eye, mul(side, s * 1.6)), mul(up, 1)), 1.7, EYE_GLOW)
            c.capsule(add(eye, mul(side, -s * 1.0)), add(add(eye, mul(side, s * 1.0)), mul(up, 0.7)), 0.9, EYE)
        c.capsule(add(add(eye, mul(side, -s * 3)), mul(up, 2.5)), add(add(eye, mul(side, s * 3)), mul(up, 4.6)),
                  0.8, SKIN[0])  # scowling brow
    # Wide grin full of teeth.
    mouth = add(head, mul(down, 3))
    g = p["grin"]
    c.polygon([add(add(mouth, mul(side, -6)), mul(up, 1)), add(add(mouth, mul(side, 6)), mul(up, 1)),
               add(add(mouth, mul(side, 3)), mul(down, g)), add(add(mouth, mul(side, -3)), mul(down, g))], MOUTH)
    for i in range(-2, 3):
        c.set(*add(add(mouth, mul(side, i * 2)), mul(up, 0.2)), TOOTH)
    # Black pointed goatee hanging off the chin.
    chin = add(head, mul(down, 7))
    c.shaded_polygon([add(chin, mul(side, -3)), add(chin, mul(side, 3)), add(add(chin, mul(down, 9)), mul(side, 0.5))],
                     GOATEE)


def draw_limbs(c, p):
    for s, e, h in ((p["sL"], p["eL"], p["hL"]), (p["sR"], p["eR"], p["hR"])):
        c.shaded_capsule(s, e, 2.8, SKIN, "skin")
        c.shaded_capsule(e, h, 2.4, SKIN, "skin")
        c.shaded_circle(h, 2.8, SKIN, "skin")
        d = norm(sub(h, e))
        for k in (-1, 0, 1):
            c.capsule(h, add(h, mul(rotate(d, (0, 0), k * 30), 5)), 0.6, CLAW)


def draw_body(c, p, up, side):
    for hip, knee, foot in ((p["pL"], p["kL"], p["fL"]), (p["pR"], p["kR"], p["fR"])):
        c.shaded_capsule(hip, knee, 3.4, SKIN, "skin")
        c.shaded_capsule(knee, foot, 2.8, SKIN, "skin")
        # Feet hang pointed, toes down.
        toe = add(foot, mul(norm(sub(foot, knee)), 4))
        c.shaded_capsule(foot, toe, 2.2, SKIN, "skin")
        c.set(*add(toe, mul(norm(sub(foot, knee)), 2)), CLAW)
    # Pot belly and narrow shoulders.
    hips = mul(add(p["pL"], p["pR"]), 0.5)
    c.shaded_capsule(p["neck"], hips, 6.5, SKIN, "skin")
    c.shaded_circle(add(hips, mul(up, 5)), 7.0, SKIN, "skin")  # pot belly
    # A thin tail curling out to one side.
    prev = add(hips, mul(side, 4))
    for i in range(1, 9):
        t = i / 8
        pt = add(add(hips, mul(side, 4 + 14 * t)), mul(up, -2 + 10 * t * t))
        c.capsule(prev, pt, 1.3, SKIN[0], "skin")
        prev = pt
    c.polygon([add(prev, (-2, 1)), add(prev, (2, 1)), add(prev, (1, -4))], SKIN[0], "skin")


def draw_frame(p):
    c = Canvas(128, 128)
    up, side = axes(p)
    if p["blood"] >= 2:
        pool(c, mul(add(p["pL"], p["neck"]), 0.5)[0], half=16, color=BLOOD[0])
    if p["flying"] and p["aura"] is not None and p["aura"] >= -1:
        draw_aura(c, p, p["aura"])
    draw_body(c, p, up, side)
    draw_limbs(c, p)
    draw_head(c, p, up, side)
    if p["missile"]:
        orb(c, *p["missile"], MISSILE)
    if p["blood"]:
        splashes(c, mul(add(p["neck"], mul(add(p["pL"], p["pR"]), 0.5)), 0.5), 79, count=8, spread=10, ramp=BLOOD)
    c.outline(OUTLINE)
    return c


if __name__ == "__main__":
    save_sheet("imp", [draw_frame(p) for p in POSES], sys.argv[1] if len(sys.argv) > 1 else None)
