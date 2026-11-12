"""Generates the werewolf sprite sheet (front-facing only).

A hunched, towering beast rather than a wolfman: dark grey fur over heavy
muscle, a huge shoulder hump, arms hanging to the knees with long claws,
digitigrade legs, a broad wolf skull with swept-back ears, glowing yellow
eyes and a jaw full of large teeth.

Run from the project root:
    python assets/source/sprites/werewolf.py [preview_dir]

Writes assets/sprites/enemies/werewolf_sheet.png: 128x128 frames (one
frame = 2.4 m, matching the quad in enemies/werewolf/werewolf_sprites.tres)
in a 4x4 grid (512x512):
    0 idle | 1-4 run | 5 windup (rear up) | 6 claw swipe | 7 pain | 8-11 death
AI-authored (Claude): see docs/placeholders.md.
"""

import os
import sys

from pixel_canvas import Canvas, add, hash01, mul, norm, rotate, sub, write_png

FRAME = 128
COLS = 4
ROWS = 4
GROUND = 125

OUTLINE = (10, 9, 11, 255)
FUR = ((30, 30, 35, 255), (60, 60, 68, 255), (100, 100, 110, 255))
FUR_PALE = ((58, 58, 66, 255), (84, 84, 92, 255), (116, 116, 124, 255))
STREAK = (22, 22, 26, 255)
MUSCLE = (24, 24, 29, 255)
MOUTH = ((40, 6, 10, 255), (96, 18, 24, 255))
GUM = (130, 44, 52, 255)
TOOTH = ((150, 140, 108, 255), (214, 206, 176, 255), (240, 236, 214, 255))
CLAW = ((92, 84, 66, 255), (176, 166, 132, 255), (222, 214, 184, 255))
NOSE = (14, 12, 14, 255)
EYE_GLOW = (150, 112, 10, 255)
EYE = (255, 214, 30, 255)
EYE_HOT = (255, 250, 190, 255)
EYE_DEAD = ((70, 58, 20, 255), (110, 92, 30, 255))
BLOOD = ((92, 10, 10, 255), (138, 22, 16, 255))
SMEAR = (196, 190, 170, 255)


# --- poses ---------------------------------------------------------------
# "L" is the viewer's left. "jaw" is how far the mouth hangs open (px).

BASE = {
    "head": (64, 33), "neck": (64, 38),
    "sL": (41, 37), "sR": (87, 37),
    "eL": (30, 64), "eR": (98, 64),
    "hL": (28, 94), "hR": (100, 94),
    "pL": (55, 76), "pR": (73, 76),
    "kL": (50, 95), "kR": (78, 95),
    "aL": (49, 110), "aR": (79, 110),  # hocks: the raised "ankle" of a digitigrade leg
    "fL": (47, 121), "fR": (81, 121),
}
JOINTS = list(BASE)
UPPER = ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR", "pL", "pR")


def pose(**overrides):
    p = dict(BASE)
    p.update({"jaw": 4, "head_tilt": 0, "blood": 0, "smear": False, "dead": False})
    p.update(overrides)
    return p


def shifted(p, dx, dy, keys):
    q = dict(p)
    for k in keys:
        q[k] = (q[k][0] + dx, q[k][1] + dy)
    return q


def run(phase):
    """Loping run: the arm on the lifted leg's opposite side reaches at you."""
    bob = -3 if phase in (1, 3) else 1
    p = pose(jaw=6)
    p = shifted(p, 0, bob, UPPER)
    if phase == 1:
        p.update(kL=(51, 89), aL=(50, 102), fL=(49, 113),
                 eR=(96, 52), hR=(88, 64))
    elif phase == 3:
        p.update(kR=(77, 89), aR=(78, 102), fR=(79, 113),
                 eL=(32, 52), hL=(40, 64))
    elif phase == 0:
        p.update(hL=(32, 88), hR=(97, 96))
    else:
        p.update(hL=(31, 96), hR=(96, 88))
    return p


def limp():
    """Arms dropped, legs together: the base for falling frames."""
    return pose(eL=(40, 60), hL=(40, 84), eR=(88, 60), hR=(88, 84),
                kL=(55, 95), kR=(73, 95), aL=(55, 110), aR=(73, 110),
                fL=(55, 121), fR=(73, 121), jaw=5)


def fit(p, degrees, nudge=0):
    """Rotates the whole body about its feet, then puts it on the ground."""
    pivot = (64, 120)
    q = dict(p)
    for k in JOINTS:
        q[k] = rotate(p[k], pivot, degrees)
    xs = [q[k][0] for k in JOINTS]
    ys = [q[k][1] for k in JOINTS]
    dx = 64 - (min(xs) + max(xs)) / 2 + nudge
    dy = (GROUND - 9) - max(ys)
    return shifted(q, dx, dy, JOINTS)


POSES = [
    # 0 idle: hunched, breathing through a half-open jaw.
    pose(),
    # 1-4 run
    run(0), run(1), run(2), run(3),
    # 5 windup: rears up to full height, arms flung wide, roaring.
    shifted(pose(head=(64, 22), neck=(64, 29), sL=(40, 31), sR=(88, 31),
                 eL=(22, 30), hL=(15, 17), eR=(106, 30), hR=(113, 17), jaw=10),
            0, 1, ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR")),
    # 6 swipe: the viewer-right arm rakes down across the body.
    pose(head=(60, 36), neck=(62, 40), eR=(86, 56), hR=(56, 82), eL=(24, 50), hL=(18, 36),
         jaw=9, smear=True),
    # 7 pain: head wrenched aside, arms pulled in.
    pose(head=(72, 34), neck=(68, 39), head_tilt=24, eL=(36, 58), hL=(44, 74),
         eR=(96, 56), hR=(90, 72), jaw=8, blood=1),
    # 8 death: reeling back, head thrown up, a last howl.
    shifted(pose(head=(68, 26), neck=(66, 33), head_tilt=12, eL=(28, 52), hL=(20, 66),
                 eR=(100, 52), hR=(108, 66), kL=(48, 98), kR=(80, 98), jaw=10, blood=1),
            0, 3, UPPER),
    # 9 death: dropped to its knees, slumped forward.
    shifted(pose(head=(64, 50), neck=(64, 52), sL=(42, 50), sR=(86, 50), eL=(36, 74),
                 hL=(38, 98), eR=(92, 74), hR=(90, 98), pL=(55, 88), pR=(73, 88),
                 kL=(48, 112), kR=(80, 112), aL=(44, 118), aR=(84, 118),
                 fL=(40, 121), fR=(88, 121), jaw=7, blood=1),
            0, 1, UPPER),
    # 10 death: toppling over.
    dict(fit(limp(), -55), blood=1, dead=True),
    # 11 corpse: sprawled on the ground in a pool of blood.
    dict(fit(limp(), -90), blood=2, jaw=6, dead=True),
]


# --- drawing -------------------------------------------------------------

def tuft(c, base, direction, length, width, color, tag="fur"):
    """A spike of fur; drawn behind body parts to roughen the silhouette."""
    d = norm(direction)
    perp = (-d[1], d[0])
    c.polygon([add(base, mul(perp, width)), add(base, mul(perp, -width)),
               add(base, mul(d, length))], color, tag)


def ragged_edge(c, a, b, outward, count, length, seed, radius=0.0):
    out = norm(outward)
    for i in range(count):
        t = (i + 0.5) / count
        base = add(add(a, mul(sub(b, a), t)), mul(out, radius * 0.75))
        jitter = 0.6 + hash01(i, seed, 3) * 0.8
        tuft(c, base, add(out, (0, 0.6)), length * jitter, 2.4, FUR[0])


def draw_claws(c, hand, forearm_dir, length=9):
    d = norm(forearm_dir)
    perp = (-d[1], d[0])
    for k in (-1.5, -0.5, 0.5, 1.5):
        base = add(add(hand, mul(d, 3.5)), mul(perp, k * 2.6))
        tip = add(base, mul(rotate(d, (0, 0), k * 10), length))
        c.polygon([add(base, mul(perp, 1.2)), add(base, mul(perp, -1.2)), tip], CLAW[1])
        c.set(*add(base, mul(sub(tip, base), 0.4)), CLAW[2])


def draw_arm(c, shoulder, elbow, hand, outward, seed):
    ragged_edge(c, shoulder, elbow, outward, 4, 6, seed, 7.0)
    ragged_edge(c, elbow, add(elbow, mul(sub(hand, elbow), 0.6)), outward, 3, 5, seed + 1, 5.4)
    c.shaded_capsule(shoulder, elbow, 7.0, FUR, "fur")          # massive upper arm
    c.shaded_capsule(elbow, hand, 5.4, FUR, "fur")              # corded forearm
    mid = add(shoulder, mul(sub(elbow, shoulder), 0.5))
    c.capsule(add(mid, mul(norm(sub(elbow, shoulder)), -4)),
              add(mid, mul(norm(sub(elbow, shoulder)), 4)), 0.5, MUSCLE, "fur")
    c.shaded_circle(hand, 5.2, FUR, "fur")                      # big clawed hand
    draw_claws(c, hand, sub(hand, elbow))


def draw_leg(c, hip, knee, hock, foot, outward, seed):
    ragged_edge(c, hip, knee, outward, 3, 5, seed, 7.6)
    c.shaded_capsule(hip, knee, 7.6, FUR, "fur")                # heavy thigh
    c.shaded_capsule(knee, hock, 4.6, FUR, "fur")
    c.shaded_capsule(hock, foot, 3.6, FUR, "fur")               # lean lower leg
    c.shaded_capsule(add(foot, (-3, 1)), add(foot, (3, 1)), 3.6, FUR, "fur")  # paw
    for k in (-3, -1, 1, 3):
        toe = add(foot, (k * 1.2, 3))
        c.polygon([add(toe, (-0.9, 0)), add(toe, (0.9, 0)), add(toe, (k * 0.3, 4))], CLAW[1])


def draw_torso(c, p, up, side):
    sL, sR, pL, pR = p["sL"], p["sR"], p["pL"], p["pR"]
    down = mul(up, -1)
    # Shoulder hump: a mass of muscle and fur rising behind the head.
    hump_l = add(add(sL, mul(up, 6)), mul(side, 6))
    hump_r = add(add(sR, mul(up, 6)), mul(side, -6))
    mound = add(p["neck"], mul(up, 7))
    ragged_edge(c, hump_l, hump_r, up, 8, 8, 21, 9.0)
    c.shaded_circle(hump_l, 9.0, FUR, "fur")
    c.shaded_circle(hump_r, 9.0, FUR, "fur")
    c.shaded_circle(mound, 10.0, FUR, "fur")
    # V-shaped torso: broad chest to a narrow waist.
    torso = [add(sL, mul(up, 4)), add(sR, mul(up, 4)),
             add(add(sR, mul(down, 16)), mul(side, 2)),
             add(add(pR, mul(side, 1)), mul(down, 3)),
             add(add(pL, mul(side, -1)), mul(down, 3)),
             add(add(sL, mul(down, 16)), mul(side, -2))]
    c.shaded_polygon(torso, FUR, "fur")
    # Paler, shaggy chest ruff.
    neck = p["neck"]
    ruff = [add(neck, mul(side, -12)), add(neck, mul(side, 12)),
            add(add(neck, mul(down, 12)), mul(side, 9)),
            add(neck, mul(down, 20)),
            add(add(neck, mul(down, 12)), mul(side, -9))]
    c.shaded_polygon(ruff, FUR_PALE, "fur")
    for i in range(5):
        tip = add(add(neck, mul(down, 17 + (i % 2) * 3)), mul(side, (i - 2) * 4))
        tuft(c, add(tip, mul(up, 5)), down, 6, 2, FUR_PALE[1])
    # Muscle: pec lines under the ruff and a few ab ridges down the gut.
    hip_mid = mul(add(pL, pR), 0.5)
    chest = add(neck, mul(down, 21))
    for s in (-1, 1):
        a = add(add(neck, mul(down, 16)), mul(side, s * 15))
        c.capsule(a, add(chest, mul(side, s * 2)), 0.5, MUSCLE, "fur")
    c.capsule(chest, add(hip_mid, mul(up, 5)), 0.5, MUSCLE, "fur")
    for i in range(3):
        y = add(chest, mul(sub(hip_mid, chest), 0.25 + i * 0.22))
        c.capsule(add(y, mul(side, -6)), add(y, mul(side, -2)), 0.5, MUSCLE, "fur")
        c.capsule(add(y, mul(side, 2)), add(y, mul(side, 6)), 0.5, MUSCLE, "fur")


def draw_head(c, p, up, side):
    head = p["head"]
    if p["head_tilt"]:
        up = rotate(up, (0, 0), p["head_tilt"])
        side = (-up[1], up[0])
    down = mul(up, -1)
    jaw = p["jaw"]
    # Swept-back ears.
    for s in (-1, 1):
        base = add(add(head, mul(side, s * 7)), mul(up, 6))
        tip = add(add(head, mul(side, s * 15)), mul(up, 22))
        c.polygon([add(base, mul(side, -5 * s)), add(base, mul(side, 5 * s)), tip], FUR[0], "fur")
        inner = add(base, mul(sub(tip, base), 0.2))
        c.polygon([add(inner, mul(side, -1.5 * s)), add(inner, mul(side, 2 * s)),
                   add(base, mul(sub(tip, base), 0.8))], MOUTH[0])
    # Cheek ruff flaring out to the sides.
    for s in (-1, 1):
        for i in range(3):
            base = add(add(head, mul(side, s * 9)), mul(up, -2 - i * 3))
            tuft(c, base, add(mul(side, s), mul(down, 0.4)), 7 - i, 2.6, FUR[0])
    # Broad skull.
    c.shaded_circle(add(head, mul(up, 2)), 10, FUR, "fur")
    c.shaded_capsule(add(head, mul(up, 2)), add(head, mul(down, 5)), 7.5, FUR, "fur")
    # Heavy brow over deep-set, glowing eyes.
    eye_y = add(head, mul(up, 2.5))
    # The glow goes out when it dies.
    glow, iris, hot = (EYE_DEAD[0], EYE_DEAD[1], EYE_DEAD[1]) if p["dead"] else (EYE_GLOW, EYE, EYE_HOT)
    for s in (-1, 1):
        eye = add(eye_y, mul(side, s * 5.5))
        c.capsule(add(eye, mul(side, -s * 3)), add(add(eye, mul(side, s * 3)), mul(up, 2)),
                  1.6, glow)
        c.capsule(add(eye, mul(side, -s * 2)), add(add(eye, mul(side, s * 2)), mul(up, 1.3)),
                  0.9, iris)
        c.set(*add(eye, mul(side, -s * 0.5)), hot)
        c.capsule(add(add(eye, mul(side, -s * 4)), mul(up, 1.4)),
                  add(add(eye, mul(side, s * 4)), mul(up, 5.0)), 1.2, STREAK)
    # Muzzle coming straight at the viewer: a short, broad snout.
    snout = add(head, mul(down, 3))
    c.shaded_capsule(add(snout, mul(up, 3)), add(snout, mul(down, 2)), 5.0, FUR_PALE, "fur")
    c.capsule(add(add(snout, mul(up, 1)), mul(side, -2.5)),
              add(add(snout, mul(up, 1)), mul(side, 2.5)), 1.8, NOSE)
    c.set(*add(add(snout, mul(up, 1.5)), mul(side, -1.5)), FUR_PALE[2])  # wet glint
    # Gaping mouth under the snout.
    lip = add(snout, mul(down, 4.5))
    w = 7.5
    mouth = [add(lip, mul(side, -w)), add(lip, mul(side, w)),
             add(add(lip, mul(down, jaw)), mul(side, w - 2)),
             add(add(lip, mul(down, jaw + 2)), mul(side, 0)),
             add(add(lip, mul(down, jaw)), mul(side, -(w - 2)))]
    c.polygon(mouth, MOUTH[0])
    c.polygon([add(add(lip, mul(down, 2)), mul(side, -4)), add(add(lip, mul(down, 2)), mul(side, 4)),
               add(lip, mul(down, max(3, jaw - 1)))], MOUTH[1])
    # Lower jaw hanging under the mouth.
    chin = add(lip, mul(down, jaw + 3))
    c.shaded_capsule(add(chin, mul(side, -5)), add(chin, mul(side, 5)), 2.4, FUR, "fur")
    c.capsule(add(lip, mul(side, -w)), add(lip, mul(side, w)), 0.8, GUM)
    # Rows of teeth, then the long fangs.
    for i in range(-3, 4):
        t = add(add(lip, mul(side, i * 2)), mul(down, 1))
        c.polygon([add(t, mul(side, -0.9)), add(t, mul(side, 0.9)), add(t, mul(down, 2.2))],
                  TOOTH[1])
        b = add(add(chin, mul(side, i * 1.8)), mul(up, 2))
        c.polygon([add(b, mul(side, -0.8)), add(b, mul(side, 0.8)), add(b, mul(up, 2))], TOOTH[0])
    for s in (-1, 1):
        root = add(add(lip, mul(side, s * 5.5)), mul(down, 0.5))
        c.polygon([add(root, mul(side, -1.3)), add(root, mul(side, 1.3)),
                   add(add(root, mul(down, 4 + jaw * 0.45)), mul(side, -s * 0.6))], TOOTH[1])
        c.set(*add(root, mul(side, -s * 0.4)), TOOTH[2])
        low = add(add(chin, mul(side, s * 4.5)), mul(up, 1.5))
        c.polygon([add(low, mul(side, -1.1)), add(low, mul(side, 1.1)),
                   add(low, mul(up, 3 + jaw * 0.25))], TOOTH[1])


def draw_smear(c):
    """Three parallel claw streaks across the body for the swipe frame."""
    for k in range(3):
        a = (100 + k * 4, 40 + k * 3)
        b = (52 + k * 4, 96 + k * 3)
        for i in range(41):
            t = i / 40
            r = 0.4 + 0.9 * (1 - abs(t - 0.4) * 1.6)
            c.circle(add(a, mul(sub(b, a), t)), max(0.8, r), SMEAR, "noline")


def fur_texture(c):
    """Dark strands so the fills read as fur instead of rubber."""
    for y in range(c.h):
        for x in range(c.w):
            if c.tag[y][x] != "fur":
                continue
            n = hash01(x, (y + x * 3) // 4, 17)
            if n < 0.07 and c.px[y][x] != MUSCLE:
                c.px[y][x] = STREAK if n < 0.035 else FUR[0]


def draw_pool(c, p):
    mid = mul(add(p["pL"], p["neck"]), 0.5)
    c.polygon([(mid[0] - 34, GROUND - 1), (mid[0] - 14, GROUND - 6), (mid[0] + 22, GROUND - 6),
               (mid[0] + 36, GROUND - 1), (mid[0] + 10, GROUND + 2), (mid[0] - 22, GROUND + 2)],
              BLOOD[0], "noline")


def draw_wounds(c, p):
    chest = mul(add(add(p["sL"], p["sR"]), add(p["pL"], p["pR"])), 0.25)
    for i in range(14):
        dx = (hash01(i, 1, 19) - 0.5) * 18
        dy = (hash01(i, 2, 19) - 0.5) * 18
        c.set(chest[0] + dx, chest[1] + dy, BLOOD[1] if i % 3 else BLOOD[0])


def draw_frame(p):
    c = Canvas(FRAME, FRAME)
    up = norm(sub(p["neck"], mul(add(p["pL"], p["pR"]), 0.5)))
    side = (-up[1], up[0])
    if p["blood"] >= 2:
        draw_pool(c, p)
    left_out = mul(side, -1)
    draw_leg(c, p["pL"], p["kL"], p["aL"], p["fL"], left_out, 31)
    draw_leg(c, p["pR"], p["kR"], p["aR"], p["fR"], side, 37)
    draw_torso(c, p, up, side)
    draw_arm(c, p["sL"], p["eL"], p["hL"], left_out, 41)
    draw_arm(c, p["sR"], p["eR"], p["hR"], side, 47)
    draw_head(c, p, up, side)
    fur_texture(c)
    if p["blood"]:
        draw_wounds(c, p)
    c.outline(OUTLINE)
    if p["smear"]:
        draw_smear(c)
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
    write_png(os.path.join(out_dir, "werewolf_sheet.png"), FRAME * COLS, FRAME * ROWS, sheet)

    if len(sys.argv) > 1:
        scale = 3
        bg = (70, 70, 74, 255)
        big = []
        for row in sheet:
            line_px = []
            for px in row:
                line_px.extend([px or bg] * scale)
            big.extend([line_px] * scale)
        write_png(os.path.join(sys.argv[1], "werewolf_preview.png"),
                  FRAME * COLS * scale, FRAME * ROWS * scale, big)


if __name__ == "__main__":
    main()
