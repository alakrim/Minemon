"""Rig and export for sculpted creatures (M2.1): bones, skin, the six clips and the GLB file.

Every builder (mesh, voxel) ends with export_glb(): it takes a mesh in nodes (model space: y up, front -z) with
per-vertex joints and weights, samples sculpt.pose(clip, u) for the 86 frames of the shared clip layout (stand 0-20,
walk 21-41, run 42-52, punch 53-63, die 64-74, sit 75-85; the same as the converted Cobblemon models, so
minemon_creatures needs nothing new) and writes the GLB with tools/cobblemon_import.py's writer.
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import cobblemon_import as ci  # noqa: E402

PX = 16.0  # the writer works in Bedrock pixels: 16 per node
IDENT = (0.0, 0.0, 0.0, 1.0)


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _px(v):
    return (v[0] * PX, v[1] * PX, v[2] * PX)


def skeleton(sculpt):
    names = [b[0] for b in sculpt.bones]
    index = {n: i for i, n in enumerate(names)}
    parent = [index[b[1]] if b[1] else None for b in sculpt.bones]
    pivots = [tuple(b[2]) for b in sculpt.bones]
    children = [[j for j in range(len(names)) if parent[j] == i] for i in range(len(names))]
    roots = [i for i in range(len(names)) if parent[i] is None]
    return names, parent, pivots, children, roots


def locals_for(sculpt, pose):
    """Node transforms (quat, translation in px) for one pose dict {bone: (quat, offset in nodes)}."""
    names, parent, pivots, _c, _r = skeleton(sculpt)
    out = []
    for i, name in enumerate(names):
        q, off = pose.get(name, (IDENT, (0.0, 0.0, 0.0)))
        base = pivots[i] if parent[i] is None else _sub(pivots[i], pivots[parent[i]])
        out.append((q, _px(_add(base, off))))
    return out


def bake_anim(sculpt):
    frames = []
    for key, first, last in ci.CLIP_RANGES:
        for f in range(first, last + 1):
            u = (f - first) / float(last - first)
            frames.append(locals_for(sculpt, sculpt.pose(key, u) or {}))
    names = skeleton(sculpt)[0]
    tracks = []
    for i in range(len(names)):
        for path, slot in (("translation", 1), ("rotation", 0)):
            values = [fr[i][slot] for fr in frames]
            if path == "rotation":
                values = ci._continuous(path, values)
            if ci._varies(values):
                tracks.append((i, path, values))
    ones = [(1.0, 1.0, 1.0)] * len(names)
    return {"times": [float(f) for f in range(ci.LAST_FRAME + 1)], "tracks": tracks, "rest": (frames[0], ones)}


def export_glb(sculpt, positions, normals, uvs, joints, weights, indices, path):
    """positions/normals (N, 3) in nodes and unit vectors, uvs (N, 2) in 0..1, joints (N, 4) int, weights (N, 4),
    indices (M,) int (counter-clockwise triangles seen from outside). Writes path; returns the anim dict."""
    names, parent, pivots, children, roots = skeleton(sculpt)
    model = {
        "names": names, "children": children, "roots": roots,
        "positions": [_px(tuple(p)) for p in positions],
        "normals": [tuple(float(c) for c in n) for n in normals],
        "uvs": [(float(u), float(v)) for u, v in uvs],
        "joints": [tuple(int(j) for j in js) for js in joints],
        "weights": [tuple(float(w) for w in ws) for ws in weights],
        "indices": [int(i) for i in indices],
        "inverse_bind": [ci.column_major(ci.t_inv((IDENT, _px(pivots[i])))) for i in range(len(names))],
    }
    anim = bake_anim(sculpt)
    with open(path, "wb") as f:
        f.write(ci.write_glb(model, anim))
    return anim


def locators_entity_space(sculpt):
    """The sculpt's locators for minemon_pack (entity space: +z forward, so model z is negated)."""
    return {k: (v[0], v[1], -v[2]) for k, v in sculpt.locators.items()}
