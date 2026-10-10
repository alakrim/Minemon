#!/usr/bin/env python3
"""Generates our own inventory icons (T-22): the Party Ball, a 16x16 red and white sphere.

Pure stdlib (zlib, struct), so it runs anywhere Python 3 does. The art is drawn here, pixel by pixel; it is not
copied from any game. Output: mods/minemon/minemon_party/textures/minemon_party_ball.png (relative to the repo root).

Usage: python3 tools/gen_icons.py [output_dir]
"""

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


def main(argv):
    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = argv[1] if len(argv) > 1 else os.path.join(here, "..", "mods", "minemon", "minemon_party", "textures")
    os.makedirs(out_dir, exist_ok=True)
    rows = [[ball_pixel(x, y) for x in range(SIZE)] for y in range(SIZE)]
    path = os.path.join(out_dir, "minemon_party_ball.png")
    with open(path, "wb") as f:
        f.write(png_bytes(SIZE, SIZE, rows))
    print("wrote " + os.path.normpath(path))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
