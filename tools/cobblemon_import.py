#!/usr/bin/env python3
"""Cobblemon Bedrock models to Luanti glTF (T-25a; owner directive D-029).

Reads a clone of kirbycope/cobblemon-bedrock (pinned in scripts/versions.env) and writes a generated pack mod.
The output is never committed: it goes to .tools/pack_cobblemon, which is git-ignored.

  <out>/minemon_pack_cobblemon/mod.conf
  <out>/minemon_pack_cobblemon/init.lua         minemon_pack.models[dex] = {mesh, texture, texture_shiny, height, width}
  <out>/minemon_pack_cobblemon/CREDITS.txt
  <out>/minemon_pack_cobblemon/models/mmp_NNNN.glb       rest pose, one skinned mesh, one joint per Bedrock bone
  <out>/minemon_pack_cobblemon/textures/mmp_NNNN.png     the Bedrock texture, copied
  <out>/minemon_pack_cobblemon/textures/mmp_NNNN_s.png   the shiny texture (the base texture when none ships)

Rules:
  - 16 px = 1 block = 1 node = 10 glTF units (as tools/gen_standins.py).
  - The lowest point of each model (its feet) sits at y = 0, found per model; the Bedrock ground plane is not used.
    The front faces the same way as the stand-ins of tools/gen_standins.py: the Bedrock front (-z) becomes
    glTF +z (a 180-degree turn about x; see FLIP_ROT).
  - Bones keep their names. A bone's rest pose is its pivot and rotation (degrees, Java/Bedrock order Rz*Ry*Rx).
  - Cube rotation, inflate, mirror and both UV forms (box and per face) are applied; the UV is normalised by the
    geometry's texture_width and texture_height.
  - Rest pose only. Animation comes in T-25b.

Stdlib only. The GLB writer and the struct helpers come from tools/gen_standins.py.

Usage: python3 tools/cobblemon_import.py --src .tools/cobblemon-bedrock --out .tools/pack_cobblemon [--only 19,25]
Exit: 0 when the run converts what it was asked to (and at least 240 species in a full run), 1 otherwise.
"""

import argparse
import json
import math
import os
import re
import shutil
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import gen_standins as gs  # noqa: E402  (the stdlib GLB writer; see module docstring)

PACK_NAME = "minemon_pack_cobblemon"
SOURCE_SUBDIR = os.path.join("development_resource_packs", "cobblemon")
DEX_MAX = 251
FULL_RUN_MIN = 240
PX_PER_BLOCK = 16.0
SCALE = gs.UNITS / PX_PER_BLOCK  # glTF units per pixel

# A rigid transform is a pair (quat, translation in pixels): p -> rot(quat, p) + translation.
# Quaternions are (x, y, z, w).
IDENTITY_Q = (0.0, 0.0, 0.0, 1.0)
IDENTITY = (IDENTITY_Q, (0.0, 0.0, 0.0))
# Model space to glTF space is a 180-degree turn about x (y and z negated) followed by a lift: the lowest point of
# the model goes to y = 0 (see build_model). The lift is the translation part of the root transform. The Bedrock front (-z) becomes glTF +z, the front of gen_standins.py;
# Luanti shows that as facing -z (checked on Rattata and Gastly: the face toward a camera at -z when yaw is 0).
FLIP_ROT = (1.0, 0.0, 0.0, 0.0)


# ---------------------------------------------------------------- quaternions and rigid transforms

def q_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
            aw * bw - ax * bx - ay * by - az * bz)


def q_conj(q):
    return (-q[0], -q[1], -q[2], q[3])


def q_rot(q, v):
    """Rotates vector v by unit quaternion q."""
    r = q_mul(q_mul(q, (v[0], v[1], v[2], 0.0)), q_conj(q))
    return (r[0], r[1], r[2])


def q_axis(axis, degrees):
    half = math.radians(degrees) / 2.0
    s = math.sin(half)
    return (axis[0] * s, axis[1] * s, axis[2] * s, math.cos(half))


def q_euler(rot):
    """Bedrock bone or cube rotation in degrees [x, y, z]: R = Rz * Ry * Rx, so x is applied first."""
    rx, ry, rz = rot
    return q_mul(q_axis((0.0, 0.0, 1.0), rz), q_mul(q_axis((0.0, 1.0, 0.0), ry), q_axis((1.0, 0.0, 0.0), rx)))


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def neg(a):
    return (-a[0], -a[1], -a[2])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def t_mul(a, b):
    """a after b: p -> a(b(p))."""
    return (q_mul(a[0], b[0]), add(q_rot(a[0], b[1]), a[1]))


def t_inv(a):
    q = q_conj(a[0])
    return (q, neg(q_rot(q, a[1])))


def t_apply(a, p):
    return add(q_rot(a[0], p), a[1])


def pivot_rot(q, pivot):
    """Rotation q about the point pivot."""
    return (q, sub(pivot, q_rot(q, pivot)))


def quat_to_matrix(q):
    x, y, z, w = q
    return [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]


def column_major(xf):
    """glTF mat4 (16 floats, column-major) of a rigid transform in pixels, with the translation in glTF units."""
    m = quat_to_matrix(xf[0])
    t = [c * SCALE for c in xf[1]]
    cols = []
    for j in range(3):
        cols += [m[0][j], m[1][j], m[2][j], 0.0]
    cols += [t[0], t[1], t[2], 1.0]
    return cols


# ---------------------------------------------------------------- box geometry and UV

# Outward normal and image-up direction of each face, in Bedrock space. Bedrock y runs down, so up is -y.
# north is the front (-z). The image-right direction of a face is cross(image-up, view direction).
FACE_NORMAL = {"north": (0, 0, -1), "south": (0, 0, 1), "east": (1, 0, 0), "west": (-1, 0, 0),
               "up": (0, -1, 0), "down": (0, 1, 0)}
FACE_UP = {"north": (0, -1, 0), "south": (0, -1, 0), "east": (0, -1, 0), "west": (0, -1, 0),
           "up": (0, 0, 1), "down": (0, 0, -1)}
FACES = ("north", "south", "east", "west", "up", "down")


def box_uv_rects(u, v, w, h, d):
    """Minecraft box unwrap: each face's texel rectangle (u0, v0, u1, v1), with u0 < u1 and v0 < v1."""
    return {
        "east": (u, v + d, u + d, v + d + h),
        "north": (u + d, v + d, u + d + w, v + d + h),
        "west": (u + d + w, v + d, u + 2 * d + w, v + d + h),
        "south": (u + 2 * d + w, v + d, u + 2 * d + 2 * w, v + d + h),
        "up": (u + d, v, u + d + w, v + d),
        "down": (u + d + w, v, u + d + 2 * w, v + d),
    }


def _axis_of(vec):
    for i, c in enumerate(vec):
        if c:
            return i, (1 if c > 0 else -1)
    raise ValueError("zero vector")


def face_corners(lo, hi, face):
    """The four corners of a box face as (bottom-left, bottom-right, top-right, top-left), seen from outside."""
    normal = FACE_NORMAL[face]
    up = FACE_UP[face]
    right = cross(up, neg(normal))
    plane_axis, plane_sign = _axis_of(normal)
    r_axis, r_sign = _axis_of(right)
    u_axis, u_sign = _axis_of(up)
    plane = hi[plane_axis] if plane_sign > 0 else lo[plane_axis]

    def pick(axis, sign, side):
        # side -1: the minimum along sign * e_axis; side +1: the maximum.
        want_hi = (side > 0) == (sign > 0)
        return hi[axis] if want_hi else lo[axis]

    corners = []
    for side_r, side_u in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        p = [0.0, 0.0, 0.0]
        p[plane_axis] = plane
        p[r_axis] = pick(r_axis, r_sign, side_r)
        p[u_axis] = pick(u_axis, u_sign, side_u)
        corners.append(tuple(p))
    return corners, normal


def face_uv_corners(rect, mirror):
    """Texel (u, v) for BL, BR, TR, TL. A mirror swaps u0 and u1, which flips the texture horizontally."""
    u0, v0, u1, v1 = rect
    if mirror:
        u0, u1 = u1, u0
    return [(u0, v1), (u1, v1), (u1, v0), (u0, v0)]


def cube_faces(cube, bone_mirror):
    """Yields (face, rect, mirror) for the faces a cube draws, from its UV form (box or per face)."""
    uv = cube.get("uv")
    mirror = bool(cube.get("mirror", bone_mirror))
    if isinstance(uv, list):
        u, v = float(uv[0]), float(uv[1])
        size = cube["size"]
        w, h, d = (abs(float(size[0])), abs(float(size[1])), abs(float(size[2])))
        rects = box_uv_rects(u, v, w, h, d)
        for face in FACES:
            yield face, rects[face], mirror
    elif isinstance(uv, dict):
        for face in FACES:
            entry = uv.get(face)
            if not entry or "uv" not in entry:
                continue
            fu, fv = float(entry["uv"][0]), float(entry["uv"][1])
            su, sv = float(entry.get("uv_size", [0, 0])[0]), float(entry.get("uv_size", [0, 0])[1])
            yield face, (fu, fv, fu + su, fv + sv), mirror
    else:
        raise ValueError("cube without uv")


def cube_bounds(cube):
    origin = [float(x) for x in cube["origin"]]
    size = [float(x) for x in cube["size"]]
    inflate = float(cube.get("inflate", 0.0))
    lo = tuple(min(origin[i], origin[i] + size[i]) - inflate for i in range(3))
    hi = tuple(max(origin[i], origin[i] + size[i]) + inflate for i in range(3))
    return lo, hi


# ---------------------------------------------------------------- geometry to a skinned model

def _vec(value, default=(0.0, 0.0, 0.0)):
    if value is None:
        return tuple(default)
    return (float(value[0]), float(value[1]), float(value[2]))


def bone_order(parent):
    """Indices with every parent before its children. Raises on a cycle."""
    n = len(parent)
    done = [False] * n
    order = []
    while len(order) < n:
        progressed = False
        for i in range(n):
            if not done[i] and (parent[i] is None or done[parent[i]]):
                done[i] = True
                order.append(i)
                progressed = True
        if not progressed:
            raise ValueError("bone parent cycle")
    return order


def build_model(geometry):
    """The rest-pose model of one Bedrock geometry, with its lowest point at y = 0 (the feet).

    The lowest point is found with a first pass; the Bedrock ground plane (y = 24) is not used, because some
    Cobblemon models (Cyndaquil) stand with their feet well above it."""
    first = _build_model(geometry, (0.0, 0.0, 0.0))
    lowest = min(p[1] for p in first["positions"])
    return _build_model(geometry, (0.0, -lowest, 0.0))


def _build_model(geometry, lift):
    flip = (FLIP_ROT, lift)
    desc = geometry["description"]
    tex_w = float(desc.get("texture_width") or 16)
    tex_h = float(desc.get("texture_height") or 16)
    bones = geometry.get("bones", [])
    if not bones:
        raise ValueError("geometry has no bones")
    names = [b["name"] for b in bones]
    index = {}
    for i, name in enumerate(names):
        if name in index:
            raise ValueError("duplicate bone %s" % name)
        index[name] = i
    parent = [index.get(b.get("parent")) if b.get("parent") is not None else None for b in bones]
    order = bone_order(parent)
    n = len(bones)
    pivots = [_vec(b.get("pivot")) for b in bones]
    rots = [q_euler(_vec(b.get("rotation"))) for b in bones]

    local = [None] * n  # glTF node transform (pixels), relative to its parent node; top bones include flip
    glob = [None] * n  # the joint's global transform in glTF space at rest (flip included)
    fk = [None] * n  # the rest forward kinematics of the bone in model space (rotations about pivots)
    for i in order:
        p = parent[i]
        if p is None:
            link = (rots[i], pivots[i])
            local[i] = t_mul(flip, link)
            glob[i] = local[i]
            fk[i] = pivot_rot(rots[i], pivots[i])
        else:
            link = (rots[i], sub(pivots[i], pivots[p]))
            local[i] = link
            glob[i] = t_mul(glob[p], link)
            fk[i] = t_mul(fk[p], pivot_rot(rots[i], pivots[i]))

    positions, normals, uvs, joints, weights, indices = [], [], [], [], [], []
    lo_pt = [float("inf")] * 3
    hi_pt = [float("-inf")] * 3
    for i, bone in enumerate(bones):
        bone_mirror = bool(bone.get("mirror", False))
        for cube in bone.get("cubes", []):
            if "rotation" in cube:
                cube_t = pivot_rot(q_euler(_vec(cube["rotation"])), _vec(cube.get("pivot"), pivots[i]))
            else:
                cube_t = IDENTITY
            full = t_mul(flip, t_mul(fk[i], cube_t))
            normal_q = q_mul(flip[0], q_mul(fk[i][0], cube_t[0]))
            lo, hi = cube_bounds(cube)
            for face, rect, mirror in cube_faces(cube, bone_mirror):
                corners, normal = face_corners(lo, hi, face)
                uv = face_uv_corners(rect, mirror)
                base = len(positions)
                for corner, (tu, tv) in zip(corners, uv):
                    p = t_apply(full, corner)
                    for k in range(3):
                        lo_pt[k] = min(lo_pt[k], p[k])
                        hi_pt[k] = max(hi_pt[k], p[k])
                    positions.append(p)
                    normals.append(q_rot(normal_q, normal))
                    uvs.append((tu / tex_w, tv / tex_h))
                    joints.append((i, 0, 0, 0))
                    weights.append((1.0, 0.0, 0.0, 0.0))
                indices += [base, base + 1, base + 2, base, base + 2, base + 3]
    if not positions:
        raise ValueError("geometry has no cubes")

    inverse_bind = [column_major(t_inv(glob[i])) for i in range(n)]
    children = [[j for j in range(n) if parent[j] == i] for i in range(n)]
    roots = [i for i in range(n) if parent[i] is None]
    return {
        "names": names, "children": children, "roots": roots, "local": local,
        "positions": positions, "normals": normals, "uvs": uvs, "joints": joints, "weights": weights,
        "indices": indices, "inverse_bind": inverse_bind,
        "bounds_px": (tuple(lo_pt), tuple(hi_pt)),
    }


def write_glb(model):
    """Packs the model into GLB bytes with the stdlib writer from tools/gen_standins.py."""
    binb = gs.BinBuilder()
    positions = [tuple(v * SCALE for v in p) for p in model["positions"]]
    n = len(positions)
    pmin = [min(p[k] for p in positions) for k in range(3)]
    pmax = [max(p[k] for p in positions) for k in range(3)]
    acc_pos = binb.add(gs.pack_floats(positions), n, "VEC3", gs.FLOAT, (pmin, pmax))
    acc_nrm = binb.add(gs.pack_floats(model["normals"]), n, "VEC3", gs.FLOAT)
    acc_uv = binb.add(gs.pack_floats(model["uvs"]), n, "VEC2", gs.FLOAT)
    acc_jnt = binb.add(gs.pack_ushorts(model["joints"]), n, "VEC4", gs.USHORT)
    acc_wgt = binb.add(gs.pack_floats(model["weights"]), n, "VEC4", gs.FLOAT)
    if n < 65536:
        idx_raw = struct.pack("<%dH" % len(model["indices"]), *model["indices"])
        idx_type = gs.USHORT
    else:
        idx_raw = struct.pack("<%dI" % len(model["indices"]), *model["indices"])
        idx_type = 5125  # UNSIGNED_INT
    acc_idx = binb.add(idx_raw, len(model["indices"]), "SCALAR", idx_type)
    nb = len(model["names"])
    acc_ibm = binb.add(gs.pack_floats(model["inverse_bind"]), nb, "MAT4", gs.FLOAT)

    nodes = []
    for i, name in enumerate(model["names"]):
        xf = model["local"][i]
        node = {"name": name, "translation": [c * SCALE for c in xf[1]], "rotation": list(xf[0])}
        if model["children"][i]:
            node["children"] = model["children"][i]
        nodes.append(node)
    mesh_node = len(nodes)
    nodes.append({"name": "mesh", "mesh": 0, "skin": 0})
    gltf = {
        "asset": {"version": "2.0", "generator": "minemon tools/cobblemon_import.py (T-25a)"},
        "scene": 0,
        "scenes": [{"nodes": model["roots"] + [mesh_node]}],
        "nodes": nodes,
        "meshes": [{"primitives": [{"attributes": {"POSITION": acc_pos, "NORMAL": acc_nrm, "TEXCOORD_0": acc_uv,
                                                   "JOINTS_0": acc_jnt, "WEIGHTS_0": acc_wgt},
                                    "indices": acc_idx}]}],
        "skins": [{"name": "skeleton", "joints": list(range(nb)), "skeleton": model["roots"][0],
                   "inverseBindMatrices": acc_ibm}],
        "accessors": binb.accessors,
        "bufferViews": binb.views,
        "buffers": [{"byteLength": len(binb.data)}],
    }
    json_bytes = json.dumps(gltf, separators=(",", ":"), sort_keys=True).encode("utf-8")
    json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
    bin_bytes = bytes(binb.data) + b"\x00" * ((4 - len(binb.data) % 4) % 4)
    total = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
    out = struct.pack("<III", 0x46546C67, 2, total)
    out += struct.pack("<II", len(json_bytes), 0x4E4F534A) + json_bytes
    out += struct.pack("<II", len(bin_bytes), 0x004E4942) + bin_bytes
    return out


# ---------------------------------------------------------------- the Cobblemon source tree

def discover(src):
    """Maps national dex number to (folder name, species name) for the entity model folders."""
    base = os.path.join(src, SOURCE_SUBDIR)
    entity_dir = os.path.join(base, "models", "entity")
    if not os.path.isdir(entity_dir):
        raise SystemExit("FAIL: %s not found (run scripts/setup.sh)" % entity_dir)
    found = {}
    for entry in sorted(os.listdir(entity_dir)):
        match = re.match(r"^(\d{4})_(.+)$", entry)
        if match and os.path.isdir(os.path.join(entity_dir, entry)):
            dex = int(match.group(1))
            found.setdefault(dex, (entry, match.group(2)))
    return base, found


def choose_geometry(path):
    """The model's main geometry: the first one that is not the held-item companion (.held)."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    for geometry in data.get("minecraft:geometry", []):
        if not geometry["description"]["identifier"].endswith(".held"):
            return geometry
    raise ValueError("no main geometry in %s" % os.path.basename(path))


def _form_key(stem):
    """'mr_mime' and 'mrmime' give the same key, and a male or female suffix is dropped."""
    stem = stem.lower()
    for suffix in ("_male", "_female"):
        if stem.endswith(suffix):
            stem = stem[:-len(suffix)]
    return stem.replace("_", "")


def find_geo_stem(models_dir, name):
    """The stem of the species' base model. Order: <name>, <name>_male, the same name without underscores
    (the folder 0122_mrmime holds mr_mime.geo.json), then the first form named <name>_... (Unown's a form)."""
    stems = sorted(f[:-len(".geo.json")] for f in os.listdir(models_dir) if f.endswith(".geo.json"))
    for stem in (name, name + "_male"):
        if stem in stems:
            return stem
    for stem in stems:
        if _form_key(stem) == name.replace("_", ""):
            return stem
    for stem in stems:
        if stem.startswith(name + "_"):
            return stem
    return None


def convert_species(base, dex, folder_name, name):
    """Returns (model dict, base texture path, shiny texture path or None), or raises ValueError with the reason."""
    models_dir = os.path.join(base, "models", "entity", folder_name)
    tex_dir = os.path.join(base, "textures", "entity", folder_name)
    geo_stem = find_geo_stem(models_dir, name)
    if geo_stem is None:
        raise ValueError("no base geo model in %s" % folder_name)
    geometry = choose_geometry(os.path.join(models_dir, geo_stem + ".geo.json"))
    tex_stem = None
    for stem in (geo_stem, name, name + "_male"):
        if os.path.isfile(os.path.join(tex_dir, stem + ".png")):
            tex_stem = stem
            break
    if tex_stem is None:
        raise ValueError("no texture for %s in %s" % (geo_stem, folder_name))
    base_png = os.path.join(tex_dir, tex_stem + ".png")
    shiny_png = os.path.join(tex_dir, tex_stem + "_shiny.png")
    if not os.path.isfile(shiny_png):
        shiny_png = None
    model = build_model(geometry)
    return model, base_png, shiny_png


def lua_number(value):
    return "%.3f" % value


def write_pack(out_dir, converted, commit):
    pack = os.path.join(out_dir, PACK_NAME)
    if os.path.isdir(pack):
        shutil.rmtree(pack)
    os.makedirs(os.path.join(pack, "models"))
    os.makedirs(os.path.join(pack, "textures"))
    with open(os.path.join(pack, "mod.conf"), "w", encoding="utf-8") as f:
        f.write("name = %s\n" % PACK_NAME)
        f.write("description = Cobblemon creature models converted by tools/cobblemon_import.py "
                "(generated; not committed; see CREDITS.txt).\n")
    lines = [
        "-- Generated by tools/cobblemon_import.py (T-25a). Do not edit: run scripts/setup.sh to regenerate.",
        "-- Assets from kirbycope/cobblemon-bedrock (commit %s). Credits and licence: CREDITS.txt." % commit,
        "minemon_pack = rawget(_G, \"minemon_pack\") or {}",
        "minemon_pack.models = {",
    ]
    for dex, name, model, shiny in converted:
        lines.append("\t[%d] = {mesh = \"mmp_%04d.glb\", texture = \"mmp_%04d.png\", texture_shiny = \"mmp_%04d_s.png\", "
                     "height = %s, width = %s}," % (dex, dex, dex, dex, lua_number(model["height"]),
                                                    lua_number(model["width"])))
    lines.append("}")
    with open(os.path.join(pack, "init.lua"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    credits = [
        "Minemon pack: Cobblemon creature models (generated at build time; never committed to the repository).",
        "",
        "Source: https://github.com/kirbycope/cobblemon-bedrock at commit %s." % commit,
        "The code of that repository is MIT. Each model folder carries its own licence file (Creative Commons,",
        "non-commercial, attribution). Cobblemon, the upstream project, is MPL-2.0 for its code; its asset licence",
        "is not stated at the root of its repository.",
        "",
        "Modified: format conversion to Luanti glTF (.glb, rest pose, one skinned mesh per species) and copies of",
        "the Bedrock PNG textures, by tools/cobblemon_import.py. The shiny texture is the base texture where the",
        "source ships no shiny one.",
        "",
        "Private, non-commercial use only. Never publish a build that contains this pack (D-029).",
        "",
    ]
    with open(os.path.join(pack, "CREDITS.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(credits))
    for dex, _name, model, shiny in converted:
        with open(os.path.join(pack, "models", "mmp_%04d.glb" % dex), "wb") as f:
            f.write(write_glb(model))
        shutil.copyfile(model["base_png"], os.path.join(pack, "textures", "mmp_%04d.png" % dex))
        shiny_src = shiny if shiny else model["base_png"]
        shutil.copyfile(shiny_src, os.path.join(pack, "textures", "mmp_%04d_s.png" % dex))
    return pack


def main(argv=None):
    parser = argparse.ArgumentParser(description="Convert Cobblemon Bedrock models to a Luanti pack (T-25a).")
    parser.add_argument("--src", required=True, help="the cobblemon-bedrock clone")
    parser.add_argument("--out", required=True, help="output directory; the pack mod is written inside it")
    parser.add_argument("--only", default="", help="comma-separated dex numbers to convert (default: all 1-251)")
    parser.add_argument("--commit", default="unknown", help="the pinned source commit, written into the pack")
    args = parser.parse_args(argv)

    base, found = discover(args.src)
    if args.only:
        wanted = [int(x) for x in args.only.split(",") if x.strip()]
    else:
        wanted = list(range(1, DEX_MAX + 1))
    converted, failed = [], []
    shiny_fallbacks = 0
    for dex in wanted:
        if dex not in found:
            failed.append((dex, "no entity folder"))
            continue
        folder_name, name = found[dex]
        try:
            model, base_png, shiny_png = convert_species(base, dex, folder_name, name)
        except (ValueError, KeyError, IndexError, OSError) as e:
            failed.append((dex, str(e)))
            continue
        (lo, hi) = model["bounds_px"]
        model["height"] = (hi[1] - lo[1]) / PX_PER_BLOCK
        model["width"] = max(hi[0] - lo[0], hi[2] - lo[2]) / PX_PER_BLOCK
        model["base_png"] = base_png
        if shiny_png is None:
            shiny_fallbacks += 1
        converted.append((dex, name, model, shiny_png))
    os.makedirs(args.out, exist_ok=True)
    pack = write_pack(args.out, converted, args.commit)
    print("cobblemon_import: converted %d of %d species into %s" % (len(converted), len(wanted), pack))
    print("cobblemon_import: shiny textures falling back to base: %d" % shiny_fallbacks)
    for dex, reason in failed:
        print("cobblemon_import: FAIL dex %d: %s" % (dex, reason))
    if not args.only and len(converted) < FULL_RUN_MIN:
        print("cobblemon_import: FAIL only %d species converted (need %d)" % (len(converted), FULL_RUN_MIN))
        return 1
    if args.only and failed:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
