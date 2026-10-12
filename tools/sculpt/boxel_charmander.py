"""Charmander in the boxel "voxel hero" style (M2.1, D-032): the reference for every boxel creature.

Design rules (docs/ART_GUIDE.md, "Boxel creatures"): a big head (about 40% of the height) with a muzzle box;
eyes are 3D decals on the head front, tall, with an iris low and a big glint high; chunky limbs with white claw
boxes; a tail of shrinking boxes that curls up to the flame (the flame is an effect on locator_fire). Units are
nodes, feet on y = 0, facing -z, +x is the creature's left.
Usage: python3 -m tools.sculpt.boxel_charmander OUT_DIR  (writes style_boxel.glb and style_boxel.png)
"""

import os
import sys

from . import boxel as B
from . import sdf as S
from .charmander import pose

PALETTE = {
    "skin": (0.97, 0.50, 0.16),
    "belly": (1.0, 0.86, 0.46),
    "claw": (0.97, 0.95, 0.90),
    "eye": (0.05, 0.06, 0.11),
    "iris": (0.13, 0.44, 0.74),
    "eye_white": (1.0, 1.0, 1.0),
    "mouth": (0.33, 0.09, 0.05),
    "nostril": (0.28, 0.08, 0.04),
    "tail_tip": (1.0, 0.70, 0.22),
}

BONES = [
    ("root", None, (0.0, 0.0, 0.0)),
    ("hips", "root", (0.0, 0.16, 0.0)),
    ("spine", "hips", (0.0, 0.34, 0.0)),
    ("head", "spine", (0.0, 0.45, -0.02)),
    ("arm_l", "spine", (0.15, 0.42, -0.03)),
    ("arm_r", "spine", (-0.15, 0.42, -0.03)),
    ("leg_l", "hips", (0.10, 0.19, 0.0)),
    ("leg_r", "hips", (-0.10, 0.19, 0.0)),
    ("tail1", "hips", (0.0, 0.18, 0.10)),
    ("tail2", "tail1", (0.0, 0.20, 0.22)),
    ("tail3", "tail2", (0.0, 0.26, 0.32)),
    ("locator_fire", "tail3", (0.0, 0.50, 0.41)),
    ("locator_mouth", "head", (0.0, 0.52, -0.28)),
    ("locator_head", "head", (0.0, 0.78, -0.02)),
]

LOCATORS = {
    "mouth": (0.0, 0.52, -0.28), "head": (0.0, 0.78, -0.02), "target": (0.0, 0.40, -0.05),
    "middle": (0.0, 0.34, 0.0), "fire": (0.0, 0.50, 0.41),
}


def boxes():
    bx = []
    for s in (1, -1):
        side = "l" if s > 0 else "r"
        leg, arm = "leg_" + side, "arm_" + side
        bx.append(B.Box("foot", leg, (0.105 * s, 0.035, -0.04), (0.13, 0.07, 0.19), "skin"))
        for k in (-1, 0, 1):
            bx.append(B.Box("toe", leg, (0.105 * s + 0.04 * k, 0.022, -0.145), (0.032, 0.034, 0.04), "claw",
                            bevel=0.008))
        bx.append(B.Box("thigh", leg, (0.10 * s, 0.13, 0.0), (0.13, 0.14, 0.15), "skin"))
        bx.append(B.Box("arm", arm, (0.185 * s, 0.37, -0.05), (0.095, 0.15, 0.10), "skin", rot=(28, 0, -16 * s)))
        bx.append(B.Box("hand", arm, (0.215 * s, 0.285, -0.115), (0.10, 0.085, 0.10), "skin"))
        for k in (-1, 0, 1):
            bx.append(B.Box("claw", arm, (0.215 * s + 0.03 * k, 0.255, -0.175), (0.024, 0.034, 0.045), "claw",
                            rot=(25, 0, 0), bevel=0.006))
    bx.append(B.Box("torso", "hips", (0.0, 0.27, 0.0), (0.30, 0.25, 0.24), "skin", bevel=0.03))
    bx.append(B.Box("chest", "spine", (0.0, 0.40, -0.01), (0.26, 0.12, 0.21), "skin", bevel=0.03))
    bx.append(B.Box("head", "head", (0.0, 0.615, -0.02), (0.40, 0.33, 0.34), "skin", bevel=0.06))
    bx.append(B.Box("muzzle", "head", (0.0, 0.52, -0.205), (0.31, 0.15, 0.12), "skin", bevel=0.045))
    bx.append(B.Box("tail1", "tail1", (0.0, 0.17, 0.17), (0.15, 0.13, 0.16), "skin", rot=(-10, 0, 0)))
    bx.append(B.Box("tail2", "tail2", (0.0, 0.225, 0.285), (0.12, 0.11, 0.14), "skin", rot=(-32, 0, 0)))
    bx.append(B.Box("tail3", "tail3", (0.0, 0.315, 0.36), (0.10, 0.10, 0.12), "skin", rot=(-58, 0, 0)))
    bx.append(B.Box("tail4", "tail3", (0.0, 0.415, 0.395), (0.085, 0.10, 0.085), "tail_tip", rot=(-78, 0, 0)))
    return bx


def decals():
    d = [S.Decal(S.ellipsoid((0.0, 0.29, -0.13), (0.115, 0.15, 0.06)), "belly", "belly"),
         S.Decal(S.ellipsoid((0.0, 0.40, -0.12), (0.10, 0.06, 0.04)), "belly", "chest"),
         S.Decal(S.ellipsoid((0.0, 0.11, 0.22), (0.07, 0.08, 0.12)), "belly", "tail_under")]
    for s in (1, -1):
        ex, ey = 0.095 * s, 0.665
        d.append(S.Decal(S.ellipsoid((ex, ey, -0.20), (0.052, 0.07, 0.05)), "eye", "eye"))
        d.append(S.Decal(S.ellipsoid((ex - 0.004 * s, ey - 0.036, -0.20), (0.040, 0.032, 0.05)), "iris", "iris"))
        d.append(S.Decal(S.ellipsoid((ex + 0.017 * s, ey + 0.028, -0.20), (0.021, 0.024, 0.05)), "eye_white",
                         "glint"))
        d.append(S.Decal(S.ellipsoid((ex - 0.02 * s, ey - 0.022, -0.20), (0.009, 0.009, 0.05)), "eye_white",
                         "glint2"))
        d.append(S.Decal(S.ellipsoid((0.06 * s, 0.578, -0.27), (0.011, 0.008, 0.03)), "nostril", "nostril"))

    def smile(p):
        x = p[:, 0]
        curve = 0.492 + 1.1 * x * x + 6.0 * S.np.maximum(S.np.abs(x) - 0.1, 0) ** 2
        return S.np.maximum(S.np.abs(p[:, 1] - curve) - 0.0055, S.np.maximum(S.np.abs(x) - 0.14, p[:, 2] + 0.245))
    d.append(S.Decal(smile, "mouth", "mouth"))
    return d


def model():
    return B.Model(boxes(), decals(), PALETTE, BONES, LOCATORS, pose)


def main(argv=None):
    out = (argv or sys.argv[1:] or ["."])[0]
    os.makedirs(out, exist_ok=True)
    tris, size = B.build(model(), os.path.join(out, "style_boxel.glb"), os.path.join(out, "style_boxel.png"))
    print("boxel_charmander: %d triangles, texture %dx%d" % (tris, size, size))
    return 0


if __name__ == "__main__":
    sys.exit(main())
