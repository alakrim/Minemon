#!/usr/bin/env python3
"""FX textures for group C (psychic, ghost, dark, dragon, fire default; M2.1 T-FX-c, D-032). Project-owned procedural
art, CC0. Imports its helpers from tools/gen_fx_textures.py. Deterministic: run again, get identical files.

New textures (neutral white or grey with alpha, tinted per type at runtime with "^[multiply:"):
  wisp    32x32  a drifting ghost wisp: bright head, a tail that curls and thins (ghost)
  rune    32x32  a psychic sigil: a thin ring with a cross and three dots inside (psychic floating motes)
  tendril 24x64  a shadow strand that curls and tapers, vertical (dark: shadow tendrils)

Usage: python3 tools/gen_fx_textures_c.py [--out DIR] [--preview DIR]
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_fx_textures as base  # noqa: E402  (shared helpers: grid, fbm, smoothstep, white, rgba)

ROOT = os.path.dirname(HERE)
DEFAULT_OUT = os.path.join(ROOT, "mods", "minemon", "minemon_fx", "textures")
PREFIX = "minemon_fx_"


def tex_wisp(n=32):
    """A ghost wisp: a soft round head that trails a thin, curling tail downwards (white alpha)."""
    x, y = base.grid(n)
    noise = base.fbm((n, n), (3, 3), seed=401, octaves=3)
    head = np.exp(-(((x) / 0.30) ** 2 + ((y + 0.25) / 0.30) ** 2))
    # The tail's centreline sways and its width shrinks towards the tip (y grows downwards).
    v = np.clip((y + 0.25) / 1.15, 0.0, 1.0)
    centre = 0.20 * np.sin(v * 5.0) * v
    width = 0.20 * (1.0 - v) ** 0.8 + 0.03
    tail = np.exp(-(((x - centre) / width) ** 2)) * base.smoothstep(-0.25, 0.05, y) * (1 - base.smoothstep(0.7, 1.0, v))
    a = np.clip(head * 0.95 + tail * 0.7, 0, 1)
    a = a * (0.7 + 0.5 * noise)
    r = np.sqrt(x * x + y * y)
    a = a * (1 - base.smoothstep(0.85, 1.0, r))
    return base.white(np.clip(a, 0, 1))


def tex_rune(n=32):
    """A psychic sigil: a thin ring, a cross through its centre and three dots (white alpha, tinted pink)."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y)
    ring = np.exp(-(((r - 0.62) / 0.07) ** 2))
    cross = (np.exp(-((x / 0.06) ** 2)) + np.exp(-((y / 0.06) ** 2))) * (r < 0.5)
    dots = np.zeros_like(r)
    for dx, dy in ((0.0, -0.3), (-0.26, 0.2), (0.26, 0.2)):
        dots += np.exp(-(((x - dx) ** 2 + (y - dy) ** 2) / 0.012))
    a = np.clip(ring * 0.9 + cross * 0.75 + dots, 0, 1)
    a = a * (1 - base.smoothstep(0.9, 1.0, r))
    return base.white(a)


def tex_tendril(w=24, h=64):
    """A shadow strand: it sways along its length and tapers to a point. Vertical (use vertical=true particles).

    Grey, with ragged edges from noise; the runtime tints it dark and blends it "alpha" or "sub".
    """
    v = (np.arange(h) + 0.5) / h  # 0 at the tip (top), 1 at the root (bottom)
    u = (np.arange(w) + 0.5) / w * 2 - 1
    uu, vv = np.meshgrid(u, v)
    noise = base.fbm((h, w), (3, 6), seed=431, octaves=3)
    centre = 0.35 * np.sin((1 - vv) * 6.0) * (1 - vv) * 0.9
    width = 0.10 + 0.42 * vv ** 1.4
    body = np.exp(-(((uu - centre) / width) ** 2))
    ragged = body * base.smoothstep(0.25, 0.7, noise + 0.25 * (1 - vv))
    alpha = np.clip(ragged * 0.95 + body * 0.25, 0, 1) * base.smoothstep(0.0, 0.12, v)[:, None]
    level = 0.35 + 0.25 * noise
    return base.grey(level, alpha)


TEXTURES = {
    "wisp": tex_wisp,
    "rune": tex_rune,
    "tendril": tex_tendril,
}


def write_all(out_dir, preview_dir=None):
    os.makedirs(out_dir, exist_ok=True)
    names = []
    for key, fn in TEXTURES.items():
        img = fn()
        name = PREFIX + key + ".png"
        Image.fromarray(img, "RGBA").save(os.path.join(out_dir, name), optimize=True)
        if preview_dir:
            os.makedirs(preview_dir, exist_ok=True)
            base.preview(img, os.path.join(preview_dir, name))
        names.append(name)
    return names


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--preview", default=None)
    args = ap.parse_args(argv)
    names = write_all(args.out, args.preview)
    print("wrote %d textures to %s" % (len(names), args.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
