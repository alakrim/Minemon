#!/usr/bin/env python3
"""The toon-voxel texture bake for the converted creatures (M2.1 art pass; docs/ART_GUIDE.md, D-032).

tools/cobblemon_import.py builds each model with an outline hull per solid cube and records, per cube, the texel
rectangles of its six faces. This module repaints the source skin once, at conversion time, so the runtime cost is
nil:

  * 4x upscale (nearest), so the light can be painted at a finer grain than the 1 px art.
  * Per face, a top light: side faces fade from +LIGHT_TOP at their top edge to -LIGHT_BOTTOM at the bottom, top
    faces are lifted, bottom faces darkened. Every face gets a one pixel bevel: a highlight on its upper edge and a
    soft occlusion on the others, so each cube reads as a chiselled block.
  * The palette strip below the skin: one cell per outlined cube, filled with the cube's average colour, darkened
    and saturated (the cel outline colour). Its rows are the ones cobblemon_import added to the UV space.

A texel is shaded once: rectangles shared by mirrored limbs are painted by the first face that reaches them.
Dev dependency (setup time only): numpy and Pillow.
"""

import colorsys

import numpy as np
from PIL import Image

SCALE = 4
LIGHT_TOP = 0.10
LIGHT_BOTTOM = 0.16
TOP_FACE = 1.12
BOTTOM_FACE = 0.72
BEVEL_HIGHLIGHT = 1.16
BEVEL_SHADE = 0.86
OUTLINE_VALUE = 0.30
OUTLINE_SATURATION = 1.25
SIDE_FACES = ("north", "south", "east", "west")

# Style presets (M2.1 style options, D-032). The converter takes the geometry keys (round_px, outline_px), this module
# the rest: texture upscale ("pixel" nearest, "epx" Scale2x twice: smooth diagonals, crisp colour borders), an
# optional blur, the face shading mode, grain, saturation and the outline darkness.
STYLES = {
    "toon_voxel": {"round_px": 0.0, "outline_px": 0.45, "upscale": "pixel", "blur": 0, "shade": "chisel",
                   "grain": 0.0, "saturation": 1.1, "outline_value": 0.22, "flatten": 0.07, "glint": True},
    "vinyl": {"round_px": 1.8, "outline_px": 0.0, "upscale": "epx", "blur": 1, "shade": "soft",
              "grain": 0.0, "saturation": 1.1, "outline_value": 0.3, "flatten": 0.11, "glint": True},
    "cel": {"round_px": 1.3, "outline_px": 0.5, "upscale": "epx", "blur": 0, "shade": "cel",
            "grain": 0.0, "saturation": 1.15, "outline_value": 0.14, "flatten": 0.12, "glint": True},
    "painterly": {"round_px": 0.7, "outline_px": 0.25, "upscale": "epx", "blur": 1, "shade": "paint",
                  "grain": 0.06, "saturation": 0.95, "outline_value": 0.24, "flatten": 0.08, "glint": True},
}
DEFAULT_STYLE = "toon_voxel"


def _epx(img):
    """Scale2x (EPX) on an HxWx4 array: doubles the size, rounding staircase edges without blurring colours."""
    p = img
    a = np.roll(p, 1, axis=0)
    a[0] = p[0]
    d = np.roll(p, -1, axis=0)
    d[-1] = p[-1]
    c = np.roll(p, 1, axis=1)
    c[:, 0] = p[:, 0]
    b = np.roll(p, -1, axis=1)
    b[:, -1] = p[:, -1]

    def eq(x, y):
        return np.all(np.abs(x - y) < 1e-6, axis=-1)
    ca, ab, dc, bd = eq(c, a), eq(a, b), eq(d, c), eq(b, d)
    o1 = np.where((ca & ~dc & ~ab)[..., None], a, p)
    o2 = np.where((ab & ~ca & ~bd)[..., None], b, p)
    o3 = np.where((dc & ~bd & ~ca)[..., None], c, p)
    o4 = np.where((bd & ~ab & ~dc)[..., None], d, p)
    h, w = p.shape[:2]
    out = np.zeros((h * 2, w * 2, p.shape[2]))
    out[0::2, 0::2] = o1
    out[0::2, 1::2] = o2
    out[1::2, 0::2] = o3
    out[1::2, 1::2] = o4
    return out


def _upscale(src, tex_w, tex_h, mode):
    """The skin at SCALE pixels per texel: nearest, or EPX twice (from a 1 px per texel base)."""
    h_px, w_px = src.shape[:2]
    if mode != "epx":
        ys = np.minimum((np.arange(int(tex_h * SCALE)) / SCALE * (h_px / tex_h)).astype(int), h_px - 1)
        xs = np.minimum((np.arange(int(tex_w * SCALE)) / SCALE * (w_px / tex_w)).astype(int), w_px - 1)
        return src[ys][:, xs]
    base_ys = np.minimum((np.arange(int(tex_h)) * (h_px / tex_h)).astype(int), h_px - 1)
    base_xs = np.minimum((np.arange(int(tex_w)) * (w_px / tex_w)).astype(int), w_px - 1)
    out = src[base_ys][:, base_xs]
    for _ in range(2):
        out = _epx(out)
    return out


def _blur_rgb(rgb, alpha, radius):
    """A small premultiplied box blur, so colours do not bleed in from transparent texels."""
    if radius <= 0:
        return rgb
    pre = rgb * alpha[..., None]
    acc = np.zeros_like(pre)
    wacc = np.zeros_like(alpha)
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            acc += np.roll(np.roll(pre, dy, axis=0), dx, axis=1)
            wacc += np.roll(np.roll(alpha, dy, axis=0), dx, axis=1)
    out = acc / np.maximum(wacc, 1e-6)[..., None]
    return np.where(alpha[..., None] > 0, out, rgb)


def _flatten(src, threshold):
    """Merges near colours of the skin into flat regions (greedy clustering by frequency): Cobblemon skins dither
    their shading with speckled shades, which the bake would amplify. Distinct colours (eyes, mouth, markings) stay,
    because they are far apart. src: HxWx4 in 0..1; returns a copy."""
    if threshold <= 0:
        return src
    out = src.copy()
    opaque = src[..., 3] > 0.5
    cols = src[..., :3][opaque]
    if len(cols) == 0:
        return out
    q = np.round(cols * 255).astype(int)
    keys, inverse, counts = np.unique(q[:, 0] * 65536 + q[:, 1] * 256 + q[:, 2], return_inverse=True,
                                      return_counts=True)
    uniq = np.stack([keys // 65536, (keys // 256) % 256, keys % 256], axis=1) / 255.0
    centres, weights, assign = [], [], np.zeros(len(uniq), dtype=int)
    for idx in np.argsort(-counts):
        c = uniq[idx]
        best, best_d = -1, threshold
        for k, cen in enumerate(centres):
            d = np.sqrt(((c - cen) ** 2).sum())
            if d < best_d:
                best, best_d = k, d
        if best < 0:
            centres.append(c.copy())
            weights.append(counts[idx])
            best = len(centres) - 1
        else:
            w = weights[best]
            centres[best] = (centres[best] * w + c * counts[idx]) / (w + counts[idx])
            weights[best] = w + counts[idx]
        assign[idx] = best
    flat = np.array(centres)[assign[inverse.reshape(-1)]]
    rgb = out[..., :3]
    rgb[opaque] = flat
    return out


def _glint(rgb, alpha, model, sx):
    """A catch light in every eye: the front face of each cube on an eye bone (Cobblemon names them eye_left,
    eye_right, eye...) gets a small white spot near its upper corner. Generic for every species with eye bones."""
    for cube in model["cubes"] + model.get("flat_cubes", []):
        name = cube.get("bone", "")
        if "eye" not in name or "lid" in name or "brow" in name or "locator" in name:
            continue
        for face, rect in cube["rects"]:
            if face != "north":
                continue
            (x0, y0, x1, y1), _top = _rect_px(rect, sx, sx)
            w, h = x1 - x0, y1 - y0
            if w < 4 or h < 4:
                continue
            gx, gy = x0 + max(1, w // 4), y0 + max(1, h // 5)
            size = max(2, min(w, h) // 3)
            spot = alpha[gy:gy + size, gx:gx + size] > 0.5
            patch = rgb[gy:gy + size, gx:gx + size]
            patch[spot] = 0.25 * patch[spot] + 0.75


def _saturate(rgb, amount):
    if abs(amount - 1.0) < 1e-6:
        return rgb
    luma = (rgb * np.array([0.299, 0.587, 0.114])).sum(axis=-1, keepdims=True)
    return np.clip(luma + (rgb - luma) * amount, 0.0, 1.0)


def _rect_px(rect, sx, sy):
    """A face rect (u0, v0, u1, v1) in skin texels to integer pixel bounds (x0, y0, x1, y1) in the upscaled image,
    and whether the image's top row is at y0 (False when the per-face uv runs upwards)."""
    u0, v0, u1, v1 = rect
    top_first = v1 >= v0
    xa, xb = sorted((u0, u1))
    ya, yb = sorted((v0, v1))
    return (int(round(xa * sx)), int(round(ya * sy)), int(round(xb * sx)), int(round(yb * sy))), top_first


def _edge_distance(h, w):
    """Per pixel distance to the nearest face border, normalised by the shorter side (0 at the border)."""
    yy = np.minimum(np.arange(h), np.arange(h)[::-1])[:, None]
    xx = np.minimum(np.arange(w), np.arange(w)[::-1])[None, :]
    return np.minimum(yy, xx) / max(1.0, min(h, w))


def _shade_soft(rgb, done, box, top_first, face, style):
    """Vinyl and painterly: a smooth top light, a soft occlusion toward the borders and, for vinyl, a sheen."""
    x0, y0, x1, y1 = box
    h, w = y1 - y0, x1 - x0
    if h <= 0 or w <= 0:
        return
    region = done[y0:y1, x0:x1]
    if region.all():
        return
    t = (np.arange(h) + 0.5) / h
    if not top_first:
        t = t[::-1]
    t = t[:, None]
    paint = style["shade"] == "paint"
    if face in SIDE_FACES:
        light = 1.0 + (0.14 if paint else 0.08) - (0.34 if paint else 0.2) * t
    elif face == "up":
        light = np.full((h, 1), 1.12)
    else:
        light = np.full((h, 1), 0.68)
    mult = np.repeat(light, w, axis=1)
    ao = 1.0 - (0.3 if paint else 0.16) * np.exp(-_edge_distance(h, w) / 0.12)
    mult = mult * ao
    add = np.zeros((h, w))
    if not paint and face != "down":
        # The vinyl sheen: a bright band across the upper part of sides and the middle of tops.
        band = np.exp(-((t - 0.22) / 0.12) ** 2) if face in SIDE_FACES else 0.6 * np.exp(-((t - 0.5) / 0.25) ** 2)
        add = np.repeat(band * 0.10, w, axis=1)
    sub = rgb[y0:y1, x0:x1]
    fresh = ~region
    sub[fresh] = np.clip(sub[fresh] * mult[fresh][:, None] + add[fresh][:, None], 0.0, 1.0)
    region[fresh] = True


def _shade_cel(rgb, done, box, top_first, face, _style):
    """Cel: flat colour with one hard shadow band at the bottom of side faces and a thin rim light on top."""
    x0, y0, x1, y1 = box
    h, w = y1 - y0, x1 - x0
    if h <= 0 or w <= 0:
        return
    region = done[y0:y1, x0:x1]
    if region.all():
        return
    t = (np.arange(h) + 0.5) / h
    if not top_first:
        t = t[::-1]
    if face in SIDE_FACES:
        rows = np.where(t > 0.62, 0.7, 1.0)
        rows = np.where(t < 0.1, 1.18, rows)
    elif face == "up":
        rows = np.full(h, 1.14)
    else:
        rows = np.full(h, 0.62)
    mult = np.repeat(rows[:, None], w, axis=1)
    sub = rgb[y0:y1, x0:x1]
    fresh = ~region
    sub[fresh] = np.clip(sub[fresh] * mult[fresh][:, None], 0.0, 1.0)
    region[fresh] = True


def _shade_face(rgb, done, box, top_first, face, style=None):
    mode = (style or {}).get("shade", "chisel")
    if mode in ("soft", "paint"):
        return _shade_soft(rgb, done, box, top_first, face, style)
    if mode == "cel":
        return _shade_cel(rgb, done, box, top_first, face, style)
    return _shade_chisel(rgb, done, box, top_first, face)


def _shade_chisel(rgb, done, box, top_first, face):
    x0, y0, x1, y1 = box
    h, w = y1 - y0, x1 - x0
    if h <= 0 or w <= 0:
        return
    region = done[y0:y1, x0:x1]
    if region.all():
        return
    t = (np.arange(h) + 0.5) / h
    if not top_first:
        t = t[::-1]
    if face in SIDE_FACES:
        rows = 1.0 + LIGHT_TOP - (LIGHT_TOP + LIGHT_BOTTOM) * t
    elif face == "up":
        rows = np.full(h, TOP_FACE)
    else:
        rows = np.full(h, BOTTOM_FACE)
    mult = np.repeat(rows[:, None], w, axis=1)
    if h >= 3 and w >= 3:
        top_row = 0 if top_first else h - 1
        bottom_row = h - 1 - top_row
        mult[bottom_row, :] *= BEVEL_SHADE
        mult[:, 0] *= BEVEL_SHADE ** 0.5
        mult[:, -1] *= BEVEL_SHADE ** 0.5
        mult[top_row, :] *= BEVEL_HIGHLIGHT if face != "down" else BEVEL_SHADE
    sub = rgb[y0:y1, x0:x1]
    fresh = ~region
    sub[fresh] = np.clip(sub[fresh] * mult[fresh][:, None], 0.0, 1.0)
    region[fresh] = True


def _outline_colour(src_rgb, src_a, rects, sx, sy, value=OUTLINE_VALUE):
    pixels = []
    for _face, rect in rects:
        (x0, y0, x1, y1), _ = _rect_px(rect, sx, sy)
        if x1 > x0 and y1 > y0:
            a = src_a[y0:y1, x0:x1]
            c = src_rgb[y0:y1, x0:x1][a > 0.5]
            if len(c):
                pixels.append(c)
    if not pixels:
        return (0.1, 0.08, 0.1)
    mean = np.concatenate(pixels).mean(axis=0)
    h, s, v = colorsys.rgb_to_hsv(*mean)
    return colorsys.hsv_to_rgb(h, min(1.0, s * OUTLINE_SATURATION), v * value)


def bake(src_png, model, out_png, style=None):
    """Writes the baked skin for model (from cobblemon_import.build_model) to out_png, in a STYLES preset."""
    style = style or STYLES[DEFAULT_STYLE]
    tex_w, tex_h, pad_rows = model["tex_size"]
    img = Image.open(src_png).convert("RGBA")
    src = np.asarray(img).astype(np.float64) / 255.0
    res = img.width / tex_w  # the skin may be a multiple of the geometry's texture size (HD skins)
    up = _upscale(_flatten(src, style.get("flatten", 0.0)), tex_w, tex_h, style.get("upscale", "pixel"))
    skin_h, out_w = up.shape[0], up.shape[1]
    out_h = int(round((tex_h + pad_rows) * SCALE))
    rgb = np.zeros((out_h, out_w, 3))
    alpha = np.zeros((out_h, out_w))
    alpha[:skin_h] = up[..., 3]
    rgb[:skin_h] = _blur_rgb(up[..., :3], up[..., 3], style.get("blur", 0))
    done = np.zeros((out_h, out_w), dtype=bool)
    done[skin_h:] = True
    for cube in model["cubes"] + model.get("flat_cubes", []):
        for face, rect in cube["rects"]:
            box, top_first = _rect_px(rect, SCALE, SCALE)
            _shade_face(rgb, done, box, top_first, face, style)
    rgb[:skin_h] = _saturate(rgb[:skin_h], style.get("saturation", 1.0))
    if style.get("glint"):
        _glint(rgb, alpha, model, SCALE)
    grain = style.get("grain", 0.0)
    if grain > 0:
        rng = np.random.RandomState(7)
        noise = rng.rand(skin_h, out_w)
        rgb[:skin_h] = np.clip(rgb[:skin_h] * (1.0 + (noise[..., None] - 0.5) * 2 * grain), 0.0, 1.0)
    cols = max(1, int(tex_w))
    src_rgb, src_a = src[..., :3], src[..., 3]
    for cube in model["cubes"]:
        cell = cube["cell"]
        cx, cy = (cell % cols) * SCALE, skin_h + (cell // cols) * SCALE
        rgb[cy:cy + SCALE, cx:cx + SCALE] = _outline_colour(src_rgb, src_a, cube["rects"], res, res,
                                                             style.get("outline_value", OUTLINE_VALUE))
        alpha[cy:cy + SCALE, cx:cx + SCALE] = 1.0
    out = np.concatenate([rgb, alpha[..., None]], axis=-1)
    Image.fromarray((out * 255.0 + 0.5).astype(np.uint8), "RGBA").save(out_png, optimize=True)
