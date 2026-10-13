#!/usr/bin/env python3
"""FX textures for M2.1 wave 2, group B (T-FX2-B): early specials. Project-owned procedural art.

Only the shapes no existing texture has. Deterministic (fixed seeds): an unchanged generator rewrites identical files.
Helpers come from tools/gen_fx_textures.py (grid, smoothstep, rgba, grey, ramp, FIRE), which this file imports; that
file is not changed.

  * flame_wheel_anim (4 frames, 32 px): a ring of flame tongues that turns a sixth of a tongue per frame (Flame Wheel's
    body, and Fire Spin's small swirl). Painted with the shared fire ramp, so it is not tinted.
  * petal (32 px): one rounded petal with a fine vein. Neutral with alpha; tinted per move type at runtime.

Dev dependency: numpy and Pillow (only to regenerate; the PNGs are committed and the game never needs Python).
Usage: python3 tools/gen_fx_textures_b2.py [--out DIR] [--preview DIR]
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


def tex_flame_wheel_anim(n=32, frames=4):
    """A burning wheel: a thick hot rim (the tyre of fire) with eight tongues flaring off it, and a cooler hub. Each
    frame turns the tongues by a sixteenth of a turn, so four frames loop as a wheel that rolls round."""
    x, y = base.grid(n)
    r = np.sqrt(x * x + y * y)
    theta = np.arctan2(y, x)
    rows = []
    for f in range(frames):
        phase = f * (2 * np.pi / 8) / frames
        tongue = np.clip(np.cos(8 * (theta - phase)), 0, 1) ** 2
        rim = 1 - base.smoothstep(0.16, 0.26, np.abs(r - 0.5))
        flare = tongue * (1 - base.smoothstep(0.0, 0.42, r - 0.66))
        hub = 0.35 * (1 - base.smoothstep(0.1, 0.3, r))
        heat = np.clip(0.6 * rim * (0.75 + 0.25 * tongue) + 0.5 * flare + hub, 0, 1)
        heat *= 1 - base.smoothstep(0.92, 1.0, r)
        alpha = base.smoothstep(0.12, 0.3, heat)
        rows.append(base.rgba(base.ramp(heat, base.FIRE), alpha))
    return np.concatenate(rows, axis=0)


def tex_petal(n=32):
    """One rounded petal, broad at the top and pointed at the base, with a fine vein and a lit upper edge."""
    x, y = base.grid(n)
    v = (y + 0.15) / 0.85
    width = 0.5 * np.clip(1 - v * v, 0, 1) ** 0.7
    edge = np.abs(x) - width
    mask = 1 - base.smoothstep(-0.02, 0.05, edge)
    mask *= 1 - base.smoothstep(0.85, 1.0, np.abs(v))
    vein = np.exp(-(x / 0.05) ** 2) * (v > -0.6) * (v < 0.6)
    light = 0.62 + 0.3 * np.clip(-v, -1, 1) * 0.5 + 0.12 * np.clip(-x / 0.5, -1, 1)
    level = np.clip(light - 0.28 * vein, 0, 1)
    return base.grey(level, mask)


TEXTURES = {
    "flame_wheel_anim": tex_flame_wheel_anim,
    "petal": tex_petal,
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
