"""Robed-caster body shared by the apprentice wizard and the necromancer:
a floor-length robe that swings with the feet, wide bell sleeves, a belt,
shoes peeking under the hem, and the fireball they both cast.

AI-authored (Claude): see docs/placeholders.md.
"""

from sheet_tools import add, mul, norm, sub, flames, orb

FIRE = ((150, 30, 8, 255), (230, 92, 20, 255), (255, 172, 44, 255), (255, 242, 176, 255))
FLAME_TIPS = ((230, 92, 20, 255), (255, 172, 44, 255))


def draw_shoes(c, p, ramp):
    """Drawn before the robe, so only the toes show under the hem."""
    for foot in (p["fL"], p["fR"]):
        c.shaded_capsule(add(foot, (-2, 3)), add(foot, (2, 3)), 3.2, ramp)


def draw_robe(c, p, up, side, ramp, flare=9):
    sL, sR, fL, fR = p["sL"], p["sR"], p["fL"], p["fR"]
    down = mul(up, -1)
    hem_mid = add(mul(add(fL, fR), 0.5), mul(up, 1))
    body = [add(add(sL, mul(up, 2)), mul(side, -1)), add(add(sR, mul(up, 2)), mul(side, 1)),
            add(add(sR, mul(down, 16)), mul(side, 2)),
            add(add(fR, mul(side, flare)), mul(down, 2)),
            add(hem_mid, mul(down, 2)),
            add(add(fL, mul(side, -flare)), mul(down, 2)),
            add(add(sL, mul(down, 16)), mul(side, -2))]
    c.shaded_polygon(body, ramp, "robe")
    # Folds falling from the hips to the hem.
    hips = mul(add(p["pL"], p["pR"]), 0.5)
    for k, foot in ((-1, fL), (1, fR)):
        top = add(hips, mul(side, k * 4))
        c.capsule(top, add(add(foot, mul(side, k * 3)), mul(down, 1)), 0.5, ramp[0], "robe")
    c.capsule(add(hips, mul(down, 4)), add(hem_mid, mul(up, 2)), 0.5, ramp[0], "robe")


def draw_belt(c, p, side, ramp, buckle):
    pL, pR = p["pL"], p["pR"]
    c.capsule(add(pL, mul(side, -4)), add(pR, mul(side, 4)), 2.2, ramp[1])
    c.capsule(add(pL, mul(side, -4)), add(pR, mul(side, 4)), 0.6, ramp[2])
    c.shaded_circle(mul(add(pL, pR), 0.5), 2.2, buckle)


def draw_sleeve(c, shoulder, elbow, hand, ramp, skin):
    """Bell sleeve: narrow at the shoulder, flaring wide at the wrist."""
    c.shaded_capsule(shoulder, elbow, 4.4, ramp, "robe")
    d = norm(sub(hand, elbow))
    perp = (-d[1], d[0])
    cuff = add(elbow, mul(sub(hand, elbow), 0.85))
    c.shaded_polygon([add(elbow, mul(perp, 4.2)), add(cuff, mul(perp, 6.4)),
                      add(cuff, mul(perp, -6.4)), add(elbow, mul(perp, -4.2))], ramp, "robe")
    c.capsule(add(cuff, mul(perp, 6)), add(cuff, mul(perp, -6)), 0.6, ramp[0], "robe")
    c.shaded_circle(add(cuff, mul(d, 3.2)), 3.0, skin, "skin")


def draw_fireball(c, centre, radius, seed=1):
    flames(c, centre, radius, FLAME_TIPS, seed)
    orb(c, centre, radius, FIRE)
