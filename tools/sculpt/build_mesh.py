#!/usr/bin/env python3
"""Sculpt to a smooth, rigged, textured creature mesh (M2.1 art styles "cel" and "painted"; D-032).

  1. Sample the sculpt's SDF on a fine grid; marching cubes gives the surface; quadric decimation brings it to the
     triangle budget (default 2600: cheap for an AMD Vega 8 and for Luanti's CPU skinning).
  2. Vertices are pulled back onto the true surface and get the SDF's normals (smooth, exact shading).
  3. Skin weights come from part proximity (sdf.Sculpt.bone_weights): soft joints.
  4. The texture is a PER-TRIANGLE ATLAS: every triangle owns an 8x8 texel cell, and every texel is shaded from the
     sculpt at its own 3D point. So eyes, mouths and markings are as crisp as the texel size (about 3 mm), whatever
     the polygon count, and the style shader (cel bands, ambient occlusion, rim, grain) is baked in. Cells are ordered
     along the surface (by material, then a Morton curve) so mipmaps blend neighbours of the same colour.
  5. "cel" also gets an ink outline: an inside-out copy of the mesh pushed out along the normals (back-face culling
     keeps only the rim), coloured with a dark ink of the local colour.

Usage: python3 -m tools.sculpt.build_mesh charmander OUT_DIR --style cel|painted [--tris 2600]
Writes OUT_DIR/style_<style>.glb and .png.
"""

import argparse
import importlib
import math
import os
import sys

import numpy as np
from PIL import Image
from skimage import measure
import pyfqmr

from . import rig

CELL = 8
BOUNDS = ((-0.34, 0.34), (-0.03, 0.84), (-0.34, 0.54))


# ---------------------------------------------------------------- surface

def sample_volume(sculpt, step):
    axes = [np.arange(lo, hi + step, step) for lo, hi in BOUNDS]
    gx, gy, gz = np.meshgrid(*axes, indexing="ij")
    pts = np.stack([gx.ravel(), gy.ravel(), gz.ravel()], axis=1)
    out = np.empty(len(pts))
    chunk = 200000
    for i in range(0, len(pts), chunk):
        out[i:i + chunk] = sculpt.sdf(pts[i:i + chunk])
    return out.reshape(gx.shape), np.array([a[0] for a in axes])


def surface_mesh(sculpt, step, tris):
    vol, origin = sample_volume(sculpt, step)
    verts, faces, _n, _v = measure.marching_cubes(vol, 0.0, spacing=(step, step, step))
    verts = verts + origin
    simp = pyfqmr.Simplify()
    simp.setMesh(verts, faces)
    simp.simplify_mesh(target_count=tris, aggressiveness=7, preserve_border=True, verbose=False)
    verts, faces, _norms = simp.getMesh()
    verts = np.asarray(verts, float)
    faces = np.asarray(faces, int)
    for _ in range(3):  # back onto the exact surface
        n = sculpt.normal(verts)
        verts = verts - n * sculpt.sdf(verts)[:, None]
    normals = sculpt.normal(verts)
    # Counter-clockwise seen from outside: the face normal must agree with the SDF normal.
    fn = np.cross(verts[faces[:, 1]] - verts[faces[:, 0]], verts[faces[:, 2]] - verts[faces[:, 0]])
    centroid_n = normals[faces].mean(axis=1)
    flip = (fn * centroid_n).sum(axis=1) < 0
    faces[flip] = faces[flip][:, [0, 2, 1]]
    return verts, faces, normals


# ---------------------------------------------------------------- atlas

def _morton(p):
    q = np.clip(((p - p.min(axis=0)) / max(np.ptp(p, axis=0).max(), 1e-9) * 1023).astype(np.int64), 0, 1023)
    code = np.zeros(len(p), dtype=np.int64)
    for bit in range(10):
        for axis in range(3):
            code |= ((q[:, axis] >> bit) & 1) << (3 * bit + axis)
    return code


def _cell_barycentrics():
    """Barycentric weights (64, 3) of each texel centre of a cell for the triangle a=(0.5,0.5), b=(7.5,0.5),
    c=(0.5,7.5) in texel units, clamped onto the triangle (padding texels repeat the nearest edge)."""
    a, b, c = np.array([0.5, 0.5]), np.array([CELL - 0.5, 0.5]), np.array([0.5, CELL - 0.5])
    ys, xs = np.mgrid[0:CELL, 0:CELL]
    p = np.stack([xs.ravel() + 0.5, ys.ravel() + 0.5], axis=1)
    v0, v1, v2 = b - a, c - a, p - a
    d00, d01, d11 = v0 @ v0, v0 @ v1, v1 @ v1
    d20, d21 = v2 @ v0, v2 @ v1
    den = d00 * d11 - d01 * d01
    w1 = (d11 * d20 - d01 * d21) / den
    w2 = (d00 * d21 - d01 * d20) / den
    bary = np.stack([1 - w1 - w2, w1, w2], axis=1)
    bary = np.clip(bary, 0.0, None)
    bary /= bary.sum(axis=1, keepdims=True)
    return bary, (a, b, c)


def _noise3(p, freq, seed=3):
    """Cheap smooth value noise in 3D (for grain), 0..1."""
    rng = np.random.RandomState(seed)
    lat = rng.rand(64, 64, 64)
    q = p * freq
    i = np.floor(q).astype(int)
    f = q - i
    f = f * f * (3 - 2 * f)
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[:, 0] if dx else 1 - f[:, 0]) * (f[:, 1] if dy else 1 - f[:, 1]) * (f[:, 2] if dz else 1 - f[:, 2])
                out = out + w * lat[(i[:, 0] + dx) % 64, (i[:, 1] + dy) % 64, (i[:, 2] + dz) % 64]
    return out


KEY = np.array([-0.5, 0.75, -0.45])
KEY = KEY / np.linalg.norm(KEY)
UNSHADED = {"eye", "eye_white", "iris"}


def shade(style, sculpt, p, n, colour, mats):
    ao = sculpt.ambient_occlusion(p, n)
    ndl = n @ KEY
    flat = np.isin(mats, list(UNSHADED))
    if style == "cel":
        lit = np.clip((ndl + 0.05) / 0.05, 0.0, 1.0)  # a hard terminator, about 2 texels soft
        bright = np.clip(colour * 1.08, 0, 1)
        shadow = np.clip(colour ** 1.4 * np.array([0.80, 0.62, 0.74]), 0, 1)  # deep, warm, a touch violet
        out = shadow * (1 - lit[:, None]) + bright * lit[:, None]
        crease = np.clip((0.88 - ao) / 0.3, 0.0, 1.0)  # ink-like occlusion only in tight creases
        out = out * (1.0 - 0.45 * crease[:, None])
        # A crisp specular sheen where the key light grazes the top of the head and shoulders.
        spec = np.clip((n @ (KEY + np.array([0, 1.0, 0])) / np.linalg.norm(KEY + np.array([0, 1.0, 0])) - 0.93)
                       / 0.03, 0, 1)
        out = np.clip(out + 0.22 * spec[:, None], 0, 1)
    else:  # painted: storybook light (warm key, cool shade), painted occlusion and brush strokes
        wrap = np.clip((ndl + 0.35) / 1.35, 0, 1)
        warm_light = np.array([1.06, 0.98, 0.84])
        cool_shade = np.array([0.62, 0.62, 0.86])
        tint = cool_shade[None, :] * (1 - wrap[:, None]) + warm_light[None, :] * wrap[:, None]
        out = colour * tint * (0.62 + 0.42 * wrap)[:, None]
        out = out * (0.55 + 0.45 * ao ** 1.5)[:, None] + (1 - ao)[:, None] * np.array([0.05, 0.02, 0.10]) * 0.6
        # Brush strokes: noise stretched along the surface's horizontal direction (dabs of paint).
        stretched = p * np.array([1.0, 4.0, 1.0])
        strokes = (_noise3(stretched, 55.0) - 0.5) * 0.16 + (_noise3(p, 140.0, 5) - 0.5) * 0.06
        out = np.clip(out * (1.0 + strokes[:, None]), 0, 1)
        lum = (out * np.array([0.3, 0.59, 0.11])).sum(axis=1, keepdims=True)
        out = np.clip(lum + (out - lum) * 0.9, 0, 1)
    # Eyes stay graphic: a light touch of shading only.
    eye_shade = colour * (0.85 + 0.15 * np.clip(ndl, 0, 1))[:, None]
    out[flat] = eye_shade[flat]
    return out


def build(species, out_dir, style, tris=2600, step=0.006):
    mod = importlib.import_module("tools.sculpt." + species)
    sculpt = mod.build()
    verts, faces, normals = surface_mesh(sculpt, step, tris)
    T = len(faces)
    # Order triangles along the surface: material of the centroid, then Morton order.
    cent = verts[faces].mean(axis=1)
    _c, cmats = sculpt.colour(cent)
    mat_rank = np.unique(cmats, return_inverse=True)[1]
    order = np.lexsort((_morton(cent), mat_rank))
    faces = faces[order]
    inks = sorted(set(sculpt.palette))
    cells = T + len(inks)
    per_row = int(math.ceil(math.sqrt(cells)))
    size = 1 << int(math.ceil(math.log2(per_row * CELL)))
    per_row = size // CELL
    bary, (a2, b2, c2) = _cell_barycentrics()
    # Texel points for every triangle cell.
    tri = verts[faces]  # (T, 3, 3)
    pts = np.einsum("kj,tjc->tkc", bary, tri).reshape(-1, 3)
    for _ in range(2):
        nn = sculpt.normal(pts)
        pts = pts - nn * sculpt.sdf(pts)[:, None]
    nrm = sculpt.normal(pts)
    col, mats = sculpt.colour(pts)
    texels = shade(style, sculpt, pts, nrm, col, mats).reshape(T, CELL, CELL, 3)
    img = np.zeros((size, size, 4))
    for t in range(T):
        cx, cy = (t % per_row) * CELL, (t // per_row) * CELL
        img[cy:cy + CELL, cx:cx + CELL, :3] = texels[t]
        img[cy:cy + CELL, cx:cx + CELL, 3] = 1.0
    ink_uv = {}
    for k, m in enumerate(inks):
        cell = T + k
        cx, cy = (cell % per_row) * CELL, (cell // per_row) * CELL
        base = np.array(sculpt.palette[m])
        img[cy:cy + CELL, cx:cx + CELL, :3] = np.clip(base ** 1.6 * 0.32, 0, 1)
        img[cy:cy + CELL, cx:cx + CELL, 3] = 1.0
        ink_uv[m] = ((cx + CELL / 2) / size, (cy + CELL / 2) / size)
    # Unshared vertices: three per triangle, each with its cell UV.
    corners2d = [a2, b2, c2]
    pos, nor, uvs, jts, wts, idx = [], [], [], [], [], []
    vj, vw = sculpt.bone_weights(verts)
    for t in range(T):
        cx, cy = (t % per_row) * CELL, (t // per_row) * CELL
        for k in range(3):
            vi = faces[t, k]
            pos.append(verts[vi])
            nor.append(normals[vi])
            uvs.append(((cx + corners2d[k][0]) / size, (cy + corners2d[k][1]) / size))
            jts.append(vj[vi])
            wts.append(vw[vi])
        idx += [3 * t, 3 * t + 1, 3 * t + 2]
    if style == "cel":
        # The ink hull: shared vertices pushed out, inside out, coloured by the nearest material's ink.
        width = 0.012
        _vc, vmats = sculpt.colour(verts)
        base = len(pos)
        for vi in range(len(verts)):
            pos.append(verts[vi] + normals[vi] * width)
            nor.append(-normals[vi])
            uvs.append(ink_uv[vmats[vi]])
            jts.append(vj[vi])
            wts.append(vw[vi])
        for f in faces:
            idx += [base + f[0], base + f[2], base + f[1]]
    os.makedirs(out_dir, exist_ok=True)
    glb = os.path.join(out_dir, "style_%s.glb" % style)
    png = os.path.join(out_dir, "style_%s.png" % style)
    rig.export_glb(sculpt, np.array(pos), np.array(nor), uvs, np.array(jts), np.array(wts), idx, glb)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGBA").save(png, optimize=True)
    print("build_mesh: %s %s: %d triangles (+%s outline), %d vertices, texture %dx%d"
          % (species, style, T, T if style == "cel" else 0, len(pos), size, size))
    return glb, png


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("species")
    ap.add_argument("out")
    ap.add_argument("--style", default="cel", choices=["cel", "painted"])
    ap.add_argument("--tris", type=int, default=2600)
    args = ap.parse_args(argv)
    build(args.species, args.out, args.style, args.tris)
    return 0


if __name__ == "__main__":
    sys.exit(main())
