#!/usr/bin/env python3
"""HD-2D pre-rendered sprites (M2.1 art style option C, brief S-hd2d).

Renders a sculpt (tools/sculpt/<species>.py) into one sheet for a Luanti sprite entity: 6 columns x 4 rows of
size x size cells, written to OUT_DIR/style_hd2d.png. Rows are the 4 idle frames (whole body bobbed up and down by
0.006 nodes, y squashed by 1 %). Columns are the engine's view columns for set_sprite(..., select_x_by_camera=true):
COLUMN_VIEWS says which side of the creature each column shows.

Camera: orthographic, pitched down PITCH_DEG, looking along +z (Luanti's frame: +x to the right of the screen, +y up,
the creature faces -z when its yaw is 180). The creature is turned for each view instead of the camera moving.
Lighting is fixed to the screen (the same for every column): soft key from upper left, cool sky fill, ambient
occlusion from the sculpt, a warm fresnel rim from behind, and a 2 px dark outline outside the silhouette. Rendering
is 2x supersampled and box-filtered down, with straight alpha.

Usage: python3 -m tools.sculpt.render_sprites charmander OUT_DIR [--size 160]
"""

import argparse
import importlib
import math
import os
import sys
import time

import numpy as np
from PIL import Image
from scipy import ndimage

CELL_HALF = 0.52  # half the cell's width and height in nodes: the sprite visual_size is 2 * CELL_HALF = 1.04
TARGET = np.array([0.0, 0.39, 0.0])  # the cell's centre: half the creature's height above the feet
PITCH_DEG = 10.0  # the camera looks down by this much
SS = 2  # supersampling factor (box filter down to the cell size)
OUTLINE_PX = 2  # final pixels
OUTLINE_RGBA = (0x2A / 255.0, 0x14 / 255.0, 0x0C / 255.0, 0.9)
FRAMES = 4
COLS = 6
DIST = 1.0  # rays start this far in front of the target (the creature is within 0.5 nodes of it)

# Column c of the sheet shows view COLUMN_VIEWS[c]. Engine rule (.tools/luanti/src/client/content_cao.cpp,
# GenericCAO::updateTextureAnim): with the camera in front of the sprite, yaw 270 picks column 0, yaw 180 column 1,
# yaw 90 column 2, yaw 0 column 3, and the 4th and 5th columns are looking down and up. The views below are what the
# creature shows when its yaw is that value, seen from that camera. Checked in-engine by the S-hd2d shots.
COLUMN_VIEWS = ["right", "front", "left", "back", "front", "front"]
VIEW_YAW = {"front": 180.0, "left": 90.0, "back": 0.0, "right": 270.0}

# Lights and shading live in view space (x right, y up, z away from the camera).
_p = math.radians(PITCH_DEG)
VIEW_DIR = np.array([0.0, -math.sin(_p), math.cos(_p)])  # the camera looks this way
UP = np.array([0.0, math.cos(_p), math.sin(_p)])
TO_CAMERA = -VIEW_DIR


def _unit(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


KEY_DIR = _unit([-0.50, 0.80, -0.45])  # upper left, in front
KEY_COL = np.array([1.12, 1.06, 0.94])
FILL_DIR = _unit([0.80, 0.25, -0.50])  # right, a little in front
FILL_COL = np.array([0.55, 0.70, 1.00])  # cool sky
SKY = np.array([0.56, 0.72, 1.00])
GROUND = np.array([0.42, 0.30, 0.24])
RIM_DIR = _unit([0.35, 0.45, 1.00])  # behind, up and right
RIM_COL = np.array([1.00, 0.72, 0.40])  # warm
WRAP = 0.40  # wrap diffuse: light reaches a little past the terminator
UNLIT = {"eye_white": 0.75, "iris": 0.40}  # eyes stay crisp: part of their colour ignores the shading


def yaw_matrix(yaw_deg):
    """Creature (model) space to view space for a yaw in Luanti's convention: forward is (-sin yaw, cos yaw) in x, z.
    The rows are the view-space x, y, z of the model axes' images; M @ model = view."""
    t = math.radians(yaw_deg)
    c, s = math.cos(t), math.sin(t)
    return np.array([[-c, 0.0, s], [0.0, 1.0, 0.0], [-s, 0.0, -c]])


def idle_frame(k):
    """(bob, squash) for idle frame k of FRAMES: the body rises and falls by 0.006 nodes, squashed up to 1 %."""
    phi = 2.0 * math.pi * k / FRAMES
    return 0.006 * math.sin(phi), 1.0 - 0.01 * (1.0 - math.cos(phi)) / 2.0


def to_model(pv, M, bob, squash):
    """View-space points (N, 3) to the creature's model space: undo the bob and squash (y only), then the turn."""
    w = pv.copy()
    w[:, 1] = (w[:, 1] - bob) / squash
    return w @ M


def march(dist, origins, direction, max_t, steps=160, eps=0.0008):
    """Sphere tracing of parallel rays. Returns the ray parameter t (N,) and the hit mask (N,)."""
    n = len(origins)
    t = np.zeros(n)
    hit = np.zeros(n, bool)
    alive = np.ones(n, bool)
    for _ in range(steps):
        idx = np.nonzero(alive)[0]
        if idx.size == 0:
            break
        d = dist(origins[idx] + direction[idx] * t[idx, None])
        t[idx] += d * 0.9
        done = d < eps
        hit[idx[done]] = True
        alive[idx[done]] = False
        alive[idx[t[idx] > max_t]] = False
    return t, hit


def shade(s, p_model, M):
    """Lit colour (N, 3) and the view-space normals (N, 3) for the hit points."""
    n_model = s.normal(p_model)
    n = n_model @ M.T  # back to view space for the screen-fixed lights
    col, mats = s.colour(p_model)
    ao = s.ambient_occlusion(p_model, n_model)
    ndl = n @ KEY_DIR
    diff = np.clip((ndl + WRAP) / (1.0 + WRAP), 0.0, 1.0)
    fill = np.clip(n @ FILL_DIR, 0.0, 1.0)
    hemi = 0.5 + 0.5 * n[:, 1]
    ambient = (GROUND[None, :] * (1.0 - hemi)[:, None] + SKY[None, :] * hemi[:, None]) * (0.30 * ao)[:, None]
    key = KEY_COL[None, :] * (diff * (0.25 + 0.75 * ao))[:, None]
    fill_term = FILL_COL[None, :] * (0.22 * fill * ao)[:, None]
    fres = (1.0 - np.clip(n @ TO_CAMERA, 0.0, 1.0)) ** 2.5
    rim = RIM_COL[None, :] * (1.2 * fres * (0.3 + 0.7 * np.clip(n @ RIM_DIR, 0.0, 1.0)))[:, None]
    lit = col * (key + fill_term + ambient) + rim * col
    k = np.zeros(len(col))
    for mat, amount in UNLIT.items():
        k[mats == mat] = amount
    out = lit * (1.0 - k)[:, None] + col * k[:, None]
    return np.clip(out, 0.0, 1.0)


def render_cell(s, view, bob, squash, size):
    """One size x size cell (RGBA uint8, straight alpha) for a view and idle frame."""
    M = yaw_matrix(VIEW_YAW[view])
    n = size * SS
    xs = (np.arange(n) + 0.5) / n * 2.0 - 1.0
    gx, gy = np.meshgrid(xs, -xs)  # gy: row 0 is the top of the cell
    right = np.array([1.0, 0.0, 0.0])
    screen = (gx.reshape(-1, 1) * CELL_HALF) * right + (gy.reshape(-1, 1) * CELL_HALF) * UP
    origins = TARGET[None, :] + screen - VIEW_DIR[None, :] * DIST
    direction = np.broadcast_to(VIEW_DIR, origins.shape).copy()

    def dist(pv):
        return s.sdf(to_model(pv, M, bob, squash))

    t, hit = march(dist, origins, direction, max_t=2.0 * DIST)
    rgb = np.zeros((n * n, 3))
    alpha = np.zeros(n * n)
    idx = np.nonzero(hit)[0]
    pv = origins[idx] + direction[idx] * t[idx, None]
    pm = to_model(pv, M, bob, squash)
    rgb[idx] = shade(s, pm, M)
    alpha[idx] = 1.0
    hit_img = hit.reshape(n, n)
    # Outline: the ring of background pixels within OUTLINE_PX (final scale) of the silhouette.
    dist_out = ndimage.distance_transform_edt(~hit_img)
    ring = (~hit_img) & (dist_out <= OUTLINE_PX * SS)
    rgb[ring.ravel()] = OUTLINE_RGBA[:3]
    alpha[ring.ravel()] = OUTLINE_RGBA[3]
    rgb = rgb.reshape(n, n, 3)
    alpha = alpha.reshape(n, n)
    # Box filter with premultiplied colour, then straight alpha again.
    prem = (rgb * alpha[..., None]).reshape(size, SS, size, SS, 3).mean(axis=(1, 3))
    a = alpha.reshape(size, SS, size, SS).mean(axis=(1, 3))
    straight = np.where(a[..., None] > 1e-6, prem / np.maximum(a[..., None], 1e-6), 0.0)
    out = np.zeros((size, size, 4), np.uint8)
    out[..., :3] = np.round(np.clip(straight, 0.0, 1.0) * 255).astype(np.uint8)
    out[..., 3] = np.round(np.clip(a, 0.0, 1.0) * 255).astype(np.uint8)
    return out


def render_sheet(s, size):
    """The 6 x 4 sheet: rows are idle frames, columns are COLUMN_VIEWS."""
    sheet = np.zeros((FRAMES * size, COLS * size, 4), np.uint8)
    for f in range(FRAMES):
        bob, squash = idle_frame(f)
        cache = {}
        for c, view in enumerate(COLUMN_VIEWS):
            if view not in cache:
                cache[view] = render_cell(s, view, bob, squash, size)
            sheet[f * size:(f + 1) * size, c * size:(c + 1) * size] = cache[view]
    return sheet


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("species")
    ap.add_argument("out_dir")
    ap.add_argument("--size", type=int, default=160)
    args = ap.parse_args(argv)
    if args.size < 16:
        ap.error("--size must be at least 16")
    started = time.time()
    mod = importlib.import_module("tools.sculpt." + args.species)
    sculpt = mod.build()
    sheet = render_sheet(sculpt, args.size)
    os.makedirs(args.out_dir, exist_ok=True)
    path = os.path.join(args.out_dir, "style_hd2d.png")
    Image.fromarray(sheet, "RGBA").save(path)
    print(f"wrote {path} ({COLS}x{FRAMES} cells of {args.size} px) in {time.time() - started:.1f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
