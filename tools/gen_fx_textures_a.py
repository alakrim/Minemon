#!/usr/bin/env python3
"""FX textures for the group A types (M2.1 T-FX-a): water, ice, electric, flying, normal, steel. Project-owned
procedural art (CC0), generated from code: no external image, no Pokemon art.

Imports the helpers of tools/gen_fx_textures.py (grid, fbm, smoothstep, rgba, grey, white). Deterministic (fixed
seeds): running it again rewrites identical files.

Neutral textures (white or grey with alpha), tinted per move type at runtime with F.tint:
  droplet, bubble, foam, shard, frost, frost_decal, feather, chip, star, puddle
  bolt_anim: 4 frames of 48 x 48 pixels (vertical strip), a jagged electric bolt that is redrawn every frame.

Usage: python3 tools/gen_fx_textures_a.py [--out DIR] [--preview DIR]
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from gen_fx_textures import DEFAULT_OUT, PREFIX, fbm, grey, grid, preview, smoothstep, white  # noqa: E402

# Frame layout of bolt_anim, read by recipes/type_electric.lua.
BOLT_FRAMES = 4
BOLT_SIZE = 48


def seg_dist(px, py, ax, ay, bx, by):
    """Distance from every pixel centre (px, py) to the segment a-b."""
    vx, vy = bx - ax, by - ay
    t = np.clip(((px - ax) * vx + (py - ay) * vy) / (vx * vx + vy * vy + 1e-9), 0.0, 1.0)
    dx = px - (ax + vx * t)
    dy = py - (ay + vy * t)
    return np.sqrt(dx * dx + dy * dy)


# ---------------------------------------------------------------- water

def tex_droplet(n=16):
    """A water drop: a round bulb with a pointed top, a soft specular highlight (grey, tinted blue)."""
    x, y = grid(n)
    d_bulb = np.sqrt(x * x + (y - 0.22) ** 2) - 0.58
    half = 0.58 * np.clip((y + 0.95) / 1.17, 0, 1) ** 0.9
    d_cone = np.maximum.reduce([np.abs(x) - half, -0.95 - y, y - 0.22])
    sdf = np.minimum(d_bulb, d_cone)
    alpha = 1 - smoothstep(-0.05, 0.08, sdf)
    shade = 0.55 + 0.22 * np.clip(-x / 0.58, -1, 1)
    hl = np.exp(-(((x + 0.22) / 0.16) ** 2 + ((y - 0.02) / 0.2) ** 2))
    level = np.maximum(shade, hl)
    return grey(level, alpha)


def tex_bubble(n=32):
    """A rising bubble: a thin wet outline, a faint wash and a bright highlight on the upper left."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    ang = np.arctan2(y, x)
    ring = np.exp(-((r - 0.72) / 0.085) ** 2)
    wash = 0.12 * (1 - smoothstep(0.5, 0.95, r))
    d = np.angle(np.exp(1j * (ang - np.arctan2(-0.6, -0.6))))
    hl = np.exp(-(d / 0.5) ** 2) * np.exp(-((r - 0.72) / 0.1) ** 2)
    alpha = np.clip(ring * 0.8 + wash + hl, 0, 1) * (1 - smoothstep(0.92, 1.0, r))
    level = np.where(hl > 0.3, 1.0, 0.8)
    return grey(level, alpha)


def tex_foam(n=64):
    """A ragged ring of foam with a few pops: the wave of a splash or a foam shockwave (tinted white-blue)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    noise = fbm((n, n), (4, 4), seed=201, octaves=4)
    pops_n = fbm((n, n), (12, 12), seed=203, octaves=2)
    rr = r + (noise - 0.5) * 0.4
    ring = smoothstep(0.5, 0.7, rr) * (1 - smoothstep(0.78, 0.95, rr))
    pops = smoothstep(0.62, 0.72, pops_n) * (1 - smoothstep(0.5, 0.9, r))
    alpha = np.clip(ring * (0.5 + 0.5 * noise) + pops * 0.9, 0, 1)
    return grey(0.9 + 0.1 * noise, alpha)


def tex_puddle(n=64):
    """A wet puddle decal (alpha blend, tinted): a soft pool with a lighter rim, for water and goo marks."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    noise = fbm((n, n), (3, 3), seed=401, octaves=4)
    rr = r + (noise - 0.5) * 0.55
    body = 1 - smoothstep(0.45, 0.92, rr)
    rim = np.exp(-((rr - 0.82) / 0.07) ** 2)
    alpha = np.clip(body * 0.6 + rim * 0.9, 0, 1)
    level = np.clip(0.7 + 0.5 * rim, 0, 1)
    return grey(level, alpha)


# ---------------------------------------------------------------- ice

def tex_shard(w=16, h=32):
    """An ice shard: a faceted crystal spindle, pointed at both ends, lit on its left facet."""
    c = (np.arange(w) + 0.5) / w * 2 - 1
    v = (np.arange(h) + 0.5) / h
    xx, vv = np.meshgrid(c, v)
    half = 0.46 * np.sin(np.pi * vv) ** 0.8
    alpha = smoothstep(0.0, 0.12, half - np.abs(xx))
    facet = np.where(xx < -0.12, 1.0, np.where(xx < 0.1, 0.8, 0.5))
    level = facet * (0.85 + 0.15 * (1 - vv))
    return grey(level, alpha)


def tex_frost(n=48):
    """A frost crystal: six arms with branches, a bright centre (a snowflake in the air)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    out = np.zeros((n, n))
    for k in range(6):
        a = k * np.pi / 3
        dx, dy = np.cos(a), np.sin(a)
        d_arm = seg_dist(x, y, 0.0, 0.0, 0.9 * dx, 0.9 * dy)
        out = np.maximum(out, np.exp(-(d_arm / 0.06) ** 2))
        for t in (0.45, 0.7):
            px, py = t * dx, t * dy
            for s in (1, -1):
                ba = a + s * np.pi / 3
                d_br = seg_dist(x, y, px, py, px + 0.3 * np.cos(ba), py + 0.3 * np.sin(ba))
                out = np.maximum(out, 0.8 * np.exp(-(d_br / 0.055) ** 2))
    core = np.exp(-(r / 0.12) ** 2)
    alpha = np.clip(out + core, 0, 1) * (1 - smoothstep(0.9, 1.0, r))
    return white(alpha)


def tex_frost_decal(n=64):
    """A frost patch on the ground (alpha blend, tinted cyan): a ragged rime with bright ice veins."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    noise = fbm((n, n), (3, 3), seed=301, octaves=4)
    cracks = fbm((n, n), (7, 7), seed=307, octaves=2)
    rr = r + (noise - 0.5) * 0.5
    patch = 1 - smoothstep(0.35, 0.95, rr)
    vein = np.exp(-((cracks - 0.5) / 0.03) ** 2) * (1 - smoothstep(0.1, 0.6, rr))
    alpha = np.clip(patch * 0.55 + vein * 0.9, 0, 1) ** 0.8
    return grey(np.full((n, n), 0.97), alpha)


# ---------------------------------------------------------------- electric

def _bolt_polyline(rng, steps=7):
    pts = []
    x = rng.uniform(-0.15, 0.15)
    for i in range(steps + 1):
        pts.append((x, -0.95 + 1.9 * i / steps))
        x = float(np.clip(x + rng.uniform(-0.3, 0.3), -0.8, 0.8))
    return pts


def tex_bolt_anim(n=BOLT_SIZE, frames=BOLT_FRAMES):
    """A lightning bolt flipbook: each frame is a new jagged path with a white-hot core and a soft halo."""
    x, y = grid(n)
    rows = []
    for f in range(frames):
        rng = np.random.RandomState(501 + f)
        pts = _bolt_polyline(rng)
        d = np.full((n, n), 9.0)
        for (ax, ay), (bx, by) in zip(pts[:-1], pts[1:]):
            d = np.minimum(d, seg_dist(x, y, ax, ay, bx, by))
        # One fork from a random point on the bolt.
        k = int(rng.randint(2, 5))
        fx, fy = pts[k]
        branch = [(fx, fy), (fx + rng.uniform(0.2, 0.4), fy + 0.25), (fx + rng.uniform(0.3, 0.5), fy + 0.5)]
        for (ax, ay), (bx, by) in zip(branch[:-1], branch[1:]):
            d = np.minimum(d, seg_dist(x, y, ax, ay, bx, by))
        core = np.exp(-(d / 0.045) ** 2)
        halo = 0.4 * np.exp(-(d / 0.14) ** 2)
        edge = 1 - smoothstep(0.85, 1.0, np.maximum(np.abs(x), np.abs(y)))
        alpha = np.clip(core + halo, 0, 1) * edge
        rows.append(grey(np.ones((n, n)), alpha))
    return np.concatenate(rows, axis=0)


# ---------------------------------------------------------------- flying

def tex_feather(w=16, h=32):
    """A bird feather: a curved, asymmetric vane with fine barbs either side of a quill (tinted flying palette)."""
    c = (np.arange(w) + 0.5) / w * 2 - 1
    v = (np.arange(h) + 0.5) / h
    xx, vv = np.meshgrid(c, v)
    swell = np.sin(np.pi * vv) ** 0.6
    spine = 0.12 * np.sin(np.pi * vv)  # the quill bows to the right
    half_l = 0.5 * swell * (1 - 0.3 * vv)
    half_r = 0.34 * swell * (1 - 0.2 * vv)
    rel = xx - spine
    inside = np.where(rel < 0, -rel < half_l, rel < half_r)
    vane = smoothstep(0.0, 0.1, np.where(rel < 0, half_l + rel, half_r - rel)) * inside
    quill = (np.abs(rel) < 0.06).astype(float) * (vv > 0.02) * (vv < 0.98)
    barbs = 0.78 + 0.22 * (0.5 + 0.5 * np.cos(vv * 60 + xx * 4))
    level = np.where(quill > 0, 1.0, barbs)
    alpha = np.clip(np.maximum(vane * 0.9, quill), 0, 1)
    return grey(level, alpha)


# ---------------------------------------------------------------- steel and normal

def tex_chip(n=16):
    """A steel chip: an irregular flake lit from the upper left (tinted steel)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    ang = np.arctan2(y, x)
    edge = 0.62 + 0.14 * np.sin(3 * ang + 0.7) + 0.08 * np.sin(5 * ang + 1.9)
    inside = 1 - smoothstep(edge - 0.06, edge, r)
    light = np.clip(0.5 - 0.5 * (x + y) / 1.2, 0, 1)
    level = 0.45 + 0.55 * light
    return grey(level, inside)


def tex_star(n=32):
    """A clean white impact star: eight crisp rays and a hot centre (normal-type hits)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y) + 1e-6
    ang = np.arctan2(y, x)
    rays = np.abs(np.cos(ang * 4)) ** 12 * np.exp(-r * 2.0)
    core = np.exp(-(r / 0.16) ** 2)
    alpha = np.clip(core + rays, 0, 1) * (1 - smoothstep(0.9, 1.0, r))
    return white(alpha)


TEXTURES = {
    "droplet": tex_droplet,
    "bubble": tex_bubble,
    "foam": tex_foam,
    "puddle": tex_puddle,
    "shard": tex_shard,
    "frost": tex_frost,
    "frost_decal": tex_frost_decal,
    "bolt_anim": tex_bolt_anim,
    "feather": tex_feather,
    "chip": tex_chip,
    "star": tex_star,
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
            preview(img, os.path.join(preview_dir, name))
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
