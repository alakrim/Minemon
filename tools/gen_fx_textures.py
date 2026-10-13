#!/usr/bin/env python3
"""FX textures for minemon_fx (M2.1 art pass, D-032). Project-owned procedural art, CC0.

Every texture is generated from code: no external image, no Pokémon art. Run it again after a change; the output is
deterministic (fixed seeds), so an unchanged generator rewrites identical files.

Two families:
  * Neutral (white or grey, with alpha): tinted per move type at runtime with "^[multiply:#rrggbb".
      glow, flare, spark, ring, smoke_anim (8 frames), dust, streak, mote, ring_ground
  * Painted (colour baked in, never tinted): the fire set, whose gradient white > yellow > orange > red cannot
    come from tinting one white texture.
      flame_anim (8 frames), fireball_anim (4 frames), blast_anim (8 frames), ember, scorch

Flipbooks are vertical strips (frame 0 on top), for the particle "vertical_frames" animation and for
ObjectRef:set_sprite (spritediv x=1, y=frames).

Dev dependency: numpy and Pillow (only to regenerate; the PNGs are committed and the game never needs Python).
Usage: python3 tools/gen_fx_textures.py [--out DIR] [--preview DIR]
  --preview writes 4x nearest-neighbour previews on a dark checker background, for review.
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DEFAULT_OUT = os.path.join(ROOT, "mods", "minemon", "minemon_fx", "textures")
PREFIX = "minemon_fx_"


# ---------------------------------------------------------------- maths helpers

def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def grid(n):
    """Pixel-centre coordinates in -1..1 (y grows downwards, as in the image)."""
    c = (np.arange(n) + 0.5) / n * 2.0 - 1.0
    return np.meshgrid(c, c)


def value_noise(shape, cells, seed, period_y=None):
    """Smooth value noise in 0..1 on a lattice of cells (cx, cy). period_y wraps the lattice vertically."""
    h, w = shape
    cx, cy = cells
    rng = np.random.RandomState(seed)
    lat = rng.rand(cy + 1, cx + 1)
    if period_y:
        lat[cy, :] = lat[0, :]
    ys = np.linspace(0, cy, h, endpoint=False)
    xs = np.linspace(0, cx, w, endpoint=False)
    y0 = np.floor(ys).astype(int)
    x0 = np.floor(xs).astype(int)
    fy = ys - y0
    fx = xs - x0
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = lat[y0][:, x0]
    b = lat[y0][:, x0 + 1]
    c = lat[y0 + 1][:, x0]
    d = lat[y0 + 1][:, x0 + 1]
    top = a + (b - a) * fx[None, :]
    bot = c + (d - c) * fx[None, :]
    return top + (bot - top) * fy[:, None]


def fbm(shape, base_cells, seed, octaves=4, period_y=False):
    total = np.zeros(shape)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        cells = (base_cells[0] * 2 ** o, base_cells[1] * 2 ** o)
        total += amp * value_noise(shape, cells, seed + 101 * o, period_y)
        norm += amp
        amp *= 0.5
    return total / norm


def ramp(t, stops):
    """Colour ramp: stops = [(pos, (r, g, b)), ...] with pos ascending in 0..1. Returns HxWx3 in 0..1."""
    t = np.clip(t, 0.0, 1.0)
    out = np.zeros(t.shape + (3,))
    for (p0, c0), (p1, c1) in zip(stops[:-1], stops[1:]):
        m = (t >= p0) & (t <= p1)
        k = ((t - p0) / max(p1 - p0, 1e-6))[..., None]
        out[m] = (np.array(c0) + (np.array(c1) - np.array(c0)) * k)[m]
    return out


def rgba(rgb, alpha):
    a = np.clip(alpha, 0.0, 1.0)
    img = np.concatenate([np.clip(rgb, 0, 1), a[..., None]], axis=-1)
    return (img * 255.0 + 0.5).astype(np.uint8)


def white(alpha):
    return rgba(np.ones(alpha.shape + (3,)), alpha)


def grey(level, alpha):
    return rgba(np.repeat(np.clip(level, 0, 1)[..., None], 3, axis=-1), alpha)


# Fire colours, hot to cold. Shared by every painted fire texture so the set reads as one material.
FIRE = [
    (0.00, (0.35, 0.03, 0.01)),
    (0.30, (0.85, 0.18, 0.02)),
    (0.55, (1.00, 0.52, 0.08)),
    (0.78, (1.00, 0.86, 0.35)),
    (1.00, (1.00, 1.00, 0.92)),
]


# ---------------------------------------------------------------- neutral textures

def tex_glow(n=64):
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    a = np.exp(-(r / 0.42) ** 2) * (1 - smoothstep(0.85, 1.0, r))
    return white(a)


def tex_flare(n=32):
    """A hot point with six thin rays: the 'catch light' of impacts and casts."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y) + 1e-6
    ang = np.arctan2(y, x)
    rays = np.abs(np.cos(ang * 3.0)) ** 40 * np.exp(-r * 2.2)
    core = np.exp(-(r / 0.16) ** 2)
    halo = 0.35 * np.exp(-(r / 0.5) ** 2)
    a = np.clip(core + rays + halo, 0, 1) * (1 - smoothstep(0.9, 1.0, r))
    return white(a)


def tex_spark(n=8):
    """A crisp, pixel-sized hot dot with a one pixel halo (reads at any distance)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    a = np.where(r < 0.35, 1.0, np.exp(-((r - 0.35) / 0.25) ** 2) * 0.6)
    return white(a * (1 - smoothstep(0.9, 1.0, r)))


def tex_mote(n=16):
    """A soft four-point twinkle, for magical and status motes."""
    x, y = grid(n)
    ax, ay = np.abs(x), np.abs(y)
    star = np.clip(1 - (np.sqrt(ax) + np.sqrt(ay)) / 1.1, 0, 1) ** 1.5
    core = np.exp(-((x * x + y * y) / 0.05))
    return white(np.clip(star * 1.4 + core, 0, 1))


def tex_streak(w=8, h=32):
    """A vertical speed streak (use with vertical=true particles for rain, dashes and falling sparks)."""
    c = (np.arange(w) + 0.5) / w * 2 - 1
    v = (np.arange(h) + 0.5) / h
    xx, vv = np.meshgrid(c, v)
    a = np.exp(-(xx / 0.35) ** 2) * smoothstep(0.0, 0.25, vv) * (1 - smoothstep(0.7, 1.0, vv))
    return white(a)


def tex_ring(n=64):
    """A thin shockwave ring with a soft inner wash."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    edge = np.exp(-((r - 0.82) / 0.07) ** 2)
    wash = 0.18 * smoothstep(0.2, 0.8, r) * (1 - smoothstep(0.8, 0.9, r))
    return white(np.clip(edge + wash, 0, 1))


def tex_dust(n=48):
    """A grainy dirt puff (alpha blend), for footfalls, landings and ground hits."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    noise = fbm((n, n), (3, 3), seed=7, octaves=3)
    a = (1 - smoothstep(0.35, 0.95, r)) * smoothstep(0.35, 0.6, noise)
    level = 0.75 + 0.25 * noise
    return grey(level, a * 0.9)


def tex_smoke_anim(n=64, frames=8):
    """Billowing smoke puff that grows and thins over 8 frames (alpha blend, grey; tint it dark or coloured)."""
    rows = []
    for f in range(frames):
        t = f / (frames - 1)
        x, y = grid(n)
        r = np.sqrt(x * x + y * y)
        noise = fbm((n, n), (3, 3), seed=31 + f * 3, octaves=4)
        radius = 0.55 + 0.35 * t
        body = 1 - smoothstep(radius * 0.55, radius, r + (noise - 0.5) * 0.45)
        density = body * (0.95 - 0.75 * t) * (0.6 + 0.6 * noise)
        level = 0.55 + 0.45 * (1 - y) / 2 * (0.7 + 0.6 * noise)  # lit from above
        rows.append(grey(level, np.clip(density, 0, 1)))
    return np.concatenate(rows, axis=0)


# ---------------------------------------------------------------- painted fire textures

def tex_flame_anim(n=32, frames=8):
    """A licking flame tongue, 8 looping frames: the noise scrolls up by one full vertical period.

    Domain warp: the x coordinate is pushed sideways by noise that grows with height, so the tip splits into
    tongues that sway; the base is a rounded hot bulb.
    """
    x, y = grid(n)
    up = (1 - y) / 2  # 0 at the bottom, 1 at the top
    rows = []
    big = fbm((n * 2, n), (3, 4), seed=11, octaves=4, period_y=True)
    fine = fbm((n * 2, n), (6, 8), seed=17, octaves=3, period_y=True)
    for f in range(frames):
        shift = int(round(f * n / frames))
        noise = np.roll(big, -shift, axis=0)[:n, :]
        detail = np.roll(fine, -2 * shift, axis=0)[:n, :]
        wx = x + (noise - 0.5) * 0.9 * up ** 1.3 + (detail - 0.5) * 0.25 * up
        # Teardrop: half width shrinks with height; the bulb sits at up ~ 0.22.
        half = 0.48 * np.clip(1 - up, 0, 1) ** 0.85 + 0.02
        bulb = 1 - smoothstep(0.0, 0.28, np.sqrt((x / 0.5) ** 2 + ((up - 0.2) / 0.22) ** 2) - 0.75)
        body = 1 - smoothstep(half * 0.45, half, np.abs(wx))
        body = np.maximum(body * smoothstep(0.08, 0.3, up), bulb * (up < 0.3))
        body *= 1 - smoothstep(0.55, 0.95, up + (detail - 0.5) * 0.5)
        heat = body * (0.35 + 0.6 * noise) * (1.05 - 0.8 * up) + 0.25 * bulb * np.exp(-(x / 0.22) ** 2)
        alpha = smoothstep(0.1, 0.3, heat)
        rows.append(rgba(ramp(heat, FIRE), alpha))
    return np.concatenate(rows, axis=0)


def tex_fireball_anim(n=32, frames=4):
    """A round fireball: white-hot core, churning orange corona, soft outer glow. Looping 4 frames."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    ang = np.arctan2(y, x)
    rows = []
    for f in range(frames):
        phase = f / frames * 2 * np.pi
        churn = fbm((n, n), (4, 4), seed=53 + f, octaves=3)
        lobes = 0.04 * np.sin(ang * 7 + phase) + 0.03 * np.sin(ang * 4 - phase * 2)
        edge = 0.68 + lobes + (churn - 0.5) * 0.18
        body = 1 - smoothstep(edge * 0.6, edge, r)
        heat = body * (0.4 + 0.45 * churn) + np.exp(-(r / 0.22) ** 2) * 0.55
        halo = 0.45 * np.exp(-(r / 0.62) ** 2) * (1 - smoothstep(0.85, 1.0, r))
        alpha = np.clip(smoothstep(0.08, 0.3, heat) + halo, 0, 1)
        colour = ramp(np.maximum(heat, halo * 0.6), FIRE)
        rows.append(rgba(colour, alpha))
    return np.concatenate(rows, axis=0)


def tex_blast_anim(n=64, frames=8):
    """A fire burst: a white flash that blooms into a ragged orange ball and collapses into embers and soot."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    rows = []
    for f in range(frames):
        t = f / (frames - 1)
        noise = fbm((n, n), (4, 4), seed=71 + f * 5, octaves=4)
        radius = 0.25 + 0.7 * (1 - (1 - t) ** 2)
        shell = 1 - smoothstep(radius * 0.4, radius, r + (noise - 0.5) * 0.5 * (0.4 + t))
        hollow = smoothstep(radius * (0.1 + 0.6 * t), radius * (0.5 + 0.5 * t), r + (noise - 0.5) * 0.3)
        body = shell * (hollow if t > 0.35 else 1.0)
        heat = body * (1.25 - 1.05 * t) * (0.6 + 0.6 * noise)
        colour = ramp(heat, FIRE)
        # Late frames cool towards soot: blend the colour to dark grey where the heat is low.
        soot = np.clip((t - 0.4) / 0.6, 0, 1) * (1 - np.clip(heat * 1.6, 0, 1))
        colour = colour * (1 - soot[..., None]) + 0.12 * soot[..., None]
        alpha = smoothstep(0.08, 0.3, body * (0.6 + 0.6 * noise)) * (1 - 0.65 * t)
        rows.append(rgba(colour, alpha))
    return np.concatenate(rows, axis=0)


def tex_ember(n=8):
    """A tiny hot ember: yellow-white core with an orange rim, pixel crisp."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    heat = np.clip(1.15 - r * 1.1, 0, 1)
    alpha = np.where(r < 0.55, 1.0, np.exp(-((r - 0.55) / 0.22) ** 2) * 0.7)
    return rgba(ramp(heat * 0.8 + 0.2, FIRE), alpha * (1 - smoothstep(0.9, 1.0, r)))


def tex_scorch(n=32):
    """A burn mark for the ground (alpha blend): soot with glowing cracks that the runtime fades out."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    noise = fbm((n, n), (3, 3), seed=91, octaves=4)
    cracks = fbm((n, n), (6, 6), seed=97, octaves=2)
    ragged = r + (noise - 0.5) * 0.45
    soot = 1 - smoothstep(0.3, 0.95, ragged)
    vein = np.exp(-((cracks - 0.5) / 0.035) ** 2) * (1 - smoothstep(0.2, 0.6, ragged))
    colour = np.zeros((n, n, 3)) + 0.06
    colour += vein[..., None] * np.array([0.95, 0.38, 0.05])
    alpha = np.clip(soot * 1.1 + vein, 0, 1) ** 0.7
    return rgba(colour, alpha)


TEXTURES = {
    "glow": tex_glow,
    "flare": tex_flare,
    "spark": tex_spark,
    "mote": tex_mote,
    "streak": tex_streak,
    "ring": tex_ring,
    "dust": tex_dust,
    "smoke_anim": tex_smoke_anim,
    "flame_anim": tex_flame_anim,
    "fireball_anim": tex_fireball_anim,
    "blast_anim": tex_blast_anim,
    "ember": tex_ember,
    "scorch": tex_scorch,
}


def preview(img, path, scale=4):
    """A nearest-neighbour enlargement over a dark checker background."""
    im = Image.fromarray(img, "RGBA")
    w, h = im.size
    bg = Image.new("RGBA", (w, h), (24, 24, 30, 255))
    px = bg.load()
    for yy in range(h):
        for xx in range(w):
            if ((xx // 4) + (yy // 4)) % 2:
                px[xx, yy] = (34, 34, 42, 255)
    bg.alpha_composite(im)
    bg.resize((w * scale, h * scale), Image.NEAREST).save(path)


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
