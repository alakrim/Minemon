#!/usr/bin/env python3
"""Ray-marched preview of a sculpt (M2.1): the quickest way to judge proportions while sculpting.

Usage: python3 -m tools.sculpt.preview charmander OUT.png [--size 320] [--yaws 200,270,160,0]
Each view is a perspective camera orbiting the creature at the given yaw (0 looks at its face from the front).
"""

import argparse
import importlib
import math
import sys

import numpy as np
from PIL import Image


def look_rays(size, yaw_deg, pitch_deg, dist, target, fov_deg=32.0):
    yaw, pitch = math.radians(yaw_deg), math.radians(pitch_deg)
    # yaw 0: the camera sits in front (-z side) of the creature and looks toward +z.
    eye = np.array([math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)]) * dist
    eye = eye + target
    fwd = target - eye
    fwd /= np.linalg.norm(fwd)
    right = np.cross(fwd, [0.0, 1.0, 0.0])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    half = math.tan(math.radians(fov_deg) / 2)
    xs = (np.arange(size) + 0.5) / size * 2 - 1
    gx, gy = np.meshgrid(xs, -xs)
    dirs = fwd[None, None, :] + (gx[..., None] * right + gy[..., None] * up) * half
    dirs = dirs.reshape(-1, 3)
    dirs /= np.linalg.norm(dirs, axis=1, keepdims=True)
    return eye, dirs


def march(sculpt, eye, dirs, max_t=6.0, steps=96):
    t = np.zeros(len(dirs))
    hit = np.zeros(len(dirs), bool)
    alive = np.ones(len(dirs), bool)
    for _ in range(steps):
        idx = np.where(alive)[0]
        if len(idx) == 0:
            break
        p = eye + dirs[idx] * t[idx, None]
        d = sculpt.sdf(p)
        t[idx] += d * 0.9
        done = d < 0.0008
        hit[idx[done]] = True
        alive[idx[done]] = False
        alive[idx[t[idx] > max_t]] = False
    return t, hit


def render(sculpt, size=320, yaw=200, pitch=12, dist=2.2, light=(-0.45, 0.8, -0.4)):
    target = np.array([0.0, 0.36, 0.05])
    eye, dirs = look_rays(size, yaw, pitch, dist, target)
    t, hit = march(sculpt, eye, dirs)
    img = np.zeros((size * size, 3))
    sky = np.array([0.55, 0.72, 0.95])
    img[:] = sky
    idx = np.where(hit)[0]
    p = eye + dirs[idx] * t[idx, None]
    n = sculpt.normal(p)
    col, _mats = sculpt.colour(p)
    L = np.array(light, float)
    L /= np.linalg.norm(L)
    ndl = np.clip(n @ L, 0, 1)
    ao = sculpt.ambient_occlusion(p, n)
    shade = (0.38 + 0.62 * ndl) * (0.55 + 0.45 * ao)
    img[idx] = np.clip(col * shade[:, None], 0, 1)
    return (img.reshape(size, size, 3) * 255).astype(np.uint8)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("species")
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=320)
    ap.add_argument("--yaws", default="200,270,160,0")
    args = ap.parse_args(argv)
    mod = importlib.import_module("tools.sculpt." + args.species)
    sculpt = mod.build()
    views = [render(sculpt, args.size, float(y)) for y in args.yaws.split(",")]
    sheet = np.concatenate(views, axis=1)
    Image.fromarray(sheet).save(args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
