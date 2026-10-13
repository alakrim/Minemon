"""Micro-voxel builder (M2.1, art style option B): a sculpt voxelized at a fine grain, one colour and one bone per voxel,
baked ambient occlusion and face shading, exported as an animated GLB plus a palette atlas PNG.

Usage: python3 -m tools.sculpt.build_voxel charmander OUT_DIR [--voxel 0.025] [--seed 1]
Writes OUT_DIR/style_voxel.glb and OUT_DIR/style_voxel.png and prints the triangle count and texture size.

Method: the sculpt's sdf is sampled at voxel centres over a fixed box (a cell is solid when sdf <= 0). Each solid voxel
takes the bone with the highest skin weight at its centre. Its colour is sampled at the centre pushed onto the surface,
multiplied by (0.55 + 0.45 * ao) and a seeded +-3% brightness jitter; faces are shaded top 1.08, sides 1.0, bottom 0.8.
Only exposed faces are emitted, greedy-merged per slice when colour, shade and bone are equal. Each distinct final
colour owns a 2x2-texel cell of a square power-of-two atlas, and every corner of a face uses the cell centre, so
nearest filtering shows a flat colour.
"""

import argparse
import importlib
import os
import sys
import time

import numpy as np
from PIL import Image

from . import rig

LO = np.array([-0.35, -0.02, -0.35])
HI = np.array([0.35, 0.82, 0.55])


def set_grid(lo, hi):
    """Sets the voxel grid box (nodes) for the next build (voxel_cobblemon.py sizes it per species)."""
    global LO, HI
    LO = np.asarray(lo, float)
    HI = np.asarray(hi, float)
JITTER = 0.03
ATLAS_MAX = 512
BONE_BITS = 4096  # bone index must fit below this in the merge key (Charizard has more than 64 bones)

# (axis, sign) -> face shade: top up, bottom down, sides neutral (baked sun).
FACES = [(0, 1), (0, -1), (1, 1), (1, -1), (2, 1), (2, -1)]


def _shade(axis, sign):
    if axis == 1:
        return 1.08 if sign > 0 else 0.8
    return 1.0


def _grid(voxel):
    span = HI - LO
    dims = np.array([int(np.ceil(s / voxel - 1e-6)) for s in span])
    axes = [LO[i] + (np.arange(dims[i]) + 0.5) * voxel for i in range(3)]
    centres = np.stack(np.meshgrid(*axes, indexing="ij"), axis=-1)
    return dims, centres


def voxelize(sculpt, voxel, seed):
    """Returns (dims, solid, bone, rgb) where rgb is the per-voxel base colour (0..1) for solid voxels."""
    dims, centres = _grid(voxel)
    flat = centres.reshape(-1, 3)
    solid_flat = sculpt.sdf(flat) <= 0.0
    solid = solid_flat.reshape(dims)
    pts = flat[solid_flat]

    joints, _weights = sculpt.bone_weights(pts)
    bone_flat = np.zeros(len(flat), dtype=np.int64)
    bone_flat[solid_flat] = joints[:, 0]

    d = sculpt.sdf(pts)
    n = sculpt.normal(pts)
    surf = pts - n * d[:, None]  # pushed onto the surface
    ns = sculpt.normal(surf)
    rgb, _mats = sculpt.colour(surf)
    ao = sculpt.ambient_occlusion(surf, ns)
    rng = np.random.default_rng(seed)
    jitter = 1.0 + rng.uniform(-JITTER, JITTER, size=len(pts))
    base = rgb * ((0.55 + 0.45 * ao) * jitter)[:, None]

    rgb_grid = np.zeros(dims.tolist() + [3])
    rgb_grid.reshape(-1, 3)[solid_flat] = base
    bone = bone_flat.reshape(dims)
    return dims, solid, bone, rgb_grid


def _exposed(solid, axis, sign):
    """Solid voxels whose neighbour along (axis, sign) is empty or outside the grid."""
    shifted = np.zeros_like(solid)
    src = [slice(None)] * 3
    dst = [slice(None)] * 3
    if sign > 0:
        src[axis], dst[axis] = slice(1, None), slice(0, -1)
    else:
        src[axis], dst[axis] = slice(0, -1), slice(1, None)
    shifted[tuple(dst)] = solid[tuple(src)]
    return solid & ~shifted


def _greedy(keys):
    """Greedy rectangles over a 2D int array (-1 is empty). Returns (i, j, h, w, key) with h along the first axis."""
    nu, nv = keys.shape
    used = np.zeros((nu, nv), bool)
    rects = []
    for i in range(nu):
        for j in range(nv):
            key = keys[i, j]
            if key < 0 or used[i, j]:
                continue
            w = 1
            while j + w < nv and keys[i, j + w] == key and not used[i, j + w]:
                w += 1
            h = 1
            while i + h < nu and np.all(keys[i + h, j:j + w] == key) and not np.any(used[i + h, j:j + w]):
                h += 1
            used[i:i + h, j:j + w] = True
            rects.append((i, j, h, w, int(key)))
    return rects


def _code(rgb):
    c8 = np.clip(np.round(rgb * 255.0), 0, 255).astype(np.int64)
    return (c8[..., 0] * 256 + c8[..., 1]) * 256 + c8[..., 2]


# Face detail (M2.1 owner feedback: "the face must be great"): voxel faces that show part of a face feature (eyes,
# mouth, nostrils: the sculpt's FACE_MATS) are not merged and get their own DETAIL x DETAIL texel cell, painted from
# the sculpt at texel resolution. Eyes become crisp ovals with an iris and two catch lights while the silhouette stays
# voxel. Only a few dozen faces qualify, so the atlas and triangle cost stay small.
DETAIL = 6
FACE_MATS = {"eye", "iris", "iris_light", "eye_white", "mouth", "nostril", "brow"}
CELL = DETAIL


def _face_points(axis, sign, idx, voxel, fu, fv):
    """3D points on the faces of voxels idx (k, 3 int) at face parameters fu, fv in 0..1 (arrays of equal length)."""
    u, v = (axis + 1) % 3, (axis + 2) % 3
    p = LO[None, :] + (idx + 0.5) * voxel
    p = np.repeat(p, len(fu), axis=0)
    p[:, axis] += sign * voxel / 2
    p[:, u] = LO[u] + (np.repeat(idx[:, u], len(fu)) + np.tile(fu, len(idx))) * voxel
    p[:, v] = LO[v] + (np.repeat(idx[:, v], len(fv)) + np.tile(fv, len(idx))) * voxel
    return p


def _surface(sculpt, p, steps=2):
    for _ in range(steps):
        n = sculpt.normal(p)
        p = p - n * sculpt.sdf(p)[:, None]
    return p


def build_mesh(dims, solid, bone, rgb_grid, voxel, sculpt=None, rgb_grid2=None):
    """Returns the quads: (axis, sign, plane value, u0, v0, h, w, code, bone, detail_index or -1), and the detail
    faces [(axis, sign, voxel index)]."""
    quads = []
    details = []
    probe_u = np.array([0.5, 0.2, 0.8, 0.2, 0.8])
    probe_v = np.array([0.5, 0.2, 0.2, 0.8, 0.8])
    face_mats = getattr(sculpt, "face_mats", FACE_MATS) if sculpt is not None else set()
    for axis, sign in FACES:
        exposed = _exposed(solid, axis, sign)
        shade = _shade(axis, sign)
        code = _code(np.clip(rgb_grid * shade, 0.0, 1.0))
        if rgb_grid2 is not None:  # a second skin (the shiny) shares the mesh: the key holds both colours
            code = code * PAIR + _code(np.clip(rgb_grid2 * shade, 0.0, 1.0))
        keys = np.where(exposed, code * BONE_BITS + bone, -1)
        detail_id = np.full(dims.tolist(), -1, dtype=np.int64)
        if sculpt is not None:
            idx = np.argwhere(exposed)
            pts = _surface(sculpt, _face_points(axis, sign, idx, voxel, probe_u, probe_v))
            mats = sculpt.material(pts).reshape(len(idx), len(probe_u))
            hit = np.isin(mats, list(face_mats)).any(axis=1)
            for vi in idx[hit]:
                detail_id[tuple(vi)] = len(details)
                details.append((axis, sign, vi))
            keys[detail_id >= 0] = -1
        u, v = (axis + 1) % 3, (axis + 2) % 3
        keys_t = np.transpose(keys, (axis, u, v))
        det_t = np.transpose(detail_id, (axis, u, v))
        bone_t = np.transpose(bone, (axis, u, v))
        for k in range(dims[axis]):
            plane = LO[axis] + (k + (1 if sign > 0 else 0)) * voxel
            if np.any(keys_t[k] >= 0):
                for i, j, h, w, key in _greedy(keys_t[k]):
                    quads.append((axis, sign, plane, i, j, h, w, key // BONE_BITS, key % BONE_BITS, -1))
            for i, j in np.argwhere(det_t[k] >= 0):
                quads.append((axis, sign, plane, int(i), int(j), 1, 1, -1, int(bone_t[k, i, j]), int(det_t[k, i, j])))
    return quads, details


def quad_vertices(axis, sign, plane, u0, v0, h, w, voxel):
    """Four corners counter-clockwise seen from outside (normal = sign * e_axis), with their face parameters."""
    u, v = (axis + 1) % 3, (axis + 2) % 3
    corners = [(u0, v0), (u0 + h, v0), (u0 + h, v0 + w), (u0, v0 + w)]
    pts = []
    for cu, cv in corners:
        p = np.zeros(3)
        p[axis] = plane
        p[u] = LO[u] + cu * voxel
        p[v] = LO[v] + cv * voxel
        pts.append((p, (cu - u0) / h, (cv - v0) / w))
    if sign < 0:
        pts = [pts[0], pts[3], pts[2], pts[1]]
    return pts


def paint_details(sculpt, details, rgb_grid, voxel):
    """DETAIL x DETAIL texels per detail face: the sculpt's colour at each texel's surface point, lit like the voxel
    (its AO and jitter come from the voxel's own colour), face materials kept graphic. Returns (n, D, D, 3)."""
    if not details:
        return np.zeros((0, DETAIL, DETAIL, 3))
    t = (np.arange(DETAIL) + 0.5) / DETAIL
    fu = np.repeat(t, DETAIL)  # texel (row = u index, col = v index)
    fv = np.tile(t, DETAIL)
    out = np.zeros((len(details), DETAIL * DETAIL, 3))
    by_dir = {}
    for n, (axis, sign, vi) in enumerate(details):
        by_dir.setdefault((axis, sign), []).append((n, vi))
    for (axis, sign), items in by_dir.items():
        idx = np.array([vi for _n, vi in items])
        pts = _surface(sculpt, _face_points(axis, sign, idx, voxel, fu, fv))
        col, mats = sculpt.colour(pts)
        base_rgb, _m = sculpt.colour(_surface(sculpt, LO[None, :] + (idx + 0.5) * voxel))
        voxel_rgb = rgb_grid[tuple(idx.T)]
        light = np.clip(voxel_rgb.sum(axis=1) / np.maximum(base_rgb.sum(axis=1), 1e-6), 0.4, 1.2)
        light = np.repeat(light, DETAIL * DETAIL) * _shade(axis, sign)
        graphic = np.isin(mats, list(FACE_MATS))
        lit = col * light[:, None]
        lit[graphic] = col[graphic] * np.clip(0.75 + 0.3 * light[graphic], 0, 1.05)[:, None]
        lit = np.clip(lit, 0, 1).reshape(len(items), DETAIL * DETAIL, 3)
        for k, (n, _vi) in enumerate(items):
            out[n] = lit[k]
    return out.reshape(len(details), DETAIL, DETAIL, 3)


PAIR = 1 << 24  # colour codes are 24-bit RGB; a pair (normal, shiny) is base * PAIR + shiny


def _rgb_of(code):
    return code // 65536, (code // 256) % 256, code % 256


def assemble(sculpt, dims, quads, voxel, details=(), rgb_grid=None, sculpt2=None, rgb_grid2=None):
    """Turns quads into GLB arrays and the atlas. Flat colours get a CELL x CELL cell (sampled at its centre); detail
    faces get a painted cell mapped corner to corner. With sculpt2/rgb_grid2 (the shiny skin) the codes are pairs and
    a second atlas with the same layout is painted. Returns (mesh dict, atlas array, atlas size[, atlas2])."""
    colours = sorted({q[7] for q in quads if q[9] < 0})
    cells = len(colours) + len(details)
    per_row = 1
    while per_row * per_row < cells:
        per_row *= 2
    side = per_row * CELL
    while side & (side - 1):
        side += 1
    if side > ATLAS_MAX * 2:
        raise SystemExit("FAIL: %d cells do not fit the atlas" % cells)
    cell_of = {c: i for i, c in enumerate(colours)}
    paired = rgb_grid2 is not None
    atlases = []
    for which in ((0, 1) if paired else (0,)):
        atlas = np.zeros((side, side, 3), np.uint8)
        for code, cell in cell_of.items():
            c = (code // PAIR if which == 0 else code % PAIR) if paired else code
            cx, cy = cell % per_row, cell // per_row
            atlas[CELL * cy:CELL * cy + CELL, CELL * cx:CELL * cx + CELL] = _rgb_of(c)
        sc, grid = (sculpt, rgb_grid) if which == 0 else (sculpt2, rgb_grid2)
        painted = paint_details(sc, list(details), grid, voxel) if len(details) else None
        for n in range(len(details)):
            cell = len(colours) + n
            cx, cy = cell % per_row, cell // per_row
            # Rows of the cell run along the face's v axis, columns along u (see the UVs below).
            atlas[CELL * cy:CELL * cy + CELL, CELL * cx:CELL * cx + CELL] = \
                (np.clip(np.transpose(painted[n], (1, 0, 2)), 0, 1) * 255 + 0.5).astype(np.uint8)
        atlases.append(atlas)
    atlas = atlases[0]

    positions, normals, uvs, joints, weights, indices = [], [], [], [], [], []
    for axis, sign, plane, u0, v0, h, w, code, bone, det in quads:
        pts = quad_vertices(axis, sign, plane, u0, v0, h, w, voxel)
        n = np.zeros(3)
        n[axis] = sign
        if det < 0:
            cell = cell_of[code]
        else:
            cell = len(colours) + det
        cx, cy = cell % per_row, cell // per_row
        base = len(positions)
        for p, fu, fv in pts:
            positions.append(tuple(float(x) for x in p))
            normals.append(tuple(float(x) for x in n))
            if det < 0:
                uvs.append(((CELL * cx + CELL / 2) / side, (CELL * cy + CELL / 2) / side))
            else:
                uvs.append(((CELL * cx + fu * CELL) / side, (CELL * cy + fv * CELL) / side))
            joints.append((bone, 0, 0, 0))
            weights.append((1.0, 0.0, 0.0, 0.0))
        indices += [base, base + 1, base + 2, base, base + 2, base + 3]
    mesh = {"positions": positions, "normals": normals, "uvs": uvs, "joints": joints, "weights": weights,
            "indices": indices}
    if paired:
        return mesh, atlas, side, atlases[1]
    return mesh, atlas, side


def build(sculpt, out_dir, voxel=0.025, seed=1):
    t0 = time.time()
    dims, solid, bone, rgb_grid = voxelize(sculpt, voxel, seed)
    quads, details = build_mesh(dims, solid, bone, rgb_grid, voxel, sculpt)
    mesh, atlas, side = assemble(sculpt, dims, quads, voxel, details, rgb_grid)
    os.makedirs(out_dir, exist_ok=True)
    glb_path = os.path.join(out_dir, "style_voxel.glb")
    png_path = os.path.join(out_dir, "style_voxel.png")
    rig.export_glb(sculpt, mesh["positions"], mesh["normals"], mesh["uvs"], mesh["joints"], mesh["weights"],
                   mesh["indices"], glb_path)
    Image.fromarray(atlas).save(png_path)
    tris = len(mesh["indices"]) // 3
    print("voxels: %d solid, grid %s, voxel %.4f" % (int(solid.sum()), "x".join(str(d) for d in dims), voxel))
    print("triangles: %d" % tris)
    print("texture: %dx%d (%d colours, %d face-detail cells)" % (side, side, len({q[7] for q in quads if q[9] < 0}),
                                                                 len(details)))
    print("written: %s %s (%.1f s)" % (glb_path, png_path, time.time() - t0))
    return tris, side


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("species")
    ap.add_argument("out_dir")
    ap.add_argument("--voxel", type=float, default=0.025)
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args(argv)
    mod = importlib.import_module("tools.sculpt." + args.species)
    sculpt = mod.build()
    build(sculpt, args.out_dir, args.voxel, args.seed)
    return 0


if __name__ == "__main__":
    sys.exit(main())
