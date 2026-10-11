#!/usr/bin/env python3
"""Generates our own inventory icons: the Party Ball (T-22) and the four capture balls (T-26).

Pure stdlib (zlib, struct), so it runs anywhere Python 3 does. The art is drawn here, pixel by pixel; it is not
copied from any game. Outputs (relative to the repo root, unless paths are given):
  mods/minemon/minemon_party/textures/minemon_party_ball.png        the Party Ball, a red and white sphere
  mods/minemon/minemon_capture/textures/minemon_capture_<id>.png    poke_ball, great_ball, ultra_ball, master_ball

Usage: python3 tools/gen_icons.py [party_output_dir] [capture_output_dir]
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
BLUE = (48, 96, 210)
YELLOW = (250, 206, 40)
PURPLE = (120, 56, 168)
MARK_RED = (220, 40, 40)
SHADE = 0.82  # the lower red half is a little darker, so the sphere reads as round
TRANSPARENT = (0, 0, 0, 0)

# The M of the Master Ball, 5 pixels wide and 4 tall, drawn in the top half of the sphere.
M_GLYPH = [
    "1...1",
    "11.11",
    "1.1.1",
    "1...1",
]
M_ORIGIN = (5, 3)  # x, y of the glyph's top left pixel


def _shaded(colour, dark):
    """The colour, darkened by SHADE for the lower half when dark is true."""
    if not dark:
        return colour
    r, g, b = colour
    return (int(r * SHADE), int(g * SHADE), int(b * SHADE))


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
        r, g, b = _shaded(WHITE, True)
    return (r, g, b, 255)


def sphere_pixel(x, y, top, bottom, button_ring=BLACK, marks=None, glyph=None):
    """RGBA for pixel (x, y) of a capture ball: a top colour, a bottom colour, a black belt and a centre button.

    marks: set of (x, y) pixels of the bottom half drawn in MARK_RED. glyph: set of (x, y) pixels drawn in WHITE.
    """
    dx = x - CENTRE
    dy = y - CENTRE
    dist = (dx * dx + dy * dy) ** 0.5
    if dist > RADIUS:
        return TRANSPARENT
    if dist > RADIUS - 1.0:
        return BLACK + (255,)
    if abs(dy) < 1.0:
        return BLACK + (255,)
    if dist < 2.3:
        if dist > 1.3:
            return button_ring + (255,)
        return WHITE + (255,)
    if glyph and (x, y) in glyph:
        return WHITE + (255,)
    if dy < 0:
        r, g, b = top
    else:
        if marks and (x, y) in marks:
            return MARK_RED + (255,)
        r, g, b = bottom
    return (r, g, b, 255)


def _glyph_pixels():
    out = set()
    for row, line in enumerate(M_GLYPH):
        for col, ch in enumerate(line):
            if ch == "1":
                out.add((M_ORIGIN[0] + col, M_ORIGIN[1] + row))
    return out


def capture_rows(name):
    """The rows of one capture ball, by ball id."""
    if name == "poke_ball":
        # Red top, white bottom: the Poké Ball.
        def px(x, y):
            return sphere_pixel(x, y, RED, WHITE)
    elif name == "great_ball":
        # Blue top, white bottom, with red marks on the white half.
        marks = {(4, 10), (5, 11), (10, 10), (11, 11)}

        def px(x, y):
            return sphere_pixel(x, y, BLUE, WHITE, marks=marks)
    elif name == "ultra_ball":
        # Black top, yellow bottom.
        def px(x, y):
            return sphere_pixel(x, y, BLACK, YELLOW, button_ring=BLACK)
    elif name == "master_ball":
        # Purple top with a white M, white bottom.
        glyph = _glyph_pixels()

        def px(x, y):
            return sphere_pixel(x, y, PURPLE, WHITE, glyph=glyph)
    else:
        raise ValueError("unknown capture ball: " + name)
    return [[px(x, y) for x in range(SIZE)] for y in range(SIZE)]


CAPTURE_BALLS = ("poke_ball", "great_ball", "ultra_ball", "master_ball")


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


def _write(path, rows):
    with open(path, "wb") as f:
        f.write(png_bytes(SIZE, SIZE, rows))
    print("wrote " + os.path.normpath(path))


def main(argv):
    here = os.path.dirname(os.path.abspath(__file__))
    party_dir = argv[1] if len(argv) > 1 else os.path.join(here, "..", "mods", "minemon", "minemon_party", "textures")
    capture_dir = argv[2] if len(argv) > 2 else os.path.join(here, "..", "mods", "minemon", "minemon_capture",
                                                             "textures")
    os.makedirs(party_dir, exist_ok=True)
    os.makedirs(capture_dir, exist_ok=True)
    rows = [[ball_pixel(x, y) for x in range(SIZE)] for y in range(SIZE)]
    _write(os.path.join(party_dir, "minemon_party_ball.png"), rows)
    for name in CAPTURE_BALLS:
        _write(os.path.join(capture_dir, "minemon_capture_" + name + ".png"), capture_rows(name))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
