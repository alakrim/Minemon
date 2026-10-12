#!/usr/bin/env python3
"""Offline preview of a creature .glb (M2.1 art pass): the skinned mesh, textured, from four sides.

Why: the in-game check of a model takes a full client run. This renders our own GLB files (the stand-ins of
tools/gen_standins.py and the converted pack of tools/cobblemon_import.py) in a second, so a converter or rig fix
can be checked before the game is started. It is a debugging aid, not a reference renderer: an orthographic
painter's-algorithm rasteriser with nearest texture sampling and simple lambert shading.

It follows the glTF rules the engine uses: node TRS hierarchy, one skin (joints + inverseBindMatrices),
JOINTS_0/WEIGHTS_0 linear blend skinning, and LINEAR animation channels sampled at one time (glTF seconds; our
clips use one second per frame, so --frame 21 samples the walk clip's first frame).

Dev dependency: numpy and Pillow.
Usage: python3 tools/render_glb.py MODEL.glb TEXTURE.png OUT.png [--frame F | --rest] [--size 256]
  --rest      ignore the animation and draw the node rest pose
  --frame F   sample every channel at time F (default 0: the stand clip's first frame)
The output shows front (+z toward the viewer), right side, back and a three-quarter view, with a ground line at y=0.
"""

import argparse
import json
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw

COMPONENT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(path):
    data = open(path, "rb").read()
    magic, _version, _length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF":
        raise ValueError("not a GLB file: " + path)
    off = 12
    gltf, binary = None, b""
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8:off + 8 + clen]
        if ctype == 0x4E4F534A:
            gltf = json.loads(chunk.decode("utf-8"))
        elif ctype == 0x004E4942:
            binary = chunk
        off += 8 + clen
    return gltf, binary


def accessor(gltf, binary, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    dtype = np.dtype(COMPONENT[acc["componentType"]])
    width = WIDTH[acc["type"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", 0)
    count = acc["count"]
    if stride and stride != dtype.itemsize * width:
        rows = [np.frombuffer(binary, dtype, width, start + i * stride) for i in range(count)]
        arr = np.array(rows)
    else:
        arr = np.frombuffer(binary, dtype, count * width, start).reshape(count, width)
    return arr.astype(np.float64) if dtype.kind == "f" else arr.astype(np.int64)


def quat_to_mat(q):
    x, y, z, w = q
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])


def trs(t, r, s):
    m = np.eye(4)
    m[:3, :3] = quat_to_mat(r) * np.array(s)[None, :]
    m[:3, 3] = t
    return m


def node_locals(gltf, binary, time, use_anim):
    nodes = gltf["nodes"]
    local = []
    for n in nodes:
        local.append([list(n.get("translation", [0, 0, 0])), list(n.get("rotation", [0, 0, 0, 1])),
                      list(n.get("scale", [1, 1, 1]))])
    if use_anim and gltf.get("animations"):
        anim = gltf["animations"][0]
        for ch in anim["channels"]:
            smp = anim["samplers"][ch["sampler"]]
            times = accessor(gltf, binary, smp["input"])[:, 0]
            vals = accessor(gltf, binary, smp["output"])
            i = int(np.searchsorted(times, time, side="right") - 1)
            i = max(0, min(i, len(times) - 1))
            if i < len(times) - 1 and times[i + 1] > times[i]:
                k = (time - times[i]) / (times[i + 1] - times[i])
                k = min(max(k, 0.0), 1.0)
                v = vals[i] * (1 - k) + vals[i + 1] * k
            else:
                v = vals[i]
            path = ch["target"]["path"]
            slot = {"translation": 0, "rotation": 1, "scale": 2}[path]
            if path == "rotation":
                v = v / (np.linalg.norm(v) or 1.0)
            local[ch["target"]["node"]][slot] = list(v)
    return [trs(*l) for l in local]


def world_mats(gltf, locals_):
    parent = {}
    for i, n in enumerate(gltf["nodes"]):
        for c in n.get("children", []):
            parent[c] = i
    world = [None] * len(locals_)

    def get(i):
        if world[i] is None:
            world[i] = get(parent[i]) @ locals_[i] if i in parent else locals_[i]
        return world[i]
    for i in range(len(locals_)):
        get(i)
    return world, parent


def skinned_mesh(gltf, binary, time, use_anim):
    locals_ = node_locals(gltf, binary, time, use_anim)
    world, _ = world_mats(gltf, locals_)
    mesh_node = next(i for i, n in enumerate(gltf["nodes"]) if "mesh" in n)
    prim = gltf["meshes"][gltf["nodes"][mesh_node]["mesh"]]["primitives"][0]
    attrs = prim["attributes"]
    pos = accessor(gltf, binary, attrs["POSITION"])
    uv = accessor(gltf, binary, attrs["TEXCOORD_0"])
    idx = accessor(gltf, binary, prim["indices"])[:, 0].reshape(-1, 3)
    if "skin" in gltf["nodes"][mesh_node] and "JOINTS_0" in attrs:
        skin = gltf["skins"][gltf["nodes"][mesh_node]["skin"]]
        ibm = accessor(gltf, binary, skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
        joints = accessor(gltf, binary, attrs["JOINTS_0"])
        weights = accessor(gltf, binary, attrs["WEIGHTS_0"])
        if weights.max() > 1.5:  # normalised integers
            weights = weights / 255.0
        jm = np.array([world[j] @ ibm[k] for k, j in enumerate(skin["joints"])])
        hom = np.concatenate([pos, np.ones((len(pos), 1))], axis=1)
        out = np.zeros_like(hom)
        for c in range(4):
            out += weights[:, c:c + 1] * np.einsum("nij,nj->ni", jm[joints[:, c]], hom)
        pos = out[:, :3]
    else:
        hom = np.concatenate([pos, np.ones((len(pos), 1))], axis=1)
        pos = (world[mesh_node] @ hom.T).T[:, :3]
    return pos, uv, idx


def render_view(pos, uv, idx, tex, yaw_deg, size, scale, centre):
    a = np.radians(yaw_deg)
    rot = np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])
    p = (pos - centre) @ rot.T
    img = Image.new("RGBA", (size, size), (40, 44, 52, 255))
    draw = ImageDraw.Draw(img)
    ground = size * 0.85 + centre[1] * scale
    draw.line([(0, ground), (size, ground)], fill=(90, 140, 90, 255), width=1)
    tw, th = tex.size
    tpx = tex.load()
    tris = p[idx]
    depth = tris[:, :, 2].mean(axis=1)
    light = np.array([0.4, 0.8, 0.45])
    light /= np.linalg.norm(light)
    for t in np.argsort(depth):  # far (low z) first: the viewer looks along -z
        v = tris[t]
        n = np.cross(v[1] - v[0], v[2] - v[0])
        ln = np.linalg.norm(n)
        if ln < 1e-12 or n[2] <= 0:
            continue
        shade = 0.55 + 0.45 * max(0.0, float(np.dot(n / ln, light)))
        cu = uv[idx[t]].mean(axis=0)
        px = tpx[min(tw - 1, max(0, int(cu[0] * tw))), min(th - 1, max(0, int(cu[1] * th)))]
        if len(px) == 4 and px[3] < 8:
            continue
        col = tuple(int(c * shade) for c in px[:3]) + (255,)
        pts = [(size / 2 + q[0] * scale, size * 0.85 - q[1] * scale) for q in v]
        draw.polygon(pts, fill=col)
    return img


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("model")
    ap.add_argument("texture")
    ap.add_argument("out")
    ap.add_argument("--frame", type=float, default=0.0)
    ap.add_argument("--rest", action="store_true")
    ap.add_argument("--size", type=int, default=256)
    args = ap.parse_args(argv)
    gltf, binary = load_glb(args.model)
    pos, uv, idx = skinned_mesh(gltf, binary, args.frame, not args.rest)
    tex = Image.open(args.texture).convert("RGBA")
    lo, hi = pos.min(axis=0), pos.max(axis=0)
    extent = max(hi - lo) or 1.0
    scale = args.size * 0.7 / extent
    centre = np.array([(lo[0] + hi[0]) / 2, 0.0, (lo[2] + hi[2]) / 2])
    views = [render_view(pos, uv, idx, tex, yaw, args.size, scale, centre) for yaw in (0, 90, 180, 45)]
    sheet = Image.new("RGBA", (args.size * 4, args.size), (0, 0, 0, 255))
    for i, v in enumerate(views):
        sheet.paste(v, (i * args.size, 0))
    sheet.save(args.out)
    print("bounds min %s max %s (glTF units; 10 = 1 node)" % (np.round(lo, 2), np.round(hi, 2)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
