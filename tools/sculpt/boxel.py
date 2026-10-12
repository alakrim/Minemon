"""Boxel: the "voxel hero" creature style (M2.1, D-032). Chunky bevelled boxes with hand-painted-looking pixel art.

A creature is a list of Box (a bevelled, optionally rotated box that belongs to one bone) plus 3D decals (eyes,
belly, mouth: sdf.Decal regions). The builder:
  * meshes every box as a bevelled box (smooth normals over the bevel), rigid on its bone;
  * gives every box face its own texture region at TEXELS_PER_NODE (crisp nearest-filtered pixels);
  * paints each texel from its 3D point: material (box material, then decals on top), real ambient occlusion from
    the union of all boxes (contact shadows where parts meet), a top light, bevel highlights on upper edges and
    shade on lower ones, then pixel-art quantisation: the brightness snaps to a few bands per material with a 4x4
    ordered dither between bands (the stepped shading of painted voxel art). Graphic materials (eyes, claws, mouth)
    keep flat colour;
  * rigs and exports through rig.export_glb (the six shared clips).
Budget: about 40 boxes, 1-2k triangles, one texture of at most 512x512.
"""

import math

import numpy as np
from PIL import Image

from . import rig
from . import sdf as S

TEXELS_PER_NODE = 64
BEVEL = 0.018
BANDS = 4
BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0 - 0.5
FACES = {  # normal, u axis, v axis (v runs down the image), for a box in its local frame
    "front": ((0, 0, -1), (-1, 0, 0), (0, -1, 0)),
    "back": ((0, 0, 1), (1, 0, 0), (0, -1, 0)),
    "left": ((1, 0, 0), (0, 0, -1), (0, -1, 0)),
    "right": ((-1, 0, 0), (0, 0, 1), (0, -1, 0)),
    "top": ((0, 1, 0), (-1, 0, 0), (0, 0, 1)),
    "bottom": ((0, -1, 0), (-1, 0, 0), (0, 0, -1)),
}


def rot_matrix(deg):
    x, y, z = [math.radians(a) for a in deg]
    rx = np.array([[1, 0, 0], [0, math.cos(x), -math.sin(x)], [0, math.sin(x), math.cos(x)]])
    ry = np.array([[math.cos(y), 0, math.sin(y)], [0, 1, 0], [-math.sin(y), 0, math.cos(y)]])
    rz = np.array([[math.cos(z), -math.sin(z), 0], [math.sin(z), math.cos(z), 0], [0, 0, 1]])
    return rz @ ry @ rx


class Box:
    """centre and size in nodes; rot in degrees (x, then y, then z) about the centre; mat a palette key;
    bevel in nodes (None: the default); flat: graphic material, no light bands (claws)."""

    def __init__(self, name, bone, centre, size, mat, rot=(0, 0, 0), bevel=None):
        self.name = name
        self.bone = bone
        self.c = np.asarray(centre, float)
        self.h = np.asarray(size, float) / 2.0
        self.mat = mat
        self.R = rot_matrix(rot)
        self.bevel = BEVEL if bevel is None else bevel

    def sdf(self, p):
        q = np.abs((p - self.c) @ self.R) - (self.h - self.bevel)
        out = np.sqrt((np.maximum(q, 0.0) ** 2).sum(axis=1))
        return out + np.minimum(q.max(axis=1), 0.0) - self.bevel


class Model:
    def __init__(self, boxes, decals, palette, bones, locators, pose, flat=("eye", "eye_white", "iris", "claw",
                                                                             "mouth", "nostril")):
        self.boxes = boxes
        self.decals = decals
        self.palette = palette
        self.bones = bones
        self.locators = locators
        self.pose = pose
        self.flat = set(flat)
        self.bone_index = {b[0]: i for i, b in enumerate(bones)}

    def sdf(self, p):
        return np.min(np.stack([b.sdf(p) for b in self.boxes], axis=1), axis=1)

    def normal(self, p, eps=0.002):
        e = np.eye(3) * eps
        n = np.stack([self.sdf(p + e[i]) - self.sdf(p - e[i]) for i in range(3)], axis=1)
        return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)

    def ao(self, p, n, step=0.02, count=5):
        occ = np.zeros(len(p))
        for i in range(1, count + 1):
            h = step * i
            occ += (h - self.sdf(p + n * h)) / (2.0 ** i)
        return np.clip(1.0 - 2.4 * occ / step, 0.0, 1.0)


def _face_mesh(box, face, grid_u, grid_v):
    """Vertices of one bevelled face: a grid whose outer ring is bent onto the bevel. Returns local points,
    normals, (s, t) in 0..1 and quads."""
    n, ua, va = [np.array(v, float) for v in FACES[face]]
    h = box.h
    hn = abs(n @ h)
    hu = abs(ua @ h)
    hv = abs(va @ h)
    r = min(box.bevel, 0.45 * min(h * 2))

    def ticks(half):
        if r <= 0 or half * 2 <= 2 * r + 1e-6:
            return [0.0, 1.0]
        return [0.0, r / (2 * half), 1 - r / (2 * half), 1.0]
    tu, tv = ticks(hu), ticks(hv)
    inner = h - r
    pts, nrm, st = [], [], []
    for t in tv:
        for s in tu:
            p = n * hn + ua * (s * 2 - 1) * hu + va * (t * 2 - 1) * hv
            q = np.clip(p, -inner, inner)
            d = p - q
            ln = np.linalg.norm(d)
            nn = d / ln if ln > 1e-9 else n
            pts.append(q + nn * r if ln > 1e-9 else p)
            nrm.append(nn)
            st.append((s, t))
    nu = len(tu)
    quads = []
    for j in range(len(tv) - 1):
        for i in range(nu - 1):
            a = j * nu + i
            quads.append((a, a + nu, a + nu + 1, a + 1))
    return np.array(pts), np.array(nrm), st, quads, (hu * 2, hv * 2)


def _bands(colour, light, dither):
    """Pixel-art light: brightness snapped to BANDS steps with ordered dither between steps."""
    lv = np.clip(light + dither * (0.35 / BANDS), 0.0, 1.3)
    q = np.round(lv * BANDS) / BANDS
    return np.clip(colour * (0.5 + 0.62 * q)[:, None], 0, 1)


KEY = np.array([-0.45, 0.8, -0.4])
KEY = KEY / np.linalg.norm(KEY)


def build(model, out_glb, out_png):
    faces = []  # (box index, face name, local pts, normals, st, quads, (w, h) nodes)
    for bi, box in enumerate(model.boxes):
        for face in FACES:
            pts, nrm, st, quads, wh = _face_mesh(box, face, None, None)
            faces.append((bi, face, pts, nrm, st, quads, wh))
    # Atlas layout: shelf packing of each face's texel rectangle (+1 px padding all round).
    rects = []
    for f in faces:
        w = max(1, int(round(f[6][0] * TEXELS_PER_NODE)))
        h = max(1, int(round(f[6][1] * TEXELS_PER_NODE)))
        rects.append((w, h))
    order = sorted(range(len(faces)), key=lambda i: -rects[i][1])
    size = 128
    while True:
        placed, x, y, shelf = {}, 0, 0, 0
        ok = True
        for i in order:
            w, h = rects[i][0] + 2, rects[i][1] + 2
            if x + w > size:
                x, y, shelf = 0, y + shelf, 0
            if y + h > size:
                ok = False
                break
            placed[i] = (x + 1, y + 1)
            x += w
            shelf = max(shelf, h)
        if ok:
            break
        size *= 2
    img = np.zeros((size, size, 4))
    pos, nor, uvs, jts, wts, idx = [], [], [], [], [], []
    for fi, (bi, face, pts, nrm, st, quads, wh) in enumerate(faces):
        box = model.boxes[bi]
        w, h = rects[fi]
        ox, oy = placed[fi]
        # Paint: the texel centres of this face in 3D (on the flat face; bevel texels stretch, as in voxel art).
        n, ua, va = [np.array(v, float) for v in FACES[face]]
        hn, hu, hv = abs(n @ box.h), abs(ua @ box.h), abs(va @ box.h)
        us = (np.arange(w) + 0.5) / w
        vs = (np.arange(h) + 0.5) / h
        gu, gv = np.meshgrid(us, vs)
        local = (n * hn)[None, :] + ua[None, :] * ((gu.ravel() * 2 - 1) * hu)[:, None] \
            + va[None, :] * ((gv.ravel() * 2 - 1) * hv)[:, None]
        world = local @ box.R.T + box.c
        wn = np.repeat((box.R @ n)[None, :], len(world), axis=0)
        mats = np.array([box.mat] * len(world), dtype=object)
        for decal in model.decals:
            mats[decal.region(world) <= 0] = decal.mat
        colour = np.array([model.palette[m] for m in mats], float)
        ao = model.ao(world + wn * 0.004, wn)
        ndl = np.clip(wn @ KEY, -1, 1)
        light = 0.52 + 0.36 * np.clip(ndl, 0, 1) + 0.12 * wn[:, 1]
        # Top-lit within the face: lighter toward the face's upper edge (v runs down).
        light = light + 0.05 * (0.5 - gv.ravel()) * (1 if abs(wn[0, 1]) < 0.7 else 0)
        # Bevel rim: the outermost texel ring catches light on top edges and darkens on the others.
        ring = (np.minimum(np.minimum(gu, 1 - gu) * w, np.minimum(gv, 1 - gv) * h) < 1.0).ravel()
        top_edge = (gv.ravel() * h < 1.0) & (abs(wn[0, 1]) < 0.7)
        light = light * (0.66 + 0.34 * ao)
        light = np.where(ring & ~top_edge, light * 0.9, light)
        light = np.where(top_edge | ((wn[:, 1] > 0.7) & ring), light * 1.12, light)
        dither = BAYER[(np.arange(h)[:, None] % 4), (np.arange(w)[None, :] % 4)].ravel()
        shaded = _bands(colour, light, dither)
        flat = np.isin(mats, list(model.flat))
        shaded[flat] = np.clip(colour[flat] * (0.85 + 0.25 * np.clip(ndl[flat], 0, 1))[:, None]
                               * (0.75 + 0.25 * ao[flat])[:, None], 0, 1)
        tex = shaded.reshape(h, w, 3)
        img[oy:oy + h, ox:ox + w, :3] = tex
        img[oy:oy + h, ox:ox + w, 3] = 1
        # Padding: repeat the border texels.
        img[oy - 1, ox:ox + w, :3] = tex[0]
        img[oy + h, ox:ox + w, :3] = tex[-1]
        img[oy:oy + h, ox - 1, :3] = tex[:, 0]
        img[oy:oy + h, ox + w, :3] = tex[:, -1]
        img[oy - 1:oy + h + 1, ox - 1, 3] = 1
        img[oy - 1:oy + h + 1, ox + w, 3] = 1
        img[oy - 1, ox:ox + w, 3] = 1
        img[oy + h, ox:ox + w, 3] = 1
        # Mesh.
        base = len(pos)
        bone = model.bone_index[box.bone]
        for p, nn, (s, t) in zip(pts, nrm, st):
            pos.append(p @ box.R.T + box.c)
            nor.append(box.R @ nn)
            uvs.append(((ox + s * w) / size, (oy + t * h) / size))
            jts.append((bone, 0, 0, 0))
            wts.append((1.0, 0.0, 0.0, 0.0))
        for a, b, c, d in quads:
            idx += [base + a, base + b, base + c, base + a, base + c, base + d]
    # Make every triangle counter-clockwise from outside.
    P = np.array(pos)
    tri = np.array(idx).reshape(-1, 3)
    fn = np.cross(P[tri[:, 1]] - P[tri[:, 0]], P[tri[:, 2]] - P[tri[:, 0]])
    nn = np.array(nor)[tri].mean(axis=1)
    flip = (fn * nn).sum(axis=1) < 0
    tri[flip] = tri[flip][:, [0, 2, 1]]
    rig.export_glb(model, P, np.array(nor), uvs, np.array(jts), np.array(wts), tri.ravel().tolist(), out_glb)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGBA").save(out_png, optimize=True)
    return len(tri), size


__all__ = ["Box", "Model", "build", "S"]
