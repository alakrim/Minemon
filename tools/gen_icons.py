#!/usr/bin/env python3
"""Generates our own inventory icons (T-22): the Party Ball, a 16x16 red and white sphere.

Pure stdlib (zlib, struct), so it runs anywhere Python 3 does. The art is drawn here, pixel by pixel; it is not
copied from any game. Output: mods/minemon/minemon_party/textures/minemon_party_ball.png (relative to the repo root).

Usage: python3 tools/gen_icons.py [output_dir]
"""

import math
import os
import struct
import sys
import zlib

SIZE = 16
RADIUS = 7.0
CENTRE = (SIZE - 1) / 2.0
RED = (212, 42, 42)
WHITE = (242, 242, 242)
BLACK = (24, 24, 24)
SHADE = 0.82  # the lower red half is a little darker, so the sphere reads as round
TRANSPARENT = (0, 0, 0, 0)


def ball_pixel(x, y):
    """RGBA for pixel (x, y) of the Party Ball."""
    dx = x - CENTRE
    dy = y - CENTRE
    dist = (dx * dx + dy * dy) ** 0.5
    if dist > RADIUS:
        return TRANSPARENT
    if dist > RADIUS - 1.0:
        return BLACK + (255,)
    # The belt across the middle: a black band, two pixels tall.
    if abs(dy) < 1.0:
        return BLACK + (255,)
    # The centre button: white with a black ring.
    if dist < 2.3:
        if dist > 1.3:
            return BLACK + (255,)
        return WHITE + (255,)
    if dy < 0:
        r, g, b = RED
    else:
        r, g, b = WHITE
        r, g, b = int(r * SHADE), int(g * SHADE), int(b * SHADE)
    return (r, g, b, 255)


def png_bytes(width, height, rows):
    """Encodes RGBA rows (lists of 4-tuples) as a PNG file."""

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    raw = bytearray()
    for row in rows:
        raw.append(0)  # filter type: none
        for px in row:
            raw.extend(px)
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b""))


# Evolution items (T-27, D-030): our own 16x16 stones (gems), held items and the Link Cable (coins and a cable).
# Drawn here, pixel by pixel, from simple shapes; not copied from any game. Kept apart from the ball icon above.
EVO_OUTLINE = (24, 24, 24)
EVO_GEMS = {
    "fire_stone": (220, 60, 40),
    "water_stone": (60, 130, 235),
    "thunder_stone": (250, 215, 60),
    "leaf_stone": (80, 200, 90),
    "moon_stone": (190, 180, 235),
    "sun_stone": (255, 160, 40),
}
EVO_COINS = {
    "dragon_scale": (50, 160, 150),
    "king_s_rock": (214, 170, 60),
    "metal_coat": (176, 184, 196),
    "up_grade": (110, 130, 170),
}
CABLE_WIRE = (70, 70, 80)
CABLE_HIGHLIGHT = (125, 125, 136)
CABLE_PLUG = (200, 200, 210)


def _shade(base, factor):
    return tuple(int(c * factor) for c in base)


def gem_pixel(x, y, base):
    """A diamond with a lit top half and a darker bottom half."""
    dx = x - CENTRE
    dy = y - CENTRE
    d = abs(dx) + abs(dy)
    if d > 6.0:
        return TRANSPARENT
    if d >= 6.0:
        return EVO_OUTLINE + (255,)
    if dy < -2.5:
        r, g, b = tuple(min(255, c + 60) for c in base)
    elif dy > 2.5:
        r, g, b = _shade(base, 0.7)
    else:
        r, g, b = base
    return (r, g, b, 255)


def coin_pixel(x, y, base):
    """A round coin: a rim, a raised centre ring and a shaded lower-right side."""
    dx = x - CENTRE
    dy = y - CENTRE
    dist = (dx * dx + dy * dy) ** 0.5
    if dist > 6.5:
        return TRANSPARENT
    if dist > 5.8:
        return EVO_OUTLINE + (255,)
    if dist > 4.9:
        r, g, b = _shade(base, 0.7)
    elif 1.4 < dist < 2.6:
        r, g, b = tuple(min(255, c + 50) for c in base)
    elif dx + dy > 2.5:
        r, g, b = _shade(base, 0.85)
    else:
        r, g, b = base
    return (r, g, b, 255)


def cable_pixel(x, y, plug_top, plug_bottom):
    """A Link Cable: a wire curving from the top-left plug to the bottom-right plug."""
    if plug_top(x, y):
        return (CABLE_PLUG if not plug_top.edge(x, y) else EVO_OUTLINE) + (255,)
    if plug_bottom(x, y):
        return (CABLE_PLUG if not plug_bottom.edge(x, y) else EVO_OUTLINE) + (255,)
    # The wire: y follows x from (3, 3) to (12, 12), bowed by a sine so it reads as a cable, about 2 px thick.
    t = x - 3.0
    wire_y = 3.0 + t + 2.5 * math.sin(math.pi * t / 9.0) if 0.0 <= t <= 9.0 else None
    if wire_y is not None and abs(y - wire_y) <= 1.0:
        return CABLE_HIGHLIGHT + (255,) if y < wire_y else CABLE_WIRE + (255,)
    return TRANSPARENT


class _Rect:
    """A plug: a filled rectangle with a one-pixel outline, drawn over the wire."""

    def __init__(self, x0, y0, x1, y1):
        self.x0, self.y0, self.x1, self.y1 = x0, y0, x1, y1

    def __call__(self, x, y):
        return self.x0 <= x <= self.x1 and self.y0 <= y <= self.y1

    def edge(self, x, y):
        return x in (self.x0, self.x1) or y in (self.y0, self.y1)


def write_evolution_icons(out_dir):
    """Writes minemon_evo_<item>.png for the six stones, four held items and the Link Cable. Returns the paths."""
    os.makedirs(out_dir, exist_ok=True)
    plug_top = _Rect(1, 1, 5, 4)
    plug_bottom = _Rect(10, 10, 14, 14)
    jobs = []
    for item, base in EVO_GEMS.items():
        jobs.append((item, [[gem_pixel(x, y, base) for x in range(SIZE)] for y in range(SIZE)]))
    for item, base in EVO_COINS.items():
        jobs.append((item, [[coin_pixel(x, y, base) for x in range(SIZE)] for y in range(SIZE)]))
    cable = [[cable_pixel(x, y, plug_top, plug_bottom) for x in range(SIZE)] for y in range(SIZE)]
    jobs.append(("link_cable", cable))
    paths = []
    for item, rows in jobs:
        path = os.path.join(out_dir, "minemon_evo_%s.png" % item)
        with open(path, "wb") as f:
            f.write(png_bytes(SIZE, SIZE, rows))
        paths.append(os.path.normpath(path))
    return paths


def main(argv):
    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = argv[1] if len(argv) > 1 else os.path.join(here, "..", "mods", "minemon", "minemon_party", "textures")
    os.makedirs(out_dir, exist_ok=True)
    rows = [[ball_pixel(x, y) for x in range(SIZE)] for y in range(SIZE)]
    path = os.path.join(out_dir, "minemon_party_ball.png")
    with open(path, "wb") as f:
        f.write(png_bytes(SIZE, SIZE, rows))
    print("wrote " + os.path.normpath(path))
    evo_dir = os.path.join(here, "..", "mods", "minemon", "minemon_growth", "textures")
    for evo_path in write_evolution_icons(evo_dir):
        print("wrote " + evo_path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
