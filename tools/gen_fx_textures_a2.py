#!/usr/bin/env python3
"""FX textures for group A, wave 2 (M2.1, T-FX2-a): the physical hits. Project-owned procedural art.

Every texture is generated from code: no external image, no Pokemon art. Deterministic (no randomness), so an
unchanged generator rewrites identical files. Helpers come from tools/gen_fx_textures.py (grid, smoothstep, grey,
white, write), which this file imports; that file is not changed.

  * fang (32 px): a curved tooth, tip down, lit on the left edge. Hyper Fang's bite.
  * arc_wide (64 px): a thick, tapered crescent for the broad sweep of a kick (Mega Kick).
  * claw (32 px): a thin straight claw cut, top left to bottom right; ^[transformFX gives the other diagonal.
  * slash_l, slash_r (32 px): thin crescents tilted 35 degrees left and right (the blades of a fan).
Textures can only be turned by 90 degrees (^[transformR90 ...), so every other angle is drawn here.

Both are neutral (grey or white, with alpha) and are tinted per move type at runtime with "^[multiply:".
Dev dependency: numpy and Pillow (only to regenerate; the PNGs are committed and the game never needs Python).
Usage: python3 tools/gen_fx_textures_a2.py [--out DIR] [--preview DIR]
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


def tex_fang(n=32):
    """A tooth: a tapered triangle that curves toward its tip (down). The left flank is lit, the right in shadow."""
    x, y = base.grid(n)
    t = np.clip((y + 0.95) / 1.9, 0.0, 1.0)  # 0 at the root (top), 1 at the tip (bottom)
    half = 0.42 * (1.0 - t) ** 0.6 + 0.02
    cx = 0.16 * t * t
    dx = np.abs(x - cx)
    inside = (1.0 - base.smoothstep(half - 0.04, half, dx)) * (1.0 - base.smoothstep(0.92, 1.0, np.abs(y)))
    light = np.clip(0.5 - (x - cx) / (2.0 * half + 1e-6), 0.0, 1.0)
    level = 0.55 + 0.45 * light + 0.12 * (0.5 - t)
    return base.grey(np.clip(level, 0, 1), np.clip(inside, 0, 1))


def tex_arc_wide(n=64):
    """A thick crescent ')' with tapered ends, brighter along its spine: a broad kick sweep."""
    x, y = base.grid(n)
    cx, cy, radius = -1.12, 0.0, 1.32
    dist = np.hypot(x - cx, y - cy)
    ang = np.arctan2(y - cy, x - cx)
    span = 0.78
    taper = np.clip(1 - (np.abs(ang) / span) ** 2, 0, 1) ** 0.7
    band = (1.0 - base.smoothstep(0.1, 0.22, np.abs(dist - radius))) * taper
    spine = np.exp(-((dist - radius) / 0.06) ** 2) * taper
    alpha = np.clip(band * 0.75 + spine * 0.45, 0, 1)
    return base.white(alpha)


def tex_claw(n=32):
    """A thin straight claw cut, from the top left to the bottom right (\\), tapered at both ends. Mirror it with
    ^[transformFX for the other diagonal (/)."""
    x, y = base.grid(n)
    a = np.array([-0.85, -0.85])
    b = np.array([0.85, 0.85])
    ab = b - a
    px, py = x - a[0], y - a[1]
    t = np.clip((px * ab[0] + py * ab[1]) / (ab @ ab), 0.0, 1.0)
    dist = np.hypot(px - t * ab[0], py - t * ab[1])
    taper = np.clip(np.sin(np.pi * t), 0, 1) ** 0.5
    line = (1.0 - base.smoothstep(0.035, 0.09, dist)) * taper
    core = np.exp(-(dist / 0.025) ** 2) * taper
    return base.white(np.clip(line * 0.8 + core * 0.4, 0, 1))


def _tilted_slash(n, angle):
    """A thin crescent (as tex_slash in gen_fx_textures_b) turned by angle radians."""
    x, y = base.grid(n)
    c, s = np.cos(angle), np.sin(angle)
    xr = x * c + y * s
    yr = -x * s + y * c
    cx, cy, radius = -1.15, 0.0, 1.3
    dist = np.hypot(xr - cx, yr - cy)
    ang = np.arctan2(yr - cy, xr - cx)
    band = np.exp(-((dist - radius) / 0.1) ** 2)
    span = 0.72
    taper = np.clip(1 - (np.abs(ang) / span) ** 2, 0, 1) ** 0.6
    core = np.exp(-((dist - radius) / 0.04) ** 2) * taper
    return base.white(np.clip(band * taper * 0.8 + core * 0.4, 0, 1))


def tex_slash_l(n=32):
    """A thin crescent tilted 35 degrees to the left (one blade of a fan)."""
    return _tilted_slash(n, -np.deg2rad(35))


def tex_slash_r(n=32):
    """A thin crescent tilted 35 degrees to the right (one blade of a fan)."""
    return _tilted_slash(n, np.deg2rad(35))


TEXTURES = {
    "fang": tex_fang,
    "arc_wide": tex_arc_wide,
    "claw": tex_claw,
    "slash_l": tex_slash_l,
    "slash_r": tex_slash_r,
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
