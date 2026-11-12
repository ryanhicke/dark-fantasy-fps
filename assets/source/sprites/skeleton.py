"""Generates the skeleton sprite sheet (front-facing only).

A long-buried human skeleton: bones stained brown with grave dirt and
patched with moss, a rusted horned helmet, swinging another skeleton's
femur as a club. Dies by falling apart into a heap of bones.
One frame = 1.8 m.

Run from the project root:
    python assets/source/sprites/skeleton.py [preview_dir]
AI-authored (Claude): see docs/placeholders.md.
"""

import sys

from sheet_tools import (Canvas, add, hash01, mul, norm, rotate, sub, HUMAN, HUMAN_UPPER,
                         axes, human_kneel, human_pain, human_reel, human_walk, shifted,
                         smear_arc, save_sheet, GROUND)

OUTLINE = (16, 12, 8, 255)
BONE = ((96, 80, 54, 255), (148, 128, 92, 255), (186, 170, 128, 255))
DIRT = ((70, 54, 36, 255), (92, 72, 48, 255))
MOSS = ((58, 70, 40, 255), (82, 96, 52, 255))
SOCKET = (14, 10, 8, 255)
RUST = ((62, 40, 28, 255), (104, 64, 40, 255), (146, 92, 56, 255))
HORN = ((104, 92, 70, 255), (160, 146, 112, 255), (204, 192, 156, 255))
SMEAR = (200, 192, 160, 255)

ARM_R = 1.9
LEG_R = 2.3


def pose(**overrides):
    p = dict(HUMAN)
    # Femur club held low in the right hand, slightly out.
    p.update(eL=(42, 50), hL=(40, 66), club=((-0.3, 0.95), 0), club_behind=False, pile=0)
    p.update(overrides)
    return p


def walk(phase):
    """A stiff, shambling gait: the club arm swings with the steps."""
    p = human_walk(pose(club=((-0.55, -0.83), 0), eL=(40, 50), hL=(42, 64)), phase)
    if phase == 1:
        p = dict(p, hL=(46, 60), hR=(84, 70))
    elif phase == 3:
        p = dict(p, hL=(40, 68), hR=(88, 62))
    return p


POSES = [
    pose(),
    walk(0), walk(1), walk(2), walk(3),
    # windup: club raised high behind the head
    pose(eL=(36, 22), hL=(46, 10), club=((0.94, -0.34), 0), club_behind=True, eR=(90, 44),
         hR=(94, 56)),
    # attack: clubbed down across the body
    shifted(pose(eL=(56, 46), hL=(72, 56), club=((0.55, 0.83), 0), eR=(92, 42), hR=(100, 50),
                 smear=True), 3, 1, HUMAN_UPPER),
    # pain: skull knocked aside, the club arm flung wide
    dict(human_pain(pose(club=((-0.6, -0.8), 0)))),
    # death: falling apart mid-stagger
    dict(human_reel(pose(club=((-0.3, 0.95), 0)))),
    # death: legs folding under it, the club gone
    human_kneel(pose(club=None)),
    # death: crumbling into a heap
    dict(pose(club=None), pile=1),
    # corpse: a heap of bones with the helmet on top
    dict(pose(club=None), pile=2),
]


def bone(c, a, b, r):
    """A long bone: a shaft with knobbly ends."""
    c.shaded_capsule(a, b, r, BONE, "bone")
    c.shaded_circle(a, r * 1.35, BONE, "bone")
    c.shaded_circle(b, r * 1.35, BONE, "bone")


def draw_femur_club(c, grip, direction):
    d = norm(direction)
    perp = (-d[1], d[0])
    butt = add(grip, mul(d, -6))
    tip = add(grip, mul(d, 30))
    c.shaded_capsule(butt, tip, 2.4, BONE, "bone")
    # Femur ends: a ball head at the far end, twin knuckles at the butt.
    c.shaded_circle(add(tip, mul(perp, 2)), 4.0, BONE, "bone")
    c.shaded_circle(add(add(tip, mul(perp, -2.5)), mul(d, -2)), 3.0, BONE, "bone")
    c.shaded_circle(add(butt, mul(perp, 2.2)), 3.0, BONE, "bone")
    c.shaded_circle(add(butt, mul(perp, -2.2)), 3.0, BONE, "bone")


def draw_skull(c, centre, up, jaw_drop=0.0):
    side = (-up[1], up[0])
    down = mul(up, -1)
    c.shaded_circle(add(centre, mul(up, 1)), 7.2, BONE, "bone")
    c.shaded_capsule(centre, add(centre, mul(down, 4)), 5.2, BONE, "bone")
    for s in (-1, 1):
        eye = add(add(centre, mul(side, s * 3)), mul(down, 0.5))
        c.circle(eye, 2.2, SOCKET)
    c.polygon([add(add(centre, mul(down, 3.5)), mul(side, -1)), add(add(centre, mul(down, 3.5)), mul(side, 1)),
               add(centre, mul(down, 2))], SOCKET)  # nose hole
    jaw = add(centre, mul(down, 6.5 + jaw_drop))
    c.shaded_capsule(add(jaw, mul(side, -4)), add(jaw, mul(side, 4)), 1.8, BONE, "bone")
    for i in range(-3, 4):
        c.set(*add(add(centre, mul(down, 5.2)), mul(side, i)), SOCKET if i % 2 else BONE[2])
        c.set(*add(add(jaw, mul(up, 1.2)), mul(side, i)), SOCKET if i % 2 == 0 else BONE[2])


def draw_helmet(c, centre, up):
    side = (-up[1], up[0])
    down = mul(up, -1)
    dome = []
    for i in range(13):
        v = rotate(up, (0, 0), -90 + i * 15)
        dome.append(add(add(centre, mul(up, 1.5)), mul(v, 8.6)))
    c.shaded_polygon(dome, RUST, "rust")
    c.capsule(add(add(centre, mul(up, 1)), mul(side, -9)), add(add(centre, mul(up, 1)), mul(side, 9)),
              1.4, RUST[0], "rust")
    c.capsule(add(centre, mul(up, 1)), add(centre, mul(down, 4)), 1.0, RUST[1], "rust")  # nasal
    # Curved horns sweeping out and up.
    for s in (-1, 1):
        prev = add(add(centre, mul(side, s * 7)), mul(up, 4))
        for i in range(1, 8):
            t = i / 7
            pt = add(add(centre, mul(side, s * (7 + 9 * t))), mul(up, 4 + 4 * t + 9 * t * t))
            c.capsule(prev, pt, 2.8 * (1 - t) + 0.6, HORN[1])
            prev = pt
        c.set(*add(add(centre, mul(side, s * 9)), mul(up, 6)), HORN[2])


def draw_ribs(c, p, up, side):
    neck, pL, pR = p["neck"], p["pL"], p["pR"]
    down = mul(up, -1)
    hip_mid = mul(add(pL, pR), 0.5)
    c.shaded_capsule(neck, hip_mid, 1.6, BONE, "bone")  # spine
    for i in range(4):
        y = add(neck, mul(down, 7 + i * 5))
        w = 11 - i * 1.2
        for s in (-1, 1):
            a = add(y, mul(side, s * 1.5))
            mid = add(add(y, mul(side, s * w * 0.7)), mul(down, 1))
            end = add(add(y, mul(side, s * w)), mul(down, 4))
            c.capsule(a, mid, 1.2, BONE[1], "bone")
            c.capsule(mid, end, 1.1, BONE[1], "bone")
    c.capsule(p["sL"], p["sR"], 1.6, BONE[1], "bone")  # collarbones
    # Pelvis: a broad saddle with dark hollows.
    c.shaded_polygon([add(pL, mul(side, -5)), add(pR, mul(side, 5)), add(add(pR, mul(side, 3)), mul(down, 6)),
                      add(hip_mid, mul(down, 4)), add(add(pL, mul(side, -3)), mul(down, 6))], BONE, "bone")
    for s in (-1, 1):
        c.circle(add(add(hip_mid, mul(side, s * 4)), mul(down, 2)), 1.6, SOCKET)


def draw_hand(c, hand, forearm):
    d = norm(forearm)
    c.shaded_circle(hand, 2.4, BONE, "bone")
    for k in (-1, 0, 1):
        c.capsule(hand, add(hand, mul(rotate(d, (0, 0), k * 25), 4)), 0.7, BONE[1], "bone")


def draw_body(c, p):
    up, side = axes(p)
    if p.get("club") is not None and p["club_behind"]:
        draw_femur_club(c, p["hL"], p["club"][0])
    for hip, knee, foot in ((p["pL"], p["kL"], p["fL"]), (p["pR"], p["kR"], p["fR"])):
        bone(c, hip, knee, LEG_R)
        bone(c, knee, foot, LEG_R * 0.85)
        c.shaded_capsule(foot, add(foot, (0, 2.5)), 2.6, BONE, "bone")
    draw_ribs(c, p, up, side)
    for s, e, h in ((p["sR"], p["eR"], p["hR"]), (p["sL"], p["eL"], p["hL"])):
        bone(c, s, e, ARM_R)
        bone(c, e, h, ARM_R * 0.85)
        draw_hand(c, h, sub(h, e))
    head_up = norm(sub(p["head"], p["neck"]))
    draw_skull(c, p["head"], head_up)
    draw_helmet(c, p["head"], head_up)
    if p.get("club") is not None and not p["club_behind"]:
        draw_femur_club(c, p["hL"], p["club"][0])
        c.shaded_circle(p["hL"], 2.4, BONE, "bone")


def draw_pile(c, stage):
    """Bones collapsing (stage 1) into a settled heap (stage 2)."""
    rise = 10 if stage == 1 else 0
    for i in range(11):
        cx = 34 + hash01(i, 1, 41) * 60
        cy = GROUND - 4 - hash01(i, 2, 41) * (6 + rise)
        ang = hash01(i, 3, 41) * 180
        half = 5 + hash01(i, 4, 41) * 6
        d = rotate((1, 0), (0, 0), ang)
        bone(c, add((cx, cy), mul(d, -half)), add((cx, cy), mul(d, half)), 1.8)
    # Ribcage lying on its back.
    for i in range(4):
        c.capsule((52, GROUND - 6 - i * 3 - rise), (78, GROUND - 6 - i * 3 - rise), 1.0, BONE[1], "bone")
    c.shaded_capsule((50, GROUND - 8 - rise), (80, GROUND - 8 - rise), 1.4, BONE, "bone")
    draw_femur_club(c, (28, GROUND - 3), (1, 0.05))
    skull = (74, GROUND - 14 - rise * 1.6) if stage == 1 else (70, GROUND - 9)
    up = (0.3, -1) if stage == 1 else (0.6, -0.8)
    draw_skull(c, skull, norm(up), jaw_drop=1.5)
    draw_helmet(c, skull, norm(up))


def weather(c):
    """Grave dirt and moss: blotches tied to position, so they hold still
    from frame to frame wherever a bone sits."""
    for y in range(c.h):
        for x in range(c.w):
            if c.tag[y][x] == "bone":
                n = hash01(x // 2, y // 2, 61)
                if n < 0.13:
                    c.px[y][x] = DIRT[0] if n < 0.06 else DIRT[1]
                elif n > 0.95:
                    c.px[y][x] = MOSS[0] if n > 0.975 else MOSS[1]
            elif c.tag[y][x] == "rust" and hash01(x, y, 67) < 0.18:
                c.px[y][x] = RUST[2] if hash01(x, y, 5) < 0.5 else RUST[0]


def draw_frame(p):
    c = Canvas(128, 128)
    if p["pile"]:
        draw_pile(c, p["pile"])
    else:
        if p.get("smear"):
            smear_arc(c, (60, 50), 40, -70, 60, SMEAR)
        draw_body(c, p)
    weather(c)
    c.outline(OUTLINE)
    return c


if __name__ == "__main__":
    save_sheet("skeleton", [draw_frame(p) for p in POSES], sys.argv[1] if len(sys.argv) > 1 else None)
