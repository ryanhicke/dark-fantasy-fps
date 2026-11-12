"""Tiny dependency-free pixel-art rasterizer and PNG writer.

Used by the enemy sprite generators in this folder. Shapes are filled by
testing pixel centers, so results are crisp (no anti-aliasing), which is
what nearest-neighbor sprites need. AI-authored (Claude): see
docs/placeholders.md.
"""

import math
import struct
import zlib


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def mul(a, s):
    return (a[0] * s, a[1] * s)


def norm(a):
    length = math.hypot(a[0], a[1]) or 1.0
    return (a[0] / length, a[1] / length)


def rotate(point, pivot, degrees):
    rad = math.radians(degrees)
    c, s = math.cos(rad), math.sin(rad)
    dx, dy = point[0] - pivot[0], point[1] - pivot[1]
    return (pivot[0] + dx * c - dy * s, pivot[1] + dx * s + dy * c)


class Canvas:
    def __init__(self, width, height):
        self.w = width
        self.h = height
        self.px = [[None] * width for _ in range(height)]
        # Parallel "material" tag per pixel so later passes (grime, outline)
        # know what they are touching.
        self.tag = [[None] * width for _ in range(height)]

    def set(self, x, y, color, tag=None):
        x, y = int(math.floor(x)), int(math.floor(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = color
            self.tag[y][x] = tag

    def _fill(self, inside, bbox, color, tag):
        x0, y0, x1, y1 = bbox
        for y in range(max(0, int(y0) - 1), min(self.h, int(y1) + 2)):
            for x in range(max(0, int(x0) - 1), min(self.w, int(x1) + 2)):
                if inside(x + 0.5, y + 0.5):
                    self.px[y][x] = color
                    self.tag[y][x] = tag

    def circle(self, c, r, color, tag=None):
        self._fill(lambda x, y: (x - c[0]) ** 2 + (y - c[1]) ** 2 <= r * r,
                   (c[0] - r, c[1] - r, c[0] + r, c[1] + r), color, tag)

    def capsule(self, a, b, r, color, tag=None):
        ab = sub(b, a)
        ab2 = ab[0] ** 2 + ab[1] ** 2 or 1e-9

        def inside(x, y):
            t = max(0.0, min(1.0, ((x - a[0]) * ab[0] + (y - a[1]) * ab[1]) / ab2))
            dx = x - (a[0] + ab[0] * t)
            dy = y - (a[1] + ab[1] * t)
            return dx * dx + dy * dy <= r * r

        self._fill(inside, (min(a[0], b[0]) - r, min(a[1], b[1]) - r,
                            max(a[0], b[0]) + r, max(a[1], b[1]) + r), color, tag)

    def polygon(self, pts, color, tag=None):
        def inside(x, y):
            hit = False
            j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]
                xj, yj = pts[j]
                if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
                    hit = not hit
                j = i
            return hit

        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        self._fill(inside, (min(xs), min(ys), max(xs), max(ys)), color, tag)

    # --- shaded helpers: light comes from the viewer's upper left ---

    def shaded_capsule(self, a, b, r, ramp, tag=None):
        dark, mid, light = ramp
        self.capsule(a, b, r, dark, tag)
        off = (-r * 0.3, -r * 0.3)
        self.capsule(add(a, off), add(b, off), r * 0.72, mid, tag)
        off2 = (-r * 0.5, -r * 0.5)
        if r >= 3:
            self.capsule(add(a, off2), add(b, off2), r * 0.28, light, tag)

    def shaded_circle(self, c, r, ramp, tag=None):
        self.shaded_capsule(c, c, r, ramp, tag)

    def shaded_polygon(self, pts, ramp, tag=None):
        """Fills, then shades each row by horizontal position in its span."""
        dark, mid, light = ramp
        marker = ("__poly__",)
        self.polygon(pts, marker, tag)
        for y in range(self.h):
            row = self.px[y]
            xs = [x for x in range(self.w) if row[x] is marker]
            if not xs:
                continue
            x0, x1 = xs[0], xs[-1]
            span = max(1, x1 - x0)
            for x in xs:
                t = (x - x0) / span
                row[x] = light if t < 0.22 else (dark if t > 0.72 else mid)

    def outline(self, color):
        """1px outline around everything opaque (4-neighbor)."""
        edge = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and self.px[ny][nx] is not None \
                            and self.tag[ny][nx] != "noline":
                        edge.append((x, y))
                        break
        for x, y in edge:
            self.px[y][x] = color
            self.tag[y][x] = "outline"


def hash01(x, y, seed=0):
    """Stable per-pixel noise in [0, 1)."""
    n = (x * 374761393 + y * 668265263 + seed * 2147483647) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return (n ^ (n >> 16)) / 4294967296.0


def write_png(path, width, height, rows):
    """rows: list of rows of (r, g, b, a) or None (transparent)."""
    raw = bytearray()
    for row in rows:
        raw.append(0)
        for p in row:
            raw.extend(p if p is not None else (0, 0, 0, 0))

    def chunk(kind, data):
        c = struct.pack(">I", len(data)) + kind + data
        return c + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)
