#!/usr/bin/env python3
"""FX textures for group B (M2.1, T-FX-b): grass, bug, poison, ground, rock, fighting. Project-owned procedural art.

Every texture is generated from code: no external image, no Pokemon art. Deterministic (fixed seeds), so an unchanged
generator rewrites identical files. Helpers come from tools/gen_fx_textures.py (grid, fbm, smoothstep, rgba, white,
grey), which this file imports; that file is not changed.

All textures are neutral (white or grey, with alpha) and are tinted per move type at runtime with "^[multiply:".
  * leaf_spin_anim (8 frames): a leaf that flips as it spins (squashed across its width).
  * bone_spin_anim (4 frames): a bone spinning in the picture plane (a boomerang).
  * shard_spin_anim (4 frames): a sharp chitin shard, spinning.
  * chunk_spin_anim (4 frames): a rough rock chunk, spinning.
  * goo: a glossy blob (poison globs and bubbles); drop: a dripping teardrop, pointed up.
  * toxic_puddle, crater: ground decals (toxic puddle, impact crater); alpha blend, faded by the runtime.
  * speedline: a tapered horizontal speed streak; impact_star: a four-ray impact star; slash: a crescent melee arc.

Dev dependency: numpy and Pillow (only to regenerate; the PNGs are committed and the game never needs Python).
Usage: python3 tools/gen_fx_textures_b.py [--out DIR] [--preview DIR]
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import gen_fx_textures as base  # noqa: E402  (shared helpers; same directory)

PREFIX = base.PREFIX
DEFAULT_OUT = base.DEFAULT_OUT


def _rotate(x, y, angle):
    c, s = np.cos(angle), np.sin(angle)
    return x * c - y * s, x * s + y * c


def _convex_sdf(x, y, pts):
    """Signed distance to a convex polygon, positive inside (the polygon's winding is made counter-clockwise)."""
    area = 0.0
    for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
        area += x0 * y1 - x1 * y0
    if area < 0:
        pts = list(reversed(pts))
    d = None
    for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
        ex, ey = x1 - x0, y1 - y0
        length = np.hypot(ex, ey)
        s = (ex * (y - y0) - ey * (x - x0)) / length
        d = s if d is None else np.minimum(d, s)
    return d


# ---------------------------------------------------------------- flipbooks

def tex_leaf_spin_anim(n=16, frames=8):
    """A pointed leaf with a vein that spins: across its width it foreshortens as it turns (flips front to back)."""
    x, y = base.grid(n)
    rows = []
    for f in range(frames):
        squash = max(abs(np.cos(np.pi * f / frames)), 0.2)
        u, v = _rotate(x, y, -np.pi / 4)
        v = v / squash
        width = 0.46 * np.clip(1 - u * u, 0, 1) ** 0.75
        inside = 1 - base.smoothstep(width - 0.06, width, np.abs(v))
        tips = 1 - base.smoothstep(0.9, 1.0, np.abs(u))
        mask = inside * tips
        vein = np.exp(-(v / 0.06) ** 2) * (np.abs(u) < 0.72)
        light = 0.5 + 0.5 * np.clip(v / np.maximum(width, 0.05), -1, 1)
        level = 0.55 + 0.45 * light - 0.4 * vein
        rows.append(base.grey(level, mask))
    return np.concatenate(rows, axis=0)


def tex_bone_spin_anim(n=16, frames=4):
    """A bone (two knobs and a shaft) spinning in the picture plane, one quarter turn per frame."""
    x, y = base.grid(n)
    rows = []
    for f in range(frames):
        u, v = _rotate(x, y, f * np.pi / frames)
        shaft = (1 - base.smoothstep(0.12, 0.17, np.abs(v))) * (1 - base.smoothstep(0.5, 0.56, np.abs(u)))
        k1 = 1 - base.smoothstep(0.2, 0.27, np.hypot(u - 0.56, v))
        k2 = 1 - base.smoothstep(0.2, 0.27, np.hypot(u + 0.56, v))
        mask = np.clip(np.maximum(np.maximum(shaft, k1), k2), 0, 1)
        level = 0.95 - 0.3 * (1 - base.smoothstep(0.0, 0.12, np.abs(v)))
        rows.append(base.grey(level, mask))
    return np.concatenate(rows, axis=0)


def tex_shard_spin_anim(n=16, frames=4):
    """A sharp chitin shard: a kite with a bright ridge, spinning in the picture plane."""
    x, y = base.grid(n)
    pts = [(0.92, 0.0), (-0.05, 0.46), (-0.88, 0.1), (-0.3, -0.34)]
    rows = []
    for f in range(frames):
        u, v = _rotate(x, y, f * np.pi / frames)
        d = _convex_sdf(u, v, pts)
        mask = base.smoothstep(-0.02, 0.05, d)
        ridge = np.exp(-(v / 0.08) ** 2) * (u > -0.5)
        level = 0.6 + 0.4 * np.clip(v * 2 + 0.5, 0, 1) + 0.35 * ridge
        rows.append(base.grey(np.clip(level, 0, 1), mask))
    return np.concatenate(rows, axis=0)


def tex_chunk_spin_anim(n=16, frames=4):
    """A rough rock chunk: a noisy polygon with a lit top and a dark rim, spinning."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y) + 1e-6
    ang = np.arctan2(y, x)
    rows = []
    for f in range(frames):
        a = ang - f * 0.5
        edge = 0.66 + 0.1 * np.sin(3 * a + 1.1) + 0.07 * np.sin(5 * a + 0.3) + 0.04 * np.sin(8 * a + 2.0)
        mask = 1 - base.smoothstep(edge - 0.05, edge, r)
        rim = base.smoothstep(edge * 0.7, edge, r)
        facets = 0.5 + 0.5 * np.sin(4 * a + 0.8)
        level = 0.85 - 0.35 * rim + 0.12 * (0.5 - y) + 0.1 * facets
        rows.append(base.grey(np.clip(level, 0, 1), mask))
    return np.concatenate(rows, axis=0)


# ---------------------------------------------------------------- single textures

def tex_goo(n=16):
    """A glossy blob of goo: a wobbly disc, a bright highlight at the top left, a darker rim."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y) + 1e-6
    ang = np.arctan2(y, x)
    edge = 0.8 + 0.06 * np.sin(5 * ang + 1.3)
    mask = 1 - base.smoothstep(edge - 0.08, edge, r)
    rim = base.smoothstep(edge * 0.55, edge, r)
    hi = np.exp(-(((x + 0.3) ** 2 + (y + 0.34) ** 2) / 0.05))
    level = 0.6 + 0.4 * (1 - rim) + 0.6 * hi
    return base.grey(np.clip(level, 0, 1), mask)


def tex_drop(w=8, h=16):
    """A dripping teardrop, pointed at the top (vertical particles fall with the point up)."""
    xx, yy = np.meshgrid(np.linspace(-1, 1, w), np.linspace(-1, 1, h))
    s = (yy + 1) / 2
    half = 0.9 * np.clip(s, 0.02, 1) ** 0.6
    mask = (1 - base.smoothstep(half * 0.8, half + 1e-3, np.abs(xx))) * (1 - base.smoothstep(0.9, 1.0, s))
    hi = np.exp(-((xx + 0.25) ** 2) / 0.05) * (s < 0.7)
    level = 0.75 + 0.25 * hi - 0.15 * np.abs(xx)
    return base.grey(np.clip(level, 0, 1), mask)


def tex_puddle(n=32):
    """A toxic puddle decal: a ragged pool, lighter bubbles inside and a bright wet rim."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y)
    noise = base.fbm((n, n), (3, 3), seed=201, octaves=3)
    edge = 0.8 + (noise - 0.5) * 0.5
    body = 1 - base.smoothstep(edge - 0.05, edge, r)
    rim = np.exp(-((r - edge * 0.92) / 0.07) ** 2)
    bubbles = base.smoothstep(0.62, 0.8, base.fbm((n, n), (6, 6), seed=207, octaves=2))
    level = 0.5 + 0.25 * noise + 0.3 * bubbles + 0.5 * rim
    alpha = np.clip(body * 0.8 + rim * 0.35, 0, 1)
    return base.grey(np.clip(level, 0, 1), alpha)


def tex_crater(n=32):
    """An impact crater decal: a dark floor, radial cracks and an upturned lit rim. Alpha blend."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y) + 1e-6
    ang = np.arctan2(y, x)
    noise = base.fbm((n, n), (3, 3), seed=301, octaves=3)
    edge = 0.86 + (noise - 0.5) * 0.35
    inside = 1 - base.smoothstep(edge - 0.06, edge, r)
    cracks = np.abs(np.cos(ang * 5 + noise * 2.5)) ** 30 * (1 - base.smoothstep(0.25, 0.9, r))
    rim = np.exp(-((r - 0.66) / 0.1) ** 2)
    level = 0.25 + 0.15 * noise - 0.2 * cracks + 0.6 * rim
    alpha = np.clip(inside * 0.9, 0, 1)
    return base.grey(np.clip(level, 0, 1), alpha)


def tex_speedline(w=32, h=8):
    """A tapered speed streak, horizontal: a bright core that thins to points at both ends."""
    xs = (np.arange(w) + 0.5) / w * 2 - 1
    ys = (np.arange(h) + 0.5) / h * 2 - 1
    xx, yy = np.meshgrid(xs, ys)
    length = 1 - base.smoothstep(0.55, 1.0, np.abs(xx))
    thick = np.exp(-(yy / (0.08 + 0.3 * (1 - np.abs(xx)) ** 1.5)) ** 2)
    core = np.exp(-(yy / 0.07) ** 2) * length
    return base.white(np.clip(length * thick * 0.9 + core * 0.35, 0, 1))


def tex_star(n=32):
    """An impact star: a white hot core, four long rays, four short diagonal rays and a soft halo."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y) + 1e-6
    ang = np.arctan2(y, x)
    rays = np.abs(np.cos(2 * ang)) ** 24 * np.exp(-r * 2.6)
    diag = np.abs(np.cos(2 * (ang - np.pi / 4))) ** 60 * np.exp(-r * 3.4) * 0.6
    core = np.exp(-(r / 0.16) ** 2)
    halo = 0.25 * np.exp(-(r / 0.45) ** 2)
    a = np.clip(core + rays + diag + halo, 0, 1) * (1 - base.smoothstep(0.9, 1.0, r))
    return base.white(a)


def tex_slash(n=32):
    """A crescent melee arc (a bright ')' with tapered ends). Mirror it with ^[transformFX for the other stroke."""
    x, y = base.grid(n)
    cx, cy, radius = -1.15, 0.0, 1.3
    dist = np.hypot(x - cx, y - cy)
    ang = np.arctan2(y - cy, x - cx)
    band = np.exp(-((dist - radius) / 0.1) ** 2)
    span = 0.72
    taper = np.clip(1 - (np.abs(ang) / span) ** 2, 0, 1) ** 0.6
    core = np.exp(-((dist - radius) / 0.04) ** 2) * taper
    return base.white(np.clip(band * taper * 0.8 + core * 0.4, 0, 1))


TEXTURES = {
    "leaf_spin_anim": tex_leaf_spin_anim,
    "bone_spin_anim": tex_bone_spin_anim,
    "shard_spin_anim": tex_shard_spin_anim,
    "chunk_spin_anim": tex_chunk_spin_anim,
    "goo": tex_goo,
    "drop": tex_drop,
    "toxic_puddle": tex_puddle,
    "crater": tex_crater,
    "speedline": tex_speedline,
    "impact_star": tex_star,
    "slash": tex_slash,
}


def write_all(out_dir, preview_dir=None):
    os.makedirs(out_dir, exist_ok=True)
    if preview_dir:
        os.makedirs(preview_dir, exist_ok=True)
    names = []
    for key, fn in TEXTURES.items():
        img = fn()
        name = PREFIX + key + ".png"
        Image.fromarray(img, "RGBA").save(os.path.join(out_dir, name), optimize=True)
        if preview_dir:
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
