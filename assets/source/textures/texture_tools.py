"""Tileable 64x64 pixel-art building blocks for the map texture generator.

Everything here wraps around the texture edges so brushes tile without
seams. Values are 0..1 "brightness inside a ramp"; `pick` turns them into
ramp colors with a 4x4 ordered dither, which keeps the look crisp under
nearest-neighbor filtering. AI-authored (Claude): see docs/placeholders.md.
"""

import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sprites"))
from pixel_canvas import hash01, write_png  # noqa: E402

S = 64

BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def clamp01(v):
    return 0.0 if v < 0.0 else (1.0 if v > 1.0 else v)


def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def ramp(*hexes):
    return [hexc(h) for h in hexes]


def lum(c):
    return (0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]) / 255.0


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def shade_ramp(base, n=5, lo=0.45, hi=1.45):
    """Dark-to-light ramp around `base` (0-255 RGB) with pixel-art hue shift:
    shadows lean cool, highlights lean warm."""
    out = []
    for i in range(n):
        t = i / (n - 1)
        k = lo + (hi - lo) * t
        r = base[0] * k - 10 * (1 - t) + 8 * t
        g = base[1] * k - 6 * (1 - t) + 5 * t
        b = base[2] * k + 8 * (1 - t) - 6 * t
        out.append(tuple(max(0, min(255, int(round(c)))) for c in (r, g, b)))
    return out


def bayer(x, y):
    return (BAYER[y & 3][x & 3] + 0.5) / 16.0


def pick(rmp, v, x, y, dither=1.0):
    t = clamp01(v) * (len(rmp) - 1) + (bayer(x, y) - 0.5) * dither
    i = int(round(t))
    return rmp[max(0, min(len(rmp) - 1, i))]


class Tex:
    def __init__(self, fill=(0, 0, 0)):
        self.p = [[fill] * S for _ in range(S)]

    def get(self, x, y):
        return self.p[int(y) % S][int(x) % S]

    def set(self, x, y, c):
        self.p[int(y) % S][int(x) % S] = tuple(c[:3])

    def tint(self, x, y, k):
        c = self.get(x, y)
        self.set(x, y, tuple(max(0, min(255, int(ch * k))) for ch in c))

    def blend(self, x, y, c, t):
        self.set(x, y, mix(self.get(x, y), c, t))

    def average(self):
        tot = [0, 0, 0]
        for row in self.p:
            for c in row:
                for i in range(3):
                    tot[i] += c[i]
        return tuple(v / (S * S) for v in tot)

    def save(self, path):
        write_png(path, S, S, [[(c[0], c[1], c[2], 255) for c in row] for row in self.p])


# --- noise -----------------------------------------------------------------

def _smooth(t):
    return t * t * (3 - 2 * t)


def vnoise(x, y, px, py, seed):
    """Value noise with px x py lattice cells across the tile (wraps)."""
    fx = x * px / S
    fy = y * py / S
    ix, iy = int(math.floor(fx)), int(math.floor(fy))
    tx, ty = _smooth(fx - ix), _smooth(fy - iy)
    a = hash01(ix % px, iy % py, seed)
    b = hash01((ix + 1) % px, iy % py, seed)
    c = hash01(ix % px, (iy + 1) % py, seed)
    d = hash01((ix + 1) % px, (iy + 1) % py, seed)
    return (a + (b - a) * tx) * (1 - ty) + (c + (d - c) * tx) * ty


def fbm(x, y, px=4, py=None, octaves=3, seed=0, gain=0.5):
    py = px if py is None else py
    total, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        m = 2 ** o
        total += vnoise(x, y, px * m, py * m, seed + o * 31) * amp
        norm += amp
        amp *= gain
    return total / norm


def voronoi(x, y, cx, cy, seed, jitter=0.85):
    """Returns (f1, f2, cell_id, (dx, dy) to nearest feature point)."""
    cw, ch = S / cx, S / cy
    gx, gy = int(x // cw), int(y // ch)
    f1 = f2 = 1e9
    cid = 0
    vec = (0.0, 0.0)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            nx, ny = gx + ox, gy + oy
            wx, wy = nx % cx, ny % cy
            fpx = (nx + 0.5 + (hash01(wx, wy, seed) - 0.5) * jitter) * cw
            fpy = (ny + 0.5 + (hash01(wx, wy, seed + 1) - 0.5) * jitter) * ch
            d = math.hypot(x - fpx, y - fpy)
            if d < f1:
                f2 = f1
                f1 = d
                cid = wx + wy * 97
                vec = ((x - fpx) / cw, (y - fpy) / ch)
            elif d < f2:
                f2 = d
    return f1, f2, cid, vec


# --- painters ----------------------------------------------------------------

def field(fn, rmp, dither=1.0):
    t = Tex()
    for y in range(S):
        for x in range(S):
            t.p[y][x] = pick(rmp, fn(x + 0.5, y + 0.5, x, y), x, y, dither)
    return t


def edge_light(t, mask, up=1.18, down=0.78):
    """Light comes from the upper left: pixels just below/right of a mask
    pixel are the lit top edge of the next chunk, pixels just above/left
    are in shadow."""
    out = [row[:] for row in t.p]
    for y in range(S):
        for x in range(S):
            if mask[y][x]:
                continue
            if mask[(y - 1) % S][x] or mask[y][(x - 1) % S]:
                c = t.p[y][x]
                out[y][x] = tuple(min(255, int(ch * up)) for ch in c)
            elif mask[(y + 1) % S][x] or mask[y][(x + 1) % S]:
                c = t.p[y][x]
                out[y][x] = tuple(int(ch * down) for ch in c)
    t.p = out


def masonry(rmp, mortar_rmp, rows, cols, seed, offset=0.5, mortar=1, var=0.16,
            rough=0.3, jagged=False, bevel=True):
    """Bricks or blocks. offset=None gives random per-row shifts."""
    t = Tex()
    bh = S / rows
    bw = S / cols
    mask = [[False] * S for _ in range(S)]
    for y in range(S):
        row = int(y // bh)
        if offset is None:
            shift = int(hash01(row, 7, seed) * cols) * bw + int(hash01(row, 9, seed) * 3) * bw / 4
        else:
            shift = offset * bw * (row % 2)
        for x in range(S):
            xx = (x + shift) % S
            col = int(xx // bw)
            lx = xx - col * bw
            ly = y - row * bh
            m = mortar
            if jagged:
                m = mortar + (1 if hash01(x, y, seed + 5) < 0.18 else 0)
            if lx < m or ly < m:
                mask[y][x] = True
                t.p[y][x] = pick(mortar_rmp, fbm(x, y, 8, seed=seed + 2), x, y)
                continue
            base = 0.55 + (hash01(col, row, seed) - 0.5) * 2 * var
            n = fbm(x + 0.5, y + 0.5, 8, octaves=3, seed=seed + 3 + col * 7 + row * 13) - 0.5
            v = base + n * rough * 2
            if bevel:
                if lx >= bw - 1 or ly >= bh - 1:
                    v -= 0.16
            t.p[y][x] = pick(rmp, v, x, y)
    edge_light(t, mask, 1.12, 1.0)
    return t, mask


def planks(rmp, count, seed, vertical=False, gap=1, gap_col=None, joints=1, nails=True,
           knots=2, var=0.14, grain=0.55, nail_col=((40, 38, 40), (120, 118, 116))):
    t = Tex()
    w = S / count
    gap_col = gap_col or tuple(int(c * 0.35) for c in rmp[0])
    mask = [[False] * S for _ in range(S)]
    knot_list = []
    for i in range(count):
        for k in range(knots):
            if hash01(i, k + 40, seed) < 0.6:
                knot_list.append((i, hash01(i, k + 50, seed) * S, gap + 1 + hash01(i, k + 60, seed) * (w - gap - 3)))
    for y in range(S):
        for x in range(S):
            u, v = (y, x) if vertical else (x, y)
            i = int(v // w)
            lv = v - i * w
            jpos = hash01(i, 1, seed) * S
            lu = (u - jpos) % S
            seg_len = S / joints
            seg = int(lu // seg_len)
            su = lu - seg * seg_len
            px, py = (x, y)
            if lv < gap or su < 1:
                mask[py][px] = True
                t.p[py][px] = gap_col
                continue
            base = 0.52 + (hash01(i, seg + 3, seed) - 0.5) * 2 * var
            if vertical:
                g = fbm(x + 0.5, y + 0.5, 32, 2, octaves=2, seed=seed + i * 11 + seg)
            else:
                g = fbm(x + 0.5, y + 0.5, 2, 32, octaves=2, seed=seed + i * 11 + seg)
            val = base + (g - 0.5) * grain
            for (ki, ku, kv) in knot_list:
                if ki != i:
                    continue
                du = ((u - ku + S / 2) % S - S / 2) / 3.2
                dv = (lv - kv) / 1.6
                d = du * du + dv * dv
                if d < 1:
                    val -= 0.3
                elif d < 3.5 and int(d * 2) % 2 == 0:
                    val -= 0.1
            if lv >= w - 1:
                val -= 0.18
            elif lv < gap + 1:
                val += 0.12
            t.p[py][px] = pick(rmp, val, px, py)
    if nails:
        for i in range(count):
            jpos = hash01(i, 1, seed) * S
            for j in range(joints):
                for side in (2.5, S / joints - 2.5):
                    u = jpos + j * S / joints + side
                    for frac in (0.3, 0.7):
                        v = i * w + gap + (w - gap) * frac
                        x, y = (v, u) if vertical else (u, v)
                        t.set(x, y, nail_col[0])
                        t.set(x - 1, y - 1, nail_col[1])
    edge_light(t, mask, 1.0, 0.85)
    return t


def logs(rmp, count, seed, vertical=True, gap_col=(18, 12, 8), lash_rmp=None):
    t = Tex()
    w = S / count
    for y in range(S):
        for x in range(S):
            u, v = (y, x) if vertical else (x, y)
            i = int(v // w)
            lv = (v - i * w + 0.5) / w
            if lv < 0.07 or lv > 0.95:
                t.set(x, y, gap_col)
                continue
            shade = math.cos((lv - 0.38) * math.pi * 0.95)
            if vertical:
                n = fbm(x + 0.5, y + 0.5, 16, 2, octaves=2, seed=seed + i * 5)
            else:
                n = fbm(x + 0.5, y + 0.5, 2, 16, octaves=2, seed=seed + i * 5)
            val = 0.05 + 0.7 * shade + (n - 0.5) * 0.55 + (hash01(i, 0, seed) - 0.5) * 0.15
            if n < 0.28:
                val -= 0.25
            t.set(x, y, pick(rmp, val, x, y))
    if lash_rmp:
        for i in range(count):
            band = hash01(i, 3, seed) * S
            for k in range(4):
                for vv in range(int(i * w) + 1, int((i + 1) * w)):
                    lv = (vv - i * w) / w
                    shade = math.cos((lv - 0.38) * math.pi * 0.95)
                    uu = band + k
                    val = 0.3 + 0.5 * shade + (0.15 if (vv + k) % 3 == 0 else 0) - (0.3 if k == 3 else 0)
                    x, y = (vv, uu) if vertical else (uu, vv)
                    t.set(x, y, pick(lash_rmp, val, int(x), int(y)))
    return t


def rock(rmp, cx, cy, seed, crack=1.1, var=0.18, rough=0.5, facet=0.35, jitter=0.9):
    t = Tex()
    mask = [[False] * S for _ in range(S)]
    for y in range(S):
        for x in range(S):
            f1, f2, cid, vec = voronoi(x + 0.5, y + 0.5, cx, cy, seed, jitter)
            if f2 - f1 < crack:
                mask[y][x] = True
                t.p[y][x] = rmp[0]
                continue
            base = 0.5 + (hash01(cid, 0, seed) - 0.5) * 2 * var
            n = fbm(x + 0.5, y + 0.5, 8, octaves=3, seed=seed + 9) - 0.5
            val = base + n * rough - (vec[0] + vec[1]) * facet
            t.p[y][x] = pick(rmp, val, x, y)
    edge_light(t, mask, 1.15, 0.8)
    return t, mask


def speckle(t, colors, density, seed, size=1):
    for y in range(S):
        for x in range(S):
            h = hash01(x, y, seed)
            if h < density:
                c = colors[int(hash01(x, y, seed + 1) * len(colors)) % len(colors)]
                for dy in range(size):
                    for dx in range(size):
                        t.set(x + dx, y + dy, c)


def disc(t, cx, cy, r, color_fn):
    """Fill a wrapped circle; color_fn(x, y, dx, dy) -> color or None."""
    ri = int(math.ceil(r))
    for dy in range(-ri, ri + 1):
        for dx in range(-ri, ri + 1):
            if dx * dx + dy * dy <= r * r:
                c = color_fn(int(cx + dx), int(cy + dy), dx, dy)
                if c is not None:
                    t.set(cx + dx, cy + dy, c)


def rect(t, x0, y0, w, h, color_fn):
    for y in range(int(y0), int(y0 + h)):
        for x in range(int(x0), int(x0 + w)):
            c = color_fn(x, y, x - x0, y - y0)
            if c is not None:
                t.set(x, y, c)


def grime(t, amount, seed, px=4, dark=0.6, bottom_bias=0.0):
    """Darken by low-frequency noise (dirt, soot, damp)."""
    for y in range(S):
        for x in range(S):
            n = fbm(x + 0.5, y + 0.5, px, octaves=2, seed=seed)
            n += bottom_bias * (y / S - 0.5)
            if n > 1 - amount:
                k = 1 - (n - (1 - amount)) / amount * (1 - dark)
                if bayer(x, y) < 0.85:
                    t.tint(x, y, k)


def moss(t, rmp, amount, seed, px=4):
    for y in range(S):
        for x in range(S):
            n = fbm(x + 0.5, y + 0.5, px, octaves=3, seed=seed)
            if n > 1 - amount and bayer(x, y) < (n - (1 - amount)) / amount * 2:
                t.set(x, y, pick(rmp, hash01(x, y, seed + 4), x, y))


def save_preview(path, named, scale=3, cols=8, tile=2):
    """Contact sheet: each texture tiled tile x tile so seams would show."""
    cell = S * tile * scale + 6
    rows = (len(named) + cols - 1) // cols
    W, H = cols * cell, rows * cell
    img = [[(20, 20, 24, 255)] * W for _ in range(H)]
    for idx, (_, tex) in enumerate(named):
        ox = (idx % cols) * cell + 3
        oy = (idx // cols) * cell + 3
        for y in range(S * tile * scale):
            sy = (y // scale) % S
            row = img[oy + y]
            src = tex.p[sy]
            for x in range(S * tile * scale):
                c = src[(x // scale) % S]
                row[ox + x] = (c[0], c[1], c[2], 255)
    write_png(path, W, H, img)
