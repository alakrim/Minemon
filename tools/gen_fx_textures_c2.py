#!/usr/bin/env python3
"""FX textures for group C2 (status and stat moves, weather; M2.1 T-FX2-C, D-032). Project-owned procedural art, CC0.
Imports its helpers from tools/gen_fx_textures.py. Deterministic: run again, get identical files.

New textures (neutral white or grey with alpha, tinted per move at runtime with "^[multiply:"):
  note    32x32  a music note: an oval head, a stem and a flag (Sing)
  zed     32x32  a capital Z made of three strokes (Rest)
  blossom 32x32  a pointed petal with a centre vein (Sweet Scent; named blossom, B owns "petal")
  web     64x64  a spider web disc: radial spokes and broken rings (Spider Web)
  hex     32x32  a hexagon outline, flat-topped, for a hex shell (Protect)
  eye     32x32  an almond eye with a slit pupil (Leer)
  tuft    32x32  a fluffy cotton puff with a ragged edge (Cotton Spore)
  seed    16x16  an oval seed with a stripe (Leech Seed)

Usage: python3 tools/gen_fx_textures_c2.py [--out DIR] [--preview DIR]
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_fx_textures as base  # noqa: E402  (shared helpers: grid, fbm, smoothstep, white, grey)

ROOT = os.path.dirname(HERE)
DEFAULT_OUT = os.path.join(ROOT, "mods", "minemon", "minemon_fx", "textures")
PREFIX = "minemon_fx_"


def seg_dist(x, y, ax, ay, bx, by):
    """Distance from every pixel (x, y) to the segment a-b."""
    dx, dy = bx - ax, by - ay
    t = np.clip(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy), 0.0, 1.0)
    px, py = ax + t * dx, ay + t * dy
    return np.sqrt((x - px) ** 2 + (y - py) ** 2)


def tex_note(n=32):
    """A music note: a filled oval head, a stem rising from its right side and a flag at the top of the stem."""
    x, y = base.grid(n)
    head_d = np.sqrt(((x + 0.06) / 0.31) ** 2 + ((y - 0.40) / 0.25) ** 2)
    head = 1 - base.smoothstep(0.86, 1.0, head_d)
    stem = (np.abs(x - 0.22) < 0.07) & (y > -0.70) & (y < 0.40)
    # The flag: a stroke that falls from the top of the stem down and to the right.
    flag = 1 - base.smoothstep(0.08, 0.13, seg_dist(x, y, 0.22, -0.70, 0.56, -0.22))
    a = np.clip(np.maximum(head, stem.astype(float) * 0.95) + flag * 0.9, 0, 1)
    return base.white(a)


def tex_zed(n=32):
    """A capital Z: a top bar, a diagonal and a bottom bar, with soft edges (white alpha)."""
    x, y = base.grid(n)
    d = np.minimum.reduce([
        seg_dist(x, y, -0.55, -0.55, 0.55, -0.55),
        seg_dist(x, y, 0.55, -0.55, -0.55, 0.55),
        seg_dist(x, y, -0.55, 0.55, 0.55, 0.55),
    ])
    a = 1 - base.smoothstep(0.11, 0.2, d)
    return base.white(a)


def tex_petal(n=32):
    """A pointed petal, widest a little below its middle, with a faint centre vein (grey: tinted at runtime)."""
    x, y = base.grid(n)
    t = np.clip((y + 0.95) / 1.9, 0.0, 1.0)
    width = 0.46 * np.sin(np.pi * np.clip(t, 0.0, 1.0)) ** 0.8
    inside = np.abs(x) - width
    a = 1 - base.smoothstep(-0.03, 0.03, inside)
    vein = np.exp(-((x / 0.05) ** 2)) * base.smoothstep(-0.7, -0.5, y) * (1 - base.smoothstep(0.4, 0.7, y))
    level = 0.95 - 0.35 * vein + 0.08 * np.clip(-x, -1, 1)
    return base.grey(level, a)


def tex_web(n=64):
    """A spider web: twelve spokes from the centre and four rings that break up towards the rim (white alpha)."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y)
    th = np.arctan2(y, x)
    spokes = np.zeros_like(r)
    for k in range(12):
        ang = k * np.pi / 6.0
        dist = np.abs(-x * np.sin(ang) + y * np.cos(ang))
        along = x * np.cos(ang) + y * np.sin(ang)
        spokes = np.maximum(spokes, (dist < 0.022) & (along > 0.0) & (along < 0.96))
    rings = np.zeros_like(r)
    for i, rad in enumerate((0.24, 0.45, 0.66, 0.86)):
        broken = np.sin(th * (5 + i)) > -0.35 + 0.15 * i
        rings = np.maximum(rings, (np.abs(r - rad) < 0.022) & broken)
    hub = np.exp(-((r / 0.09) ** 2))
    a = np.clip(spokes * 0.9 + rings * 0.85 + hub, 0, 1)
    a = a * (1 - base.smoothstep(0.9, 1.0, r))
    return base.white(a)


def tex_hex(n=32):
    """A flat-topped hexagon outline: a thin ring of six sides (white alpha)."""
    x, y = base.grid(n)
    d = np.zeros_like(x)
    for k in range(3):
        ang = k * np.pi / 3.0
        d = np.maximum(d, np.abs(x * np.cos(ang) + y * np.sin(ang)))
    a = 1 - base.smoothstep(0.03, 0.07, np.abs(d - 0.82))
    return base.white(a)


def tex_eye(n=32):
    """An almond eye: a white almond, a grey iris ring and a dark vertical slit pupil (grey, tinted at runtime)."""
    x, y = base.grid(n)
    almond = np.sqrt((x / 0.95) ** 2 + (y / 0.44) ** 2)
    a = 1 - base.smoothstep(0.9, 1.0, almond)
    iris_d = np.sqrt(x * x + y * y)
    iris = 1 - base.smoothstep(0.26, 0.31, iris_d)
    slit = (np.abs(x) < 0.07) & (np.abs(y) < 0.3)
    level = np.ones_like(x)
    level = np.where(iris > 0.5, 0.55, level)
    level = np.where(slit, 0.05, level)
    return base.grey(level, a)


def tex_tuft(n=32):
    """A cotton puff: a round clump of soft lobes with a ragged edge (grey, nearly white, tinted at runtime)."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y)
    th = np.arctan2(y, x)
    noise = base.fbm((n, n), (3, 3), seed=811, octaves=3)
    lobes = 0.07 * np.sin(th * 6 + 1.3) + 0.04 * np.sin(th * 11 + 0.4)
    edge = 0.72 + lobes + 0.12 * (noise - 0.5)
    a = 1 - base.smoothstep(edge - 0.08, edge, r)
    level = 0.9 + 0.1 * noise - 0.08 * np.clip(y, 0, 1)
    return base.grey(level, a)


def tex_seed(n=16):
    """A seed: an oval with a pale stripe down its length (grey, tinted at runtime)."""
    x, y = base.grid(n)
    oval = np.sqrt((x / 0.45) ** 2 + (y / 0.85) ** 2)
    a = 1 - base.smoothstep(0.85, 1.0, oval)
    stripe = np.exp(-((x / 0.12) ** 2)) * (np.abs(y) < 0.6)
    level = 0.55 + 0.35 * stripe
    return base.grey(level, a)


TEXTURES = {
    "note": tex_note,
    "zed": tex_zed,
    "blossom": tex_petal,
    "web": tex_web,
    "hex": tex_hex,
    "eye": tex_eye,
    "tuft": tex_tuft,
    "seed": tex_seed,
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
