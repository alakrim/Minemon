"""Cobblemon box models to micro-voxel creatures (M2.1, the owner-chosen style; D-032).

Every species gets the look of the hand-made reference (tools/sculpt/charmander.py through build_voxel.py) from
Cobblemon's geometry, skin, skeleton and baked clips:
  * CobbleSculpt makes a posed Cobblemon model look like a sculpt: sdf() is the union of its cubes (thin planes
    such as flames and fins get at least one voxel of thickness, and their transparent texels are holes), colour()
    reads the skin at the surface point through the cube's face UVs (from a 4x EPX-smoothed copy of the skin, so
    diagonals do not stair-step), and bone_weights() gives each point its cube's bone.
  * Eyes are repainted (the owner asked for great faces): the front face of every cube on an eye bone becomes an
    anime eye: a dark oval pupil from the skin's darkest eye colour, an iris from its most saturated one, and two
    catch lights, painted at face-detail resolution by build_voxel.
  * The voxel size is the model height / VOXELS_TALL, so every creature has the same voxel density whatever its
    size, and the triangle budget stays near the reference's.
The GLB keeps Cobblemon's skeleton and clips (cobblemon_import.write_glb), so locators, blink and every animation
still work. The pack entry's scale comes from fx_logic.visual_height (mirrored in visual_height below).
"""

import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import cobblemon_import as ci  # noqa: E402
import creature_look as cl  # noqa: E402

from . import build_voxel as BV  # noqa: E402

PX = 16.0
VOXELS_TALL = 36
HEIGHT_CAP = 3.2
EYE_EXCLUDE = ("lid", "brow", "locator", "lash")


def visual_height(height_m):
    """The same rule as mods/minemon/minemon_fx/fx_logic.lua visual_height (keep both in step)."""
    return min(0.95 * (max(height_m or 0.5, 0.05) ** 0.75) + 0.25, HEIGHT_CAP)


def _quat_matrix(q):
    return np.array(ci.quat_to_matrix(q), float)


def _lum(c):
    return c @ np.array([0.299, 0.587, 0.114])


class CobbleSculpt:
    def __init__(self, model, png_path, voxel_px, hidden=()):
        self.model = model
        hidden = set(hidden)
        tex_w, tex_h, _pad = model["tex_size"]
        img = np.asarray(Image.open(png_path).convert("RGBA")).astype(float) / 255.0
        self.tex = cl._upscale(img, tex_w, tex_h, "epx")  # SCALE texels per skin texel
        self.ts = cl.SCALE
        self.raw = img
        self.res = img.shape[1] / tex_w
        self.names = model["names"]
        self.cubes = []
        min_half = voxel_px * 0.55
        for c in model["all_cubes"]:
            name = c["name"]
            if "lid" in name or c["bone"] in hidden:
                continue  # eyelids live inside the head; hidden bones (vine whips...) are scaled to 0 at rest
            lo, hi = np.array(c["lo"], float), np.array(c["hi"], float)
            centre = (lo + hi) / 2
            half = np.maximum((hi - lo) / 2, min_half)
            thin = bool(np.min(hi - lo) < 0.75)
            R = _quat_matrix(c["full"][0])
            t = np.array(c["full"][1], float)
            faces = {f: (rect, mirror) for f, rect, mirror in c["faces"]}
            if self._invisible(c["faces"]):
                continue  # helper geometry drawn fully transparent (shadows, hidden variants)
            is_eye = "eye" in name and not any(x in name for x in EYE_EXCLUDE)
            self.cubes.append({"bone": c["bone"], "name": name, "lo": lo, "hi": hi, "c": centre, "h": half,
                               "R": R, "t": t, "faces": faces, "thin": thin, "eye": is_eye})
        self.eye_colours = {}
        for i, c in enumerate(self.cubes):
            if c["eye"]:
                self.eye_colours[i] = self._eye_palette(c)
        self.face_mats = {"eye", "iris", "iris_light", "eye_white"}

    def _invisible(self, faces):
        total, seen = 0.0, 0
        for _f, rect, _m in faces:
            u0, v0, u1, v1 = rect
            xa, xb = sorted((int(u0 * self.res), int(u1 * self.res)))
            ya, yb = sorted((int(v0 * self.res), int(v1 * self.res)))
            region = self.raw[ya:max(yb, ya + 1), xa:max(xb, xa + 1), 3]
            if region.size:
                total += float(region.mean())
                seen += 1
        return seen > 0 and total / seen < 0.05

    # ------------------------------------------------------------ geometry

    def _local(self, p_px, c):
        return (p_px - c["t"]) @ c["R"]

    def _box(self, p_px, c):
        q = np.abs(self._local(p_px, c) - c["c"]) - c["h"]
        return np.sqrt((np.maximum(q, 0) ** 2).sum(axis=1)) + np.minimum(q.max(axis=1), 0)

    def _dists(self, p):
        p_px = p * PX
        return np.stack([self._box(p_px, c) for c in self.cubes], axis=1) / PX

    def sdf(self, p):
        d = self._dists(p)
        out = d.min(axis=1)
        # Thin planes are holes where their skin is transparent.
        idx = d.argmin(axis=1)
        for i, c in enumerate(self.cubes):
            if c["thin"]:
                m = (idx == i) & (out <= 0.03)
                if np.any(m):
                    _rgb, a = self._sample(p[m] * PX, c)
                    clear = a < 0.5
                    sub = np.where(m)[0][clear]
                    out[sub] = 0.05
        return out

    def normal(self, p, eps=0.004):
        e = np.eye(3) * eps
        n = np.stack([self._dists(p + e[i]).min(axis=1) - self._dists(p - e[i]).min(axis=1) for i in range(3)],
                     axis=1)
        return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)

    def ambient_occlusion(self, p, n, step=None, count=5):
        step = step or self.voxel_nodes * 0.8
        occ = np.zeros(len(p))
        for i in range(1, count + 1):
            h = step * i
            occ += (h - self._dists(p + n * h).min(axis=1)) / (2.0 ** i)
        return np.clip(1.0 - 2.6 * occ / step, 0.0, 1.0)

    def bone_weights(self, p):
        idx = self._dists(p).argmin(axis=1)
        bones = np.array([c["bone"] for c in self.cubes])[idx]
        joints = np.zeros((len(p), 4), int)
        joints[:, 0] = bones
        weights = np.zeros((len(p), 4))
        weights[:, 0] = 1
        return joints, weights

    # ------------------------------------------------------------ skin

    def _face_of(self, local, c):
        """The face a cube-space point is nearest to, with its (s, t) on that face."""
        dl = local - c["lo"]
        dh = c["hi"] - local
        cand = np.stack([dl[:, 0], dh[:, 0], dl[:, 1], dh[:, 1], dl[:, 2], dh[:, 2]], axis=1)
        names = np.array(["east", "west", "down", "up", "north", "south"])
        return names[np.argmin(np.abs(cand), axis=1)]

    def _sample(self, p_px, c):
        local = self._local(p_px, c)
        local = np.clip(local, c["lo"], c["hi"])
        faces = self._face_of(local, c)
        rgb = np.zeros((len(p_px), 3))
        alpha = np.ones(len(p_px))
        st = np.zeros((len(p_px), 2))
        for face in np.unique(faces):
            m = faces == face
            entry = c["faces"].get(face)
            if entry is None:
                entry = next(iter(c["faces"].values()), None)
                if entry is None:
                    continue
            rect, mirror = entry
            corners, _n = ci.face_corners(tuple(c["lo"]), tuple(c["hi"]), face)
            bl, br, _tr, tl = [np.array(v) for v in corners]
            ex, ey = br - bl, tl - bl
            s = np.clip(((local[m] - bl) @ ex) / max(ex @ ex, 1e-9), 0, 1)
            t = np.clip(((local[m] - bl) @ ey) / max(ey @ ey, 1e-9), 0, 1)
            st[m] = np.stack([s, t], axis=1)
            uv = np.array(ci.face_uv_corners(rect, mirror), float)
            bottom = uv[0] + (uv[1] - uv[0]) * s[:, None]
            top = uv[3] + (uv[2] - uv[3]) * s[:, None]
            tex_uv = bottom + (top - bottom) * t[:, None]
            x = np.clip((tex_uv[:, 0] * self.ts).astype(int), 0, self.tex.shape[1] - 1)
            y = np.clip((tex_uv[:, 1] * self.ts).astype(int), 0, self.tex.shape[0] - 1)
            texel = self.tex[y, x]
            rgb[m] = texel[:, :3]
            alpha[m] = texel[:, 3]
        self._last_faces, self._last_st = faces, st
        return rgb, alpha

    def _eye_palette(self, c):
        entry = c["faces"].get("north")
        if entry is None:
            return None
        rect, _m = entry
        u0, v0, u1, v1 = rect
        xa, xb = sorted((int(u0 * self.res), int(u1 * self.res)))
        ya, yb = sorted((int(v0 * self.res), int(v1 * self.res)))
        region = self.raw[ya:max(yb, ya + 1), xa:max(xb, xa + 1)].reshape(-1, 4)
        region = region[region[:, 3] > 0.5][:, :3]
        if len(region) == 0:
            return None
        lum = _lum(region)
        pupil = region[np.argmin(lum)] * 0.6
        sat = region.max(axis=1) - region.min(axis=1)
        ok = (lum > 0.12) & (lum < 0.85)
        if np.any(ok & (sat > 0.18)):
            iris = region[np.argmax(np.where(ok, sat, -1))]
        else:
            iris = np.array([0.22, 0.30, 0.48])
        return pupil, iris

    def _paint_eye(self, rgb, mats, faces, st, pal):
        if pal is None:
            return
        pupil, iris = pal
        front = faces == "north"
        s, t = st[:, 0] - 0.5, st[:, 1] - 0.5
        inside = front & ((s / 0.5) ** 2 + (t / 0.5) ** 2 <= 1.0)
        rgb[inside] = pupil
        mats[inside] = "eye"
        low = inside & (t < -0.02) & ((s / 0.38) ** 2 + ((t + 0.18) / 0.3) ** 2 <= 1.0)
        rgb[low] = iris
        mats[low] = "iris"
        light = low & (((s / 0.26) ** 2 + ((t + 0.3) / 0.16) ** 2) <= 1.0)
        rgb[light] = np.clip(iris * 1.45 + 0.08, 0, 1)
        mats[light] = "iris_light"
        g1 = inside & (((s + 0.17) / 0.17) ** 2 + ((t - 0.2) / 0.19) ** 2 <= 1.0)
        g2 = inside & (((s - 0.2) / 0.08) ** 2 + ((t + 0.12) / 0.08) ** 2 <= 1.0)
        rgb[g1 | g2] = 1.0
        mats[g1 | g2] = "eye_white"

    def colour(self, p):
        p_px = p * PX
        idx = self._dists(p).argmin(axis=1)
        rgb = np.zeros((len(p), 3))
        mats = np.array(["skin"] * len(p), dtype=object)
        for i, c in enumerate(self.cubes):
            m = idx == i
            if not np.any(m):
                continue
            sub_rgb, _a = self._sample(p_px[m], c)
            if c["eye"]:
                sub_m = mats[m]
                self._paint_eye(sub_rgb, sub_m, self._last_faces, self._last_st, self.eye_colours.get(i))
                mats[m] = sub_m
            rgb[m] = sub_rgb
        return rgb, mats

    def material(self, p):
        return self.colour(p)[1]


OVERRIDES_PATH = os.path.join(HERE, "voxel_overrides.json")


def overrides(dex):
    import json
    try:
        with open(OVERRIDES_PATH, encoding="utf-8") as f:
            return json.load(f).get(str(dex), {})
    except OSError:
        return {}


def hidden_bones(model, anim, hide_names=()):
    """Bones not to voxelize: scaled to (near) zero in the stand clip's first frame, named in the overrides' hide
    list, or under such a bone."""
    _locals, scales = anim["rest"]
    parent = model.get("parent") or [None] * len(model["names"])
    hidden = set()
    for i in model.get("order", range(len(model["names"]))):
        sc = scales[i] if i < len(scales) else (1, 1, 1)
        if (min(abs(c) for c in sc) < 0.05 or model["names"][i] in hide_names
                or (parent[i] is not None and parent[i] in hidden)):
            hidden.add(i)
    return hidden


def convert(model, anim, png_path, height_m, out_glb, out_png, body_plan=None, fix=None):
    """Voxelizes one converted species. Returns (triangles, texture size, scale, height_nodes, width_nodes)."""
    lo_px, hi_px = np.array(model["bounds_px"][0]), np.array(model["bounds_px"][1])
    height_px = hi_px[1] - lo_px[1]
    voxel_px = max(height_px / VOXELS_TALL, 0.2)
    fix = fix or {}
    sculpt = CobbleSculpt(model, png_path, voxel_px, hidden_bones(model, anim, fix.get("hide", ())))
    # The grid covers the visible cubes only (some models carry far-away invisible helper boxes).
    corners = []
    for c in sculpt.cubes:
        for sx in (0, 1):
            for sy in (0, 1):
                for sz in (0, 1):
                    loc = c["c"] + (np.array([sx, sy, sz]) * 2 - 1) * c["h"]
                    corners.append(c["R"] @ loc + c["t"])
    corners = np.array(corners)
    lo_px, hi_px = corners.min(axis=0), corners.max(axis=0)
    height_px = hi_px[1] - lo_px[1]
    voxel = voxel_px / PX
    sculpt.voxel_nodes = voxel
    pad = 2 * voxel
    BV.set_grid(lo_px / PX - pad, hi_px / PX + pad)
    dims, solid, bone, rgb_grid = BV.voxelize(sculpt, voxel, seed=7)
    quads, details = BV.build_mesh(dims, solid, bone, rgb_grid, voxel, sculpt)
    mesh, atlas, side = BV.assemble(sculpt, dims, quads, voxel, details, rgb_grid)
    vox_model = dict(model)
    vox_model["positions"] = [tuple(c * PX for c in p) for p in mesh["positions"]]
    vox_model["normals"] = mesh["normals"]
    vox_model["uvs"] = mesh["uvs"]
    vox_model["joints"] = mesh["joints"]
    vox_model["weights"] = mesh["weights"]
    vox_model["indices"] = mesh["indices"]
    with open(out_glb, "wb") as f:
        f.write(ci.write_glb(vox_model, anim))
    Image.fromarray(atlas).save(out_png, optimize=True)
    # Extents from the voxels themselves. The size rule targets the creature's bulk: its height, or for serpents
    # (Onix, Gyarados, Ekans) 60% of their length, so they do not stretch across the landscape.
    pos = np.array(mesh["positions"])
    ext = pos.max(axis=0) - pos.min(axis=0)
    model_h = float(ext[1])
    width = float(max(ext[0], ext[2]))
    bulk = max(model_h, 0.6 * width) if body_plan == "serpent" else model_h
    scale = visual_height(height_m) / max(bulk, 1e-3) * float(fix.get("scale", 1.0))
    return len(mesh["indices"]) // 3, side, scale, model_h, width


# ---------------------------------------------------------------- the pack

def _sculpt_module(name):
    """The hand-made sculpt module for a species (tools/sculpt/<name>.py with build()), or None."""
    import importlib
    path = os.path.join(HERE, name + ".py")
    if not os.path.isfile(path):
        return None
    mod = importlib.import_module("tools.sculpt." + name)
    return mod if hasattr(mod, "build") and hasattr(mod, "H") else None


def _from_sculpt(mod, height_m, out_glb, out_png):
    """A hand-made sculpt (the reference look) instead of the Cobblemon conversion."""
    sculpt = mod.build()
    if hasattr(mod, "BOUNDS"):
        BV.set_grid(*mod.BOUNDS)
    else:
        BV.set_grid((-0.35, -0.02, -0.35), (0.35, 0.82, 0.55))
    out_dir = os.path.dirname(out_glb)
    BV.build(sculpt, out_dir)
    os.replace(os.path.join(out_dir, "style_voxel.glb"), out_glb)
    os.replace(os.path.join(out_dir, "style_voxel.png"), out_png)
    from . import rig
    locs = rig.locators_entity_space(sculpt)
    return visual_height(height_m) / mod.H, mod.H, 0.6, locs


def _job(args):
    dex, name, model, shiny, height_m, plan, pack = args
    fix = overrides(dex)
    out = {}
    try:
        mod = _sculpt_module(name)
        glb = os.path.join(pack, "models", "mmp_%04d.glb" % dex)
        png = os.path.join(pack, "textures", "mmp_%04d.png" % dex)
        if mod is not None:
            scale, h, w, locs = _from_sculpt(mod, height_m, glb, png)
            out.update(scale=scale, height=h, width=w, locators=locs, source="sculpt")
            import shutil
            shutil.copyfile(glb, os.path.join(pack, "models", "mmp_%04d_s.glb" % dex))
            shutil.copyfile(png, os.path.join(pack, "textures", "mmp_%04d_s.png" % dex))
        else:
            _t, _s, scale, h, w = convert(model, model["anim"], model["base_png"], height_m, glb, png, plan, fix)
            convert(model, model["anim"], shiny or model["base_png"], height_m,
                    os.path.join(pack, "models", "mmp_%04d_s.glb" % dex),
                    os.path.join(pack, "textures", "mmp_%04d_s.png" % dex), plan, fix)
            out.update(scale=scale, height=h, width=w, locators=model.get("locators", {}), source="cobblemon")
    except Exception as e:  # one species failing must not stop the pack
        out["error"] = "%s: %s" % (type(e).__name__, e)
    return dex, out


def write_pack(out_dir, converted, commit, heights, jobs=4, plans=None):
    """The micro-voxel pack: same layout and init.lua fields as cobblemon_import.write_pack, plus scale (the
    visual size the creature code applies) and mesh_shiny (the shiny atlas needs its own UVs)."""
    import multiprocessing
    import shutil
    pack = os.path.join(out_dir, ci.PACK_NAME)
    if os.path.isdir(pack):
        shutil.rmtree(pack)
    os.makedirs(os.path.join(pack, "models"))
    os.makedirs(os.path.join(pack, "textures"))
    with open(os.path.join(pack, "mod.conf"), "w", encoding="utf-8") as f:
        f.write("name = %s\n" % ci.PACK_NAME)
        f.write("description = Micro-voxel creatures (M2.1) built from Cobblemon models and Minemon sculpts by "
                "tools/sculpt/voxel_cobblemon.py (generated; not committed; see CREDITS.txt).\n")
    plans = plans or {}
    work = [(dex, name, model, shiny, heights.get(dex, 1.0), plans.get(dex), pack)
            for dex, name, model, shiny in converted]
    with multiprocessing.Pool(jobs) as pool:
        results = dict(pool.map(_job, work))
    lines = [
        "-- Generated by tools/sculpt/voxel_cobblemon.py (M2.1 micro-voxel style). Do not edit: run scripts/setup.sh.",
        "-- Geometry, skins and clips from kirbycope/cobblemon-bedrock (commit %s), or a Minemon sculpt." % commit,
        "-- scale: the visual size to apply (fx_logic.visual_height); height and width: the model box at scale 1.",
        "minemon_pack = rawget(_G, \"minemon_pack\") or {}",
        "minemon_pack.style = \"microvoxel\"",
        "minemon_pack.models = {",
    ]
    anims = ci.anims_lua()
    failed = []
    for dex, name, _model, _shiny in converted:
        r = results.get(dex, {})
        if "error" in r:
            failed.append((dex, r["error"]))
            continue
        lines.append("\t[%d] = {mesh = \"mmp_%04d.glb\", mesh_shiny = \"mmp_%04d_s.glb\", texture = \"mmp_%04d.png\","
                     " texture_shiny = \"mmp_%04d_s.png\"," % (dex, dex, dex, dex, dex))
        lines.append("\t\theight = %s, width = %s, scale = %s, source = \"%s\","
                     % (ci.lua_number(r["height"]), ci.lua_number(r["width"]), ci.lua_number(r["scale"]),
                        r["source"]))
        lines.append("\t\tlocators = %s," % ci.locators_lua(r["locators"]))
        lines.append("\t\tanims = %s}," % anims)
    lines.append("}")
    with open(os.path.join(pack, "init.lua"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    with open(os.path.join(pack, "CREDITS.txt"), "w", encoding="utf-8") as f:
        f.write("Minemon micro-voxel creatures, generated at build time (never committed).\n"
                "Geometry, skins and animations derived from https://github.com/kirbycope/cobblemon-bedrock at "
                "commit %s (MIT code; per-model Creative Commons non-commercial attribution licences). "
                "Private, non-commercial use only (D-029, D-032).\n" % commit)
    for dex, err in failed:
        print("voxel_cobblemon: FAIL dex %d: %s" % (dex, err))
    print("voxel_cobblemon: %d species in %s (%d failed)" % (len(converted) - len(failed), pack, len(failed)))
    return pack
