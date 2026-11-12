"""Generates the bandit archer sprite sheet (front-facing only).

Bearded man in a red cowl (hood and dagged shoulder cape), black jerkin,
red hose and black boots, armed with a longbow, quiver on his back.

Run from the project root:
    python assets/source/sprites/bandit_archer.py [preview_dir]

Writes assets/sprites/enemies/bandit_archer_sheet.png: 128x128 frames (one
frame = 1.8 m, matching the archer's sprite quad) in a 4x4 grid (512x512),
laid out as described by enemies/bandit_archer/bandit_archer_sprites.tres:
    0 idle | 1-4 walk | 5 draw (windup) | 6 release | 7 pain | 8-11 death
AI-authored (Claude): see docs/placeholders.md.
"""

import os
import sys

from pixel_canvas import Canvas, add, hash01, mul, norm, rotate, sub, write_png

FRAME = 128
COLS = 4
ROWS = 4
GROUND = 125

OUTLINE = (14, 9, 9, 255)
SKIN = ((124, 82, 62, 255), (172, 122, 92, 255), (206, 158, 122, 255))
BEARD = ((52, 32, 20, 255), (82, 52, 30, 255), (110, 72, 42, 255))
COWL = ((104, 14, 22, 255), (156, 28, 38, 255), (198, 62, 64, 255))
HOOD_SHADOW = (40, 10, 12, 255)
JERKIN = ((22, 20, 24, 255), (42, 40, 48, 255), (68, 66, 76, 255))
HOSE = ((98, 22, 20, 255), (142, 36, 30, 255), (180, 62, 48, 255))
BOOT = ((18, 16, 16, 255), (38, 34, 34, 255), (62, 58, 56, 255))
LEATHER = ((56, 36, 22, 255), (94, 62, 36, 255), (128, 88, 52, 255))
WOOD = ((70, 44, 24, 255), (112, 74, 40, 255), (150, 106, 62, 255))
STRING = (206, 196, 164, 255)
STEEL = ((66, 68, 76, 255), (122, 126, 134, 255), (190, 194, 200, 255))
FLETCH = ((150, 146, 136, 255), (214, 210, 198, 255))
BRASS = (166, 138, 78, 255)
EYE = (24, 16, 12, 255)
MOUTH = (40, 18, 14, 255)
BLOOD = ((92, 10, 10, 255), (138, 22, 16, 255))

BOW_HALF = 46  # half the bow's length in pixels: a ~1.3 m bow


# --- poses ---------------------------------------------------------------
# Joint names: "L" is the viewer's left (the archer's right, the draw hand),
# "R" is the viewer's right (the archer's left, the bow hand).

BASE = {
    "head": (64, 19), "neck": (64, 28),
    "sL": (49, 33), "sR": (79, 33),
    "eL": (45, 50), "eR": (84, 50),
    "hL": (44, 66), "hR": (86, 65),
    "pL": (57, 70), "pR": (71, 70),
    "kL": (55, 96), "kR": (73, 96),
    "fL": (54, 120), "fR": (74, 120),
}
UPPER = ("head", "neck", "sL", "sR", "eL", "eR", "hL", "hR", "pL", "pR")


def pose(**overrides):
    p = dict(BASE)
    # bow: (grip-to-top-tip direction, bulge), or None once dropped.
    p.update({"bow": ((0.12, -1.0), 4.0), "bow_front": False, "draw": None,
              "arrow": False, "blood": 0})
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
    p = pose()
    p = shifted(p, 0, bob, UPPER)
    if phase == 1:
        p.update(kL=(56, 90), fL=(57, 112), hL=(47, 63), eL=(45, 48),
                 hR=(85, 68), bow=((0.2, -1.0), 4.0))
    elif phase == 3:
        p.update(kR=(72, 90), fR=(71, 112), hL=(42, 68), hR=(87, 62),
                 bow=((0.05, -1.0), 4.0))
    return p


def limp():
    """Arms hanging, legs together: the base for falling frames."""
    return pose(eL=(48, 50), hL=(49, 66), eR=(80, 50), hR=(79, 66),
                kL=(57, 96), kR=(71, 96), fL=(57, 120), fR=(71, 120), bow=None)


def fit(p, degrees):
    """Rotates the whole body about its feet, then puts it on the ground."""
    pivot = (64, 120)
    joints = list(BASE)
    q = dict(p)
    for k in joints:
        q[k] = rotate(p[k], pivot, degrees)
    xs = [q[k][0] for k in joints]
    ys = [q[k][1] for k in joints]
    dx = 64 - (min(xs) + max(xs)) / 2 + 2
    dy = (GROUND - 6) - max(ys)
    return shifted(q, dx, dy, joints)


POSES = [
    # 0 idle: bow held low at his side.
    pose(),
    # 1-4 walk
    walk(0), walk(1), walk(2), walk(3),
    # 5 draw: bow raised in front, canted; string pulled to the cheek and
    # the arrow pointing straight at the viewer.
    pose(eR=(86, 42), hR=(77, 47), eL=(38, 31), hL=(55, 27),
         bow=((0.3, -0.95), 3.0), bow_front=True, draw="hL", arrow=True),
    # 6 release: string snapped straight, draw hand flung back past the ear.
    pose(eR=(86, 42), hR=(77, 47), eL=(36, 27), hL=(40, 14),
         bow=((0.3, -0.95), 4.0), bow_front=True),
    # 7 pain: head snapped aside, arms thrown out, bow swinging wide.
    pose(head=(59, 21), neck=(62, 29), sL=(48, 34), sR=(78, 32), eL=(36, 46), hL=(30, 56),
         eR=(92, 42), hR=(100, 50), bow=((0.75, -0.66), 4.0), blood=1),
    # 8 death: reeling, knees buckling, the bow slipping.
    shifted(pose(head=(57, 25), neck=(61, 32), eL=(38, 48), hL=(32, 60), eR=(92, 46),
                 hR=(98, 58), kL=(52, 98), kR=(76, 98), bow=((0.9, -0.42), 4.0), blood=1),
            0, 4, UPPER),
    # 9 death: on his knees, slumping, bow dropped.
    dict(shifted(pose(head=(66, 31), neck=(65, 38), sL=(50, 42), sR=(79, 42), eL=(48, 60),
                      hL=(50, 76), eR=(81, 60), hR=(79, 76), pL=(57, 80), pR=(71, 80),
                      kL=(53, 108), kR=(75, 108), fL=(51, 120), fR=(77, 120), bow=None,
                      blood=1), 0, 4, UPPER + ("kL", "kR")), dropped=True),
    # 10 death: toppling over.
    dict(fit(limp(), -55), blood=1, dropped=True),
    # 11 corpse: flat on the ground in a pool of blood.
    dict(fit(limp(), -90), blood=2, dropped=True),
]


# --- drawing -------------------------------------------------------------

def line(c, a, b, color, tag=None):
    """1px line for bowstrings: no thickness, so it stays a hair."""
    steps = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
    for i in range(steps + 1):
        t = i / steps
        c.set(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, color, tag)


def bow_points(grip, axis, bulge):
    """Tip-to-tip points of a longbow. The limbs curve back toward the
    string side, so the grip sits at the belly's deepest point."""
    a = norm(axis)
    back = (a[1], -a[0])  # perpendicular, pointing to the string side
    pts = []
    for i in range(25):
        t = -1 + i / 12
        pts.append(add(add(grip, mul(a, t * BOW_HALF)), mul(back, bulge * t * t)))
    return pts, back


def draw_bow(c, grip, axis, bulge, draw_hand=None):
    pts, back = bow_points(grip, axis, bulge)
    top, bottom = pts[-1], pts[0]
    for i in range(len(pts) - 1):
        t = abs(-1 + (i + 0.5) / 12)
        c.capsule(pts[i], pts[i + 1], 2.0 - 1.0 * t, WOOD[1])
    for i in range(len(pts) - 1):
        c.capsule(add(pts[i], mul(back, 0.7)), add(pts[i + 1], mul(back, 0.7)), 0.5, WOOD[0])
    for i in range(13, len(pts) - 2):
        c.set(*add(pts[i], mul(back, -0.8)), WOOD[2])
    a = norm(axis)
    c.capsule(add(grip, mul(a, -4)), add(grip, mul(a, 4)), 2.4, LEATHER[1])  # grip wrap
    c.circle(top, 1.2, WOOD[0])
    c.circle(bottom, 1.2, WOOD[0])
    if draw_hand is None:
        line(c, top, bottom, STRING, "noline")
    else:
        line(c, top, draw_hand, STRING, "noline")
        line(c, bottom, draw_hand, STRING, "noline")


def draw_dropped_bow(c, y):
    pts = []
    for i in range(25):
        t = -1 + i / 12
        pts.append((22 + t * BOW_HALF * 0.55 + 10, y - 4 * (1 - t * t)))
    for i in range(len(pts) - 1):
        c.capsule(pts[i], pts[i + 1], 1.6, WOOD[1])
    line(c, pts[0], pts[-1], STRING, "noline")


def draw_arrow_at_viewer(c, nock, grip):
    """Arrow drawn to the cheek: mostly foreshortened, the head toward us."""
    head = add(grip, mul(norm(sub(grip, nock)), 2))
    c.capsule(nock, head, 0.8, WOOD[2])
    c.polygon([add(head, (-2.5, 1.5)), add(head, (2.5, 1.5)), add(head, (0, -3))], STEEL[1])
    c.set(*add(head, (-0.5, -1)), STEEL[2])


def draw_quiver(c, p, up, side):
    """On his back over the viewer-left shoulder; only the top shows."""
    base = add(add(p["sL"], mul(side, 3)), mul(up, -10))
    top = add(add(p["sL"], mul(side, -2)), mul(up, 14))
    c.shaded_capsule(base, top, 4.2, LEATHER)
    for i, off in enumerate((-2.5, 0.0, 2.5)):
        shaft_top = add(add(top, mul(side, off)), mul(up, 6 + (i % 2) * 2))
        c.capsule(top, shaft_top, 0.6, WOOD[1])
        c.polygon([add(shaft_top, mul(side, -1.6)), add(shaft_top, mul(side, 1.6)),
                   add(shaft_top, mul(up, 5))], FLETCH[i % 2])
    c.capsule(add(top, mul(side, -4)), add(top, mul(side, 4)), 1.0, BRASS)


def draw_arm(c, shoulder, elbow, hand, bracer):
    c.shaded_capsule(shoulder, elbow, 4.0, JERKIN, "jerkin")
    c.shaded_capsule(elbow, hand, 3.4, JERKIN, "jerkin")
    if bracer:
        c.shaded_capsule(add(elbow, mul(sub(hand, elbow), 0.35)),
                         add(elbow, mul(sub(hand, elbow), 0.8)), 3.7, LEATHER)
    c.shaded_circle(hand, 3.2, SKIN, "skin")


def draw_leg(c, hip, knee, foot):
    c.shaded_capsule(hip, knee, 5.2, HOSE, "cloth")
    c.shaded_capsule(knee, foot, 4.3, HOSE, "cloth")
    boot_top = add(knee, mul(sub(foot, knee), 0.35))
    c.shaded_capsule(boot_top, foot, 5.0, BOOT)
    c.capsule(add(boot_top, (-5.5, 0)), add(boot_top, (5.5, 0)), 1.8, BOOT[2])  # turned cuff
    c.shaded_capsule(add(foot, (-2, 2)), add(foot, (3, 2)), 3.2, BOOT)


def draw_torso(c, p, up, side):
    sL, sR, pL, pR = p["sL"], p["sR"], p["pL"], p["pR"]
    down = mul(up, -1)
    hem = 12
    jerkin = [add(sL, mul(up, 2)), add(sR, mul(up, 2)),
              add(add(pR, mul(side, 4)), mul(down, hem)),
              add(add(pL, mul(side, -4)), mul(down, hem))]
    c.shaded_polygon(jerkin, JERKIN, "jerkin")
    # Laced front: a pale cross-lacing down the middle.
    neck_base = add(p["neck"], mul(down, 14))
    hip_mid = mul(add(pL, pR), 0.5)
    for i in range(6):
        pt = add(neck_base, mul(sub(hip_mid, neck_base), i / 7))
        c.set(*add(pt, mul(side, -1)), LEATHER[2])
        c.set(*add(pt, mul(side, 1)), LEATHER[2])
    # Belt, buckle, and a knife on the hip.
    c.capsule(add(pL, mul(side, -4)), add(pR, mul(side, 4)), 2.3, LEATHER[0])
    c.capsule(add(pL, mul(side, -4)), add(pR, mul(side, 4)), 0.6, LEATHER[2])
    c.shaded_circle(hip_mid, 2.2, (BRASS, BRASS, (220, 196, 130, 255)))
    knife = add(pR, mul(side, 1))
    c.capsule(knife, add(knife, mul(down, 12)), 1.6, LEATHER[1])
    c.set(*add(knife, mul(up, 1)), STEEL[2])


def draw_cape(c, p, up, side):
    """Dagged capelet of the cowl over the shoulders and upper chest."""
    down = mul(up, -1)
    neck = p["neck"]
    left = add(p["sL"], mul(side, -5))
    right = add(p["sR"], mul(side, 5))
    pts = [add(neck, mul(up, 4)), add(add(right, mul(up, 3)), mul(side, -2)), right]
    teeth = 7
    for i in range(teeth + 1):
        t = i / teeth
        edge = add(add(right, mul(sub(left, right), t)), mul(down, 9))
        depth = 4 if i % 2 == 0 else 0
        # The cape hangs lowest in the middle of the chest.
        sag = 5 * (1 - abs(t - 0.5) * 2)
        pts.append(add(edge, mul(down, depth + sag)))
    pts.extend([left, add(add(left, mul(up, 3)), mul(side, 2))])
    c.shaded_polygon(pts, COWL, "cloth")


def draw_head(c, p, up, side):
    head = p["head"]
    down = mul(up, -1)
    # Hood: a rounded cowl peaking a little above the head.
    hood = []
    for i in range(15):
        v = rotate(up, (0, 0), -110 + i * (220 / 14))
        hood.append(add(add(head, mul(up, 0.5)), mul(v, 11.0)))
    hood.append(add(add(head, mul(down, 7)), mul(side, 10)))
    hood.append(add(add(head, mul(down, 7)), mul(side, -10)))
    c.shaded_polygon(hood, COWL, "cloth")
    c.set(*add(head, mul(up, 10)), COWL[2])
    # Face opening, in the hood's shadow at the top.
    face = add(head, mul(down, 1.5))
    c.circle(face, 7.2, HOOD_SHADOW)
    c.shaded_circle(add(face, mul(down, 0.6)), 6.4, SKIN, "skin")
    for i in range(-5, 6):
        c.set(*add(add(face, mul(up, 4)), mul(side, i)), SKIN[0], "skin")  # brow shadow
    # Full beard over the jaw and chin, with a moustache.
    beard = [add(add(face, mul(side, -6.5)), mul(down, 0)),
             add(add(face, mul(side, -6)), mul(down, 5)),
             add(add(face, mul(side, -3)), mul(down, 9.5)),
             add(face, mul(down, 11.5)),
             add(add(face, mul(side, 3)), mul(down, 9.5)),
             add(add(face, mul(side, 6)), mul(down, 5)),
             add(add(face, mul(side, 6.5)), mul(down, 0)),
             add(add(face, mul(side, 3)), mul(down, 3)),
             add(add(face, mul(side, -3)), mul(down, 3))]
    c.shaded_polygon(beard, BEARD, "beard")
    c.capsule(add(add(face, mul(side, -3.5)), mul(down, 3.2)),
              add(add(face, mul(side, 3.5)), mul(down, 3.2)), 1.2, BEARD[1], "beard")
    for i in (-1, 0, 1):
        c.set(*add(add(face, mul(down, 5)), mul(side, i)), MOUTH)
    for s in (-2.5, 2.5):
        c.set(*add(add(face, mul(up, 2)), mul(side, s)), EYE)
    c.set(*add(face, mul(up, 0)), SKIN[0], "skin")  # nose shadow


def texture(c):
    """Speckles the beard and scuffs the jerkin so flat fills don't look
    plastic. Not the reds: dark flecks there read as holes or blood."""
    for y in range(c.h):
        for x in range(c.w):
            tag = c.tag[y][x]
            n = hash01(x, y, 5)
            if tag == "beard" and n < 0.22:
                c.px[y][x] = BEARD[0] if n < 0.12 else BEARD[2]
            elif tag == "jerkin" and hash01(x // 2, y // 2, 9) < 0.06:
                c.px[y][x] = JERKIN[2]


def draw_pool(c, p):
    """Blood pool under a corpse; drawn first so the body covers it."""
    mid = mul(add(p["pL"], p["neck"]), 0.5)
    c.polygon([(mid[0] - 26, GROUND - 1), (mid[0] - 10, GROUND - 5), (mid[0] + 18, GROUND - 5),
               (mid[0] + 30, GROUND - 1), (mid[0] + 8, GROUND + 2), (mid[0] - 18, GROUND + 2)],
              BLOOD[0], "noline")


def draw_splashes(c, p):
    chest = mul(add(add(p["sL"], p["sR"]), add(p["pL"], p["pR"])), 0.25)
    for i in range(10):
        dx = (hash01(i, 1, 13) - 0.5) * 12
        dy = (hash01(i, 2, 13) - 0.5) * 14
        c.set(chest[0] + dx, chest[1] + dy, BLOOD[1] if i % 3 else BLOOD[0])


def draw_frame(p):
    c = Canvas(FRAME, FRAME)
    up = norm(sub(p["neck"], mul(add(p["pL"], p["pR"]), 0.5)))
    side = (-up[1], up[0])
    if p["blood"] >= 2:
        draw_pool(c, p)
    if p.get("dropped"):
        draw_dropped_bow(c, GROUND - 1)
    draw_quiver(c, p, up, side)
    if p["bow"] is not None and not p["bow_front"]:
        draw_bow(c, p["hR"], *p["bow"])
    draw_leg(c, p["pL"], p["kL"], p["fL"])
    draw_leg(c, p["pR"], p["kR"], p["fR"])
    draw_torso(c, p, up, side)
    draw_cape(c, p, up, side)
    draw_arm(c, p["sR"], p["eR"], p["hR"], bracer=True)
    draw_head(c, p, up, side)
    if p["bow"] is not None and p["bow_front"]:
        draw_hand = p[p["draw"]] if p["draw"] else None
        draw_bow(c, p["hR"], *p["bow"], draw_hand=draw_hand)
        c.shaded_circle(p["hR"], 3.2, SKIN, "skin")  # fist over the grip
        if p["arrow"]:
            draw_arrow_at_viewer(c, p["hL"], p["hR"])
    draw_arm(c, p["sL"], p["eL"], p["hL"], bracer=False)
    texture(c)
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
    write_png(os.path.join(out_dir, "bandit_archer_sheet.png"), FRAME * COLS, FRAME * ROWS, sheet)

    if len(sys.argv) > 1:
        # 3x preview on a gray background for eyeballing.
        scale = 3
        bg = (70, 70, 74, 255)
        big = []
        for row in sheet:
            line_px = []
            for px in row:
                line_px.extend([px or bg] * scale)
            big.extend([line_px] * scale)
        write_png(os.path.join(sys.argv[1], "bandit_archer_preview.png"),
                  FRAME * COLS * scale, FRAME * ROWS * scale, big)


if __name__ == "__main__":
    main()
