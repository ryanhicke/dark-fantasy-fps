"""Generates the armored mercenary sprite sheet (front-facing only).

Chainmail coif, plate cuirass and pauldrons, mail sleeves and chausses,
blonde goatee, two-handed warhammer. One frame = 1.8 m.

Run from the project root:
    python assets/source/sprites/armored_mercenary.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import sys

from sheet_tools import (Canvas, add, mul, norm, sub, HUMAN, HUMAN_UPPER, axes, fit,
                         human_kneel, human_limp, human_pain, human_reel, human_walk,
                         shifted, splashes, pool, smear_arc, save_sheet, GROUND)

OUTLINE = (14, 12, 12, 255)
SKIN = ((140, 92, 70, 255), (186, 134, 104, 255), (214, 166, 132, 255))
BLONDE = ((150, 112, 44, 255), (204, 164, 78, 255), (236, 206, 128, 255))
MAIL = ((58, 60, 66, 255), (104, 108, 116, 255), (150, 154, 162, 255))
PLATE = ((70, 74, 84, 255), (136, 142, 152, 255), (206, 212, 220, 255))
LEATHER = ((50, 32, 20, 255), (86, 56, 32, 255), (120, 82, 48, 255))
BOOT = ((30, 22, 16, 255), (56, 40, 28, 255), (82, 60, 42, 255))
# Blackened iron, so the hammer head stands out against the polished plate.
IRON = ((34, 34, 40, 255), (70, 72, 80, 255), (128, 132, 140, 255))
WOOD = ((66, 42, 24, 255), (106, 70, 40, 255), (142, 100, 60, 255))
EYE = (28, 22, 30, 255)
SMEAR = (190, 194, 200, 255)

HAFT = 62  # haft length in px (~0.9 m), head at the far end


def pose(**overrides):
    p = dict(HUMAN)
    # Port-arms: hands low-left and high-right on the haft, head over the right shoulder.
    p.update(eL=(42, 54), hL=(54, 66), eR=(88, 48), hR=(76, 54),
             hammer=((0.55, -0.83), 42), hammer_behind=False, blood=0, dropped=False)
    p.update(overrides)
    return p


def walk(phase):
    p = human_walk(pose(), phase)
    if phase in (1, 3):
        p = dict(p, hammer=((0.6, -0.8), 42))
    return p


DEATH_BASE = dict(hammer=None)

POSES = [
    pose(),
    walk(0), walk(1), walk(2), walk(3),
    # windup: hammer hauled up over the right shoulder, head behind him
    pose(eL=(38, 36), hL=(46, 24), eR=(70, 40), hR=(56, 30),
         hammer=((-0.8, -0.6), 22), hammer_behind=True),
    # attack: smashed down across the body, head by his left foot
    shifted(pose(eL=(52, 50), hL=(66, 64), eR=(84, 52), hR=(74, 70),
                 hammer=((0.42, 0.91), 40), smear=True), 2, 3, HUMAN_UPPER),
    dict(human_pain(pose(hammer=((0.9, -0.44), 34))), blood=1, hL=(36, 52), eL=(36, 44)),
    dict(human_reel(pose(hammer=((0.8, 0.6), 34))), blood=1),
    dict(human_kneel(pose(hammer=None)), blood=1, dropped=True),
    dict(fit(human_limp(pose(hammer=None)), -55, list(HUMAN)), blood=1, dropped=True),
    dict(fit(human_limp(pose(hammer=None)), -90, list(HUMAN)), blood=2, dropped=True),
]


def mail_texture(c):
    """Rows of rings: darken every other pixel in a staggered pattern."""
    for y in range(c.h):
        for x in range(c.w):
            if c.tag[y][x] == "mail" and (x + (y % 2)) % 2 == 0 and c.px[y][x] != MAIL[0]:
                c.px[y][x] = MAIL[0] if y % 2 else MAIL[1]


def draw_hammer(c, grip, direction, offset):
    """grip: a hand on the haft; offset: px from that hand to the head."""
    d = norm(direction)
    perp = (-d[1], d[0])
    butt = add(grip, mul(d, offset - HAFT))
    head = add(grip, mul(d, offset))
    c.capsule(butt, head, 1.7, WOOD[1])
    c.capsule(add(butt, mul(perp, -0.6)), add(head, mul(perp, -0.6)), 0.5, WOOD[2])
    c.shaded_circle(butt, 2.2, IRON)
    # Head: a squat block, flat face one side, spike the other, top spike.
    block = [add(add(head, mul(perp, -7)), mul(d, -5)), add(add(head, mul(perp, 7)), mul(d, -5)),
             add(add(head, mul(perp, 7)), mul(d, 5)), add(add(head, mul(perp, -7)), mul(d, 5))]
    c.shaded_polygon(block, IRON)
    c.polygon([add(add(head, mul(perp, 7)), mul(d, -3)), add(add(head, mul(perp, 7)), mul(d, 3)),
               add(head, mul(perp, 15))], IRON[1])
    c.polygon([add(add(head, mul(perp, -6)), mul(d, -4.5)), add(add(head, mul(perp, -6)), mul(d, 4.5)),
               add(head, mul(perp, -9))], IRON[0])
    c.polygon([add(add(head, mul(d, 4)), mul(perp, -2)), add(add(head, mul(d, 4)), mul(perp, 2)),
               add(head, mul(d, 10))], IRON[2])


def draw_dropped_hammer(c):
    y = GROUND - 2
    c.capsule((10, y), (64, y), 1.7, WOOD[1])
    head = (66, y - 3)
    c.shaded_polygon([(62, y - 9), (70, y - 9), (70, y + 2), (62, y + 2)], IRON)
    c.polygon([(62, y - 9), (70, y - 9), (66, y - 16)], IRON[1])
    c.set(*head, IRON[2])


def draw_leg(c, hip, knee, foot):
    c.shaded_capsule(hip, knee, 6.0, MAIL, "mail")
    c.shaded_capsule(knee, foot, 4.8, MAIL, "mail")
    c.shaded_circle(knee, 4.4, PLATE)  # poleyn
    boot_top = add(knee, mul(sub(foot, knee), 0.5))
    c.shaded_capsule(boot_top, foot, 5.2, BOOT)
    c.shaded_capsule(add(foot, (-2, 2)), add(foot, (3, 2)), 3.4, BOOT)


def draw_torso(c, p, up, side):
    sL, sR, pL, pR = p["sL"], p["sR"], p["pL"], p["pR"]
    down = mul(up, -1)
    # Mail hauberk skirt below the cuirass.
    skirt = [add(pL, mul(side, -5)), add(pR, mul(side, 5)),
             add(add(pR, mul(side, 6)), mul(down, 12)), add(add(pL, mul(side, -6)), mul(down, 12))]
    c.shaded_polygon(skirt, MAIL, "mail")
    # Cuirass: wide chest narrowing to the waist, with a centre ridge.
    cuirass = [add(sL, mul(up, 1)), add(sR, mul(up, 1)),
               add(add(sR, mul(down, 18)), mul(side, 1)),
               add(pR, mul(side, 3)), add(add(pR, mul(down, 3)), mul(side, -2)),
               add(add(pL, mul(down, 3)), mul(side, 2)), add(pL, mul(side, -3)),
               add(add(sL, mul(down, 18)), mul(side, -1))]
    c.shaded_polygon(cuirass, PLATE)
    neck = add(p["neck"], mul(down, 4))
    hip_mid = mul(add(pL, pR), 0.5)
    c.capsule(neck, add(hip_mid, mul(up, 2)), 0.6, PLATE[2])
    c.capsule(add(neck, mul(side, 1)), add(add(hip_mid, mul(up, 2)), mul(side, 1)), 0.5, PLATE[0])
    # Waist lame and belt.
    c.capsule(add(pL, mul(side, -3)), add(pR, mul(side, 3)), 2.0, LEATHER[1])
    c.shaded_circle(hip_mid, 2.2, PLATE)
    # Pauldrons.
    for s in (sL, sR):
        c.shaded_circle(add(s, mul(up, 1)), 7.4, PLATE)
        c.capsule(add(add(s, mul(down, 4)), mul(side, -6)), add(add(s, mul(down, 4)), mul(side, 6)),
                  0.6, PLATE[0])


def draw_arm(c, shoulder, elbow, hand):
    c.shaded_capsule(shoulder, elbow, 4.4, MAIL, "mail")
    c.shaded_capsule(elbow, hand, 3.8, MAIL, "mail")
    c.shaded_capsule(add(elbow, mul(sub(hand, elbow), 0.4)), add(elbow, mul(sub(hand, elbow), 0.9)),
                     4.2, LEATHER)  # gauntlet cuff
    c.shaded_circle(hand, 3.8, LEATHER)


def draw_head(c, p, up, side):
    head = p["head"]
    down = mul(up, -1)
    # Mail coif: hood of rings over head, neck and the top of the chest.
    c.shaded_circle(add(head, mul(down, 4)), 11.5, MAIL, "mail")
    c.shaded_circle(add(head, mul(up, 1)), 10, MAIL, "mail")
    # Face opening.
    face = add(head, mul(down, 1.5))
    c.shaded_circle(face, 6.6, SKIN, "skin")
    c.capsule(add(add(face, mul(up, 5.5)), mul(side, -6)), add(add(face, mul(up, 5.5)), mul(side, 6)),
              1.5, MAIL[0])  # coif rim over the brow
    for s in (-2.5, 2.5):
        eye = add(add(face, mul(up, 2)), mul(side, s))
        c.set(*eye, EYE)
        c.capsule(add(add(eye, mul(up, 1.5)), mul(side, -1.5)), add(add(eye, mul(up, 1.5)), mul(side, 1.5)),
                  0.5, BLONDE[1])  # blonde brows
    c.set(*add(face, mul(down, 0.5)), SKIN[0])
    # Goatee: moustache and a pointed chin beard.
    c.capsule(add(add(face, mul(down, 2.5)), mul(side, -3)), add(add(face, mul(down, 2.5)), mul(side, 3)),
              1.0, BLONDE[1])
    c.polygon([add(add(face, mul(down, 3)), mul(side, -2.5)), add(add(face, mul(down, 3)), mul(side, 2.5)),
               add(face, mul(down, 9))], BLONDE[1])
    c.set(*add(face, mul(down, 4)), BLONDE[2])
    for i in (-1, 0, 1):
        c.set(*add(add(face, mul(down, 3.8)), mul(side, i)), SKIN[0])


def draw_frame(p):
    c = Canvas(128, 128)
    up, side = axes(p)
    if p["blood"] >= 2:
        pool(c, mul(add(p["pL"], p["neck"]), 0.5)[0])
    if p["dropped"]:
        draw_dropped_hammer(c)
    if p["hammer"] is not None and p["hammer_behind"]:
        draw_hammer(c, p["hL"], *p["hammer"])
    draw_leg(c, p["pL"], p["kL"], p["fL"])
    draw_leg(c, p["pR"], p["kR"], p["fR"])
    draw_torso(c, p, up, side)
    draw_head(c, p, up, side)
    if p.get("smear"):
        smear_arc(c, (62, 66), 40, -55, 50, SMEAR)
    draw_arm(c, p["sR"], p["eR"], p["hR"])
    draw_arm(c, p["sL"], p["eL"], p["hL"])
    if p["hammer"] is not None and not p["hammer_behind"]:
        # Over the arms so the head is never hidden; fists go back on top.
        draw_hammer(c, p["hL"], *p["hammer"])
        c.shaded_circle(p["hL"], 3.8, LEATHER)
        c.shaded_circle(p["hR"], 3.8, LEATHER)
    mail_texture(c)
    if p["blood"]:
        splashes(c, mul(add(add(p["sL"], p["sR"]), add(p["pL"], p["pR"])), 0.25), 23)
    c.outline(OUTLINE)
    return c


if __name__ == "__main__":
    save_sheet("armored_mercenary", [draw_frame(p) for p in POSES],
               sys.argv[1] if len(sys.argv) > 1 else None)
