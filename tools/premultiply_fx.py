"""Writes the premultiplied copy (<name>_pm.png) of every effect texture in mods/minemon/minemon_fx/textures.

Why (M2.1 review): Luanti's "add" and "sub" particle blends multiply what is behind them by the framebuffer's alpha
(GL_DST_ALPHA), and soft smoke or water leave that alpha below 1, so every glow drawn over them became a dark
square. minemon_fx draws its glows with the "screen" blend instead (ONE, ONE_MINUS_SRC_COLOR), which ignores alpha:
it needs textures whose colour is already multiplied by their alpha (black where transparent). lib.lua (F.tex) swaps
a texture for its _pm copy when a recipe asks for "add". Run after any texture generator; deterministic.
"""
import argparse
import glob
import os

import numpy as np
from PIL import Image

DEFAULT_DIR = os.path.join(os.path.dirname(__file__), "..", "mods", "minemon", "minemon_fx", "textures")


def premultiply(img):
    a = img[..., 3:4].astype(np.float32) / 255.0
    rgb = np.round(img[..., :3].astype(np.float32) * a).astype(np.uint8)
    out = np.empty_like(img)
    out[..., :3] = rgb
    out[..., 3] = 255
    return out


def write_all(tex_dir):
    names = []
    for path in sorted(glob.glob(os.path.join(tex_dir, "minemon_fx_*.png"))):
        if path.endswith("_pm.png"):
            continue
        img = np.asarray(Image.open(path).convert("RGBA"))
        out = path[:-4] + "_pm.png"
        Image.fromarray(premultiply(img), "RGBA").save(out, optimize=True)
        names.append(os.path.basename(out))
    return names


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--dir", default=DEFAULT_DIR)
    args = ap.parse_args(argv)
    names = write_all(os.path.abspath(args.dir))
    print("wrote %d premultiplied textures" % len(names))


if __name__ == "__main__":
    main()
