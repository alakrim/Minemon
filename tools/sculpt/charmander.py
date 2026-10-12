"""Charmander, the reference sculpt (M2.1, D-032; hand-authored by the orchestrator, our own fan design for private
use). Every other species follows this file's layout: docs/ART_GUIDE.md, "Sculpting a creature".

Units are nodes. The feet stand on y = 0, the creature faces -z (Luanti's forward for glTF), +x is its left.
Proportions: a big round head (about 40% of the height) with a soft muzzle, a pear body with a cream belly, short
arms with three claws, stubby legs, and a long tail that curls up to the flame (the flame itself is an effect:
minemon_fx/art/charmander.lua rides it on the "fire" locator).
"""

import math

import numpy as np

from . import sdf as S

H = 0.78  # standing height to the top of the head, in nodes

PALETTE = {
    "skin": (0.95, 0.52, 0.22),
    "skin_dark": (0.86, 0.40, 0.16),
    "belly": (1.0, 0.90, 0.60),
    "claw": (0.96, 0.94, 0.88),
    "eye": (0.07, 0.09, 0.16),
    "iris": (0.14, 0.34, 0.80),
    "iris_light": (0.35, 0.62, 0.98),
    "eye_white": (1.0, 1.0, 1.0),
    "mouth": (0.42, 0.13, 0.08),
    "nostril": (0.30, 0.10, 0.06),
    "tail_tip": (1.0, 0.80, 0.30),
}

BONES = [
    ("root", None, (0.0, 0.0, 0.0)),
    ("hips", "root", (0.0, 0.17, 0.0)),
    ("spine", "hips", (0.0, 0.30, -0.01)),
    ("head", "spine", (0.0, 0.43, -0.02)),
    ("arm_l", "spine", (0.115, 0.37, -0.03)),
    ("arm_r", "spine", (-0.115, 0.37, -0.03)),
    ("leg_l", "hips", (0.085, 0.15, 0.01)),
    ("leg_r", "hips", (-0.085, 0.15, 0.01)),
    ("tail1", "hips", (0.0, 0.16, 0.11)),
    ("tail2", "tail1", (0.0, 0.17, 0.25)),
    ("tail3", "tail2", (0.0, 0.25, 0.35)),
    # Locator bones carry no skin; effects ride them (minemon_fx art profiles attach to "locator_fire").
    ("locator_fire", "tail3", (0.0, 0.46, 0.42)),
    ("locator_mouth", "head", (0.0, 0.50, -0.25)),
    ("locator_head", "head", (0.0, 0.76, -0.03)),
]

# Effect anchors (entity space: +z is forward, so these are written with z negated from model space at export).
LOCATORS = {
    "mouth": (0.0, 0.50, -0.25),
    "head": (0.0, 0.76, -0.03),
    "target": (0.0, 0.38, -0.05),
    "middle": (0.0, 0.33, 0.0),
    "fire": (0.0, 0.47, 0.42),
    "eye_left": (0.085, 0.60, -0.20),
    "eye_right": (-0.085, 0.60, -0.20),
    "foot_primary": (0.1, 0.02, -0.06),
    "foot_secondary": (-0.1, 0.02, -0.06),
}


def _mirror(fn, x_parts):
    """Builds a part for each side: fn(sign) -> list of Parts (sign +1 for the left, -1 for the right)."""
    out = []
    for s in (1, -1):
        out += fn(s)
    return out


def _arm(s):
    side = "arm_l" if s > 0 else "arm_r"
    sh = (0.13 * s, 0.38, -0.03)
    hand = (0.195 * s, 0.30, -0.125)
    parts = [S.Part(S.capsule(sh, hand, 0.056, 0.048), side, "skin", 0.03, "arm")]
    parts.append(S.Part(S.ellipsoid(hand, (0.052, 0.046, 0.05)), side, "skin", 0.02, "hand"))
    for k in (-1, 0, 1):  # three little claws pointing forward-down
        base = (hand[0] + 0.022 * k, hand[1] - 0.012, hand[2] - 0.032)
        tip = (hand[0] + 0.03 * k, hand[1] - 0.03, hand[2] - 0.062)
        parts.append(S.Part(S.capsule(base, tip, 0.012, 0.003), side, "claw", 0.0, "claw"))
    return parts


def _leg(s):
    side = "leg_l" if s > 0 else "leg_r"
    hip = (0.095 * s, 0.15, 0.01)
    ankle = (0.11 * s, 0.05, -0.01)
    parts = [S.Part(S.capsule(hip, ankle, 0.084, 0.066), side, "skin", 0.04, "thigh")]
    foot = (0.115 * s, 0.034, -0.05)
    parts.append(S.Part(S.ellipsoid(foot, (0.064, 0.036, 0.09)), side, "skin", 0.03, "foot"))
    for k in (-1, 0, 1):
        base = (foot[0] + 0.027 * k, 0.022, foot[2] - 0.06)
        tip = (foot[0] + 0.034 * k, 0.012, foot[2] - 0.098)
        parts.append(S.Part(S.capsule(base, tip, 0.013, 0.004), side, "claw", 0.0, "toe"))
    return parts


def build():
    parts = []
    # Body: a pear, wider low, with a soft belly bulge in front.
    parts.append(S.Part(S.ellipsoid((0.0, 0.25, 0.0), (0.175, 0.18, 0.155)), "hips", "skin", 0.0, "belly_low"))
    parts.append(S.Part(S.ellipsoid((0.0, 0.36, -0.01), (0.148, 0.13, 0.128)), "spine", "skin", 0.07, "chest"))
    parts.append(S.Part(S.ellipsoid((0.0, 0.25, -0.06), (0.14, 0.145, 0.11)), "hips", "skin", 0.05, "bulge"))
    # Head: big and round, a touch wider than tall, with the muzzle pushed forward and down.
    parts.append(S.Part(S.ellipsoid((0.0, 0.585, -0.025), (0.185, 0.170, 0.170)), "head", "skin", 0.06, "skull"))
    parts.append(S.Part(S.ellipsoid((0.0, 0.52, -0.14), (0.135, 0.092, 0.125)), "head", "skin", 0.07, "muzzle"))
    parts.append(S.Part(S.ellipsoid((0.0, 0.47, -0.04), (0.11, 0.07, 0.10)), "head", "skin", 0.05, "jaw"))
    parts += _mirror(_arm, None)
    parts += _mirror(_leg, None)
    # Tail: thick at the root, curling up behind; the last segment holds the flame.
    pts = [(0.0, 0.16, 0.08), (0.0, 0.15, 0.20), (0.0, 0.19, 0.31), (0.0, 0.28, 0.39), (0.0, 0.39, 0.42),
           (0.0, 0.44, 0.42)]
    rad = [0.085, 0.072, 0.060, 0.050, 0.043, 0.038]
    bones = ["tail1", "tail1", "tail2", "tail3", "tail3"]
    for shape, bone in zip(S.chain(pts, rad), bones):
        parts.append(S.Part(shape, bone, "skin", 0.03, "tail"))

    decals = []
    # Belly: a cream oval on the front of the body.
    decals.append(S.Decal(S.ellipsoid((0.0, 0.27, -0.14), (0.12, 0.15, 0.12)), "belly", "belly"))
    # Tail underside, cream too.
    decals.append(S.Decal(S.ellipsoid((0.0, 0.11, 0.24), (0.06, 0.07, 0.12)), "belly", "tail_belly"))
    # Muzzle underside and jaw, lighter.
    decals.append(S.Decal(S.ellipsoid((0.0, 0.445, -0.10), (0.10, 0.045, 0.10)), "belly", "chin"))
    # Eyes: tall ovals, set wide on the upper face; a blue iris low in the eye and a big white catch light high.
    for s in (1, -1):
        ex, ey, ez = 0.094 * s, 0.615, -0.16
        dz = 0.09
        decals.append(S.Decal(S.ellipsoid((ex, ey, ez), (0.046, 0.066, dz)), "eye", "eye"))
        decals.append(S.Decal(S.ellipsoid((ex - 0.003 * s, ey - 0.03, ez), (0.035, 0.032, dz)), "iris", "iris"))
        decals.append(S.Decal(S.ellipsoid((ex - 0.003 * s, ey - 0.044, ez), (0.024, 0.016, dz)), "iris_light",
                              "iris_light"))
        decals.append(S.Decal(S.ellipsoid((ex + 0.014 * s, ey + 0.026, ez), (0.018, 0.022, dz)), "eye_white",
                              "glint"))
        decals.append(S.Decal(S.ellipsoid((ex - 0.016 * s, ey - 0.012, ez), (0.009, 0.009, dz)), "eye_white",
                              "glint2"))
        # Nostrils.
        decals.append(S.Decal(S.ellipsoid((0.032 * s, 0.555, -0.26), (0.009, 0.006, 0.04)), "nostril", "nostril"))

    def smile(p):
        """A curved mouth line along the side of the muzzle: rises toward the cheeks."""
        x = p[:, 0]
        curve = 0.468 + 1.6 * x * x
        return np.maximum(np.abs(p[:, 1] - curve) - 0.0045, np.maximum(np.abs(x) - 0.12, p[:, 2] + 0.06))
    decals.append(S.Decal(smile, "mouth", "mouth"))
    return S.Sculpt(parts, decals, PALETTE, BONES, LOCATORS, pose=pose)


# ---------------------------------------------------------------- animation

def _q(axis, deg):
    a = math.radians(deg) / 2.0
    s = math.sin(a)
    return (axis[0] * s, axis[1] * s, axis[2] * s, math.cos(a))


def _qmul(p, q):
    px, py, pz, pw = p
    qx, qy, qz, qw = q
    return (pw * qx + px * qw + py * qz - pz * qy, pw * qy - px * qz + py * qw + pz * qx,
            pw * qz + px * qy - py * qx + pz * qw, pw * qw - px * qx - py * qy - pz * qz)


def euler(x=0.0, y=0.0, z=0.0):
    """Degrees about x (pitch: + tips the front down... see below), y (yaw) and z (roll), applied z, y, x."""
    return _qmul(_qmul(_q((1, 0, 0), x), _q((0, 1, 0), y)), _q((0, 0, 1), z))


# The six clips share the frame ranges of the converted models (stand 0-20, walk 21-41, run 42-52, punch 53-63,
# die 64-74, sit 75-85). pose(clip, u) returns {bone: (quat, (dx, dy, dz))}: a rotation about the bone's pivot and
# a pivot offset, both relative to the rest pose. Rotation about +x lifts the front (-z) up: a positive x rotation of
# the head looks up; of a leg swings the foot forward (-z) up... in this rig a positive x swings the foot backward.
def pose(clip, u):
    t = 2 * math.pi * u
    P = {}
    if clip == "stand":
        breath = math.sin(t)
        P["spine"] = (euler(x=1.5 * breath), (0.0, 0.004 * breath, 0.0))
        P["head"] = (euler(x=-2.5 * breath, z=2.0 * math.sin(t + 1.0)), (0.0, 0.0, 0.0))
        P["arm_l"] = (euler(z=4 + 3 * breath), (0, 0, 0))
        P["arm_r"] = (euler(z=-4 - 3 * breath), (0, 0, 0))
        P["tail1"] = (euler(y=6 * math.sin(t)), (0, 0, 0))
        P["tail2"] = (euler(y=7 * math.sin(t - 0.6)), (0, 0, 0))
        P["tail3"] = (euler(y=8 * math.sin(t - 1.2), x=3 * breath), (0, 0, 0))
    elif clip in ("walk", "run"):
        amp = 1.0 if clip == "walk" else 1.5
        sw = math.sin(t)
        bob = abs(math.sin(t))
        P["root"] = (euler(x=-6 * (amp - 1) * 2), (0.0, 0.018 * amp * bob, 0.0))
        P["hips"] = (euler(y=5 * sw * amp, z=3 * sw), (0, 0, 0))
        P["leg_l"] = (euler(x=28 * amp * sw), (0, 0, 0))
        P["leg_r"] = (euler(x=-28 * amp * sw), (0, 0, 0))
        P["arm_l"] = (euler(x=-22 * amp * sw, z=6), (0, 0, 0))
        P["arm_r"] = (euler(x=22 * amp * sw, z=-6), (0, 0, 0))
        P["spine"] = (euler(y=-4 * sw * amp), (0, 0, 0))
        P["head"] = (euler(x=3 * math.cos(2 * t), y=3 * sw), (0, 0, 0))
        P["tail1"] = (euler(y=-12 * sw * amp), (0, 0, 0))
        P["tail2"] = (euler(y=-10 * math.sin(t - 0.7) * amp), (0, 0, 0))
        P["tail3"] = (euler(y=-10 * math.sin(t - 1.4) * amp), (0, 0, 0))
    elif clip == "punch":
        # Wind up (0-0.35): rear back; strike (0.35-0.55): lunge, arms and head forward; recover.
        if u < 0.35:
            k = u / 0.35
            lean, arms, push = -14 * k, -30 * k, -0.01 * k
        elif u < 0.55:
            k = (u - 0.35) / 0.2
            lean, arms, push = -14 + 34 * k, -30 + 100 * k, -0.01 - 0.05 * k
        else:
            k = (u - 0.55) / 0.45
            lean, arms, push = 20 * (1 - k), 70 * (1 - k), -0.06 * (1 - k)
        P["root"] = (euler(), (0.0, 0.0, push))
        P["spine"] = (euler(x=-lean), (0, 0, 0))
        P["head"] = (euler(x=-lean * 0.5), (0, 0, 0))
        P["arm_l"] = (euler(x=-arms), (0, 0, 0))
        P["arm_r"] = (euler(x=-arms), (0, 0, 0))
        P["tail1"] = (euler(x=lean * 0.6), (0, 0, 0))
    elif clip == "die":
        k = 0.5 - 0.5 * math.cos(math.pi * min(u * 1.3, 1.0))
        P["root"] = (euler(z=88 * k), (0.0, 0.10 * k, 0.0))
        P["head"] = (euler(x=-15 * k), (0, 0, 0))
        P["arm_l"] = (euler(z=30 * k), (0, 0, 0))
        P["arm_r"] = (euler(z=-30 * k), (0, 0, 0))
        P["tail1"] = (euler(y=25 * k), (0, 0, 0))
    elif clip == "sit":
        k = 0.5 - 0.5 * math.cos(math.pi * min(u * 1.6, 1.0))
        P["hips"] = (euler(x=8 * k), (0.0, -0.07 * k, 0.0))
        P["leg_l"] = (euler(x=-70 * k, z=-8 * k), (0, 0.0, 0))
        P["leg_r"] = (euler(x=-70 * k, z=8 * k), (0, 0.0, 0))
        P["spine"] = (euler(x=-6 * k), (0, 0, 0))
        P["head"] = (euler(x=-14 * k, z=6 * k), (0, 0, 0))
        P["tail1"] = (euler(y=40 * k, x=12 * k), (0, 0, 0))
        P["tail2"] = (euler(y=25 * k), (0, 0, 0))
    return P
