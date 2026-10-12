"""Vectorised signed distance primitives (numpy). Points are (N, 3) arrays in nodes; distances are (N,) arrays.

A sculpt is a list of Part objects: each has a shape (one of the functions below, bound with its parameters), the
bone that moves it, a material name and a blend radius k (smooth union with everything before it). Decals paint
materials on the surface without changing the shape (eyes, belly, markings).
"""

import numpy as np


def _len(v):
    return np.sqrt((v * v).sum(axis=-1))


def sphere(c, r):
    c = np.asarray(c, float)
    return lambda p: _len(p - c) - r


def ellipsoid(c, radii):
    """Inigo Quilez's bound for ellipsoids: good near the surface, which is all the mesher and shader need."""
    c = np.asarray(c, float)
    r = np.asarray(radii, float)

    def f(p):
        q = p - c
        k0 = _len(q / r)
        k1 = _len(q / (r * r))
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)
    return f


def box(lo, hi):
    """An axis-aligned box from corner lo to corner hi (used for cuts)."""
    lo = np.asarray(lo, float)
    hi = np.asarray(hi, float)
    c = (lo + hi) / 2
    h = (hi - lo) / 2

    def f(p):
        q = np.abs(p - c) - h
        return _len(np.maximum(q, 0.0)) + np.minimum(q.max(axis=1), 0.0)
    return f


def capsule(a, b, ra, rb=None):
    """A capsule from a to b whose radius goes from ra to rb (a tapered limb, a tail segment, a claw)."""
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    rb = ra if rb is None else rb
    ba = b - a
    bb = float((ba * ba).sum())

    def f(p):
        pa = p - a
        h = np.clip((pa @ ba) / bb, 0.0, 1.0)
        return _len(pa - h[:, None] * ba) - (ra + (rb - ra) * h)
    return f


def chain(points, radii):
    """Several tapered capsules along a polyline (tails, necks): returns a list of shapes."""
    out = []
    for i in range(len(points) - 1):
        out.append(capsule(points[i], points[i + 1], radii[i], radii[i + 1]))
    return out


def smin(a, b, k):
    """Polynomial smooth minimum: the union of two shapes with a fillet of size about k."""
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


class Part:
    def __init__(self, shape, bone, mat, k=0.0, name=""):
        self.shape = shape
        self.bone = bone
        self.mat = mat
        self.k = k
        self.name = name


class Decal:
    """Paints mat on the surface where the region function is <= 0 (a volume that cuts the surface)."""

    def __init__(self, region, mat, name=""):
        self.region = region
        self.mat = mat
        self.name = name


class Sculpt:
    """parts: [Part]; decals: [Decal], later ones on top; palette: {mat: (r, g, b) in 0..1};
    bones: [(name, parent or None, pivot)] in nodes, parents first; locators: {name: (x, y, z)}."""

    def __init__(self, parts, decals, palette, bones, locators, pose=None, cuts=()):
        self.parts = parts
        self.cuts = list(cuts)  # shapes removed from the solid (flat face plates for voxel styles)
        self.decals = decals
        self.palette = palette
        self.bones = bones
        self.locators = locators
        self.pose = pose
        self.bone_index = {b[0]: i for i, b in enumerate(bones)}

    def distances(self, p):
        return np.stack([part.shape(p) for part in self.parts], axis=1)

    def sdf(self, p):
        d = None
        for part in self.parts:
            dp = part.shape(p)
            d = dp if d is None else smin(d, dp, part.k)
        for cut in self.cuts:
            d = np.maximum(d, -cut(p))
        return d

    def normal(self, p, eps=0.002):
        e = np.eye(3) * eps
        n = np.stack([self.sdf(p + e[i]) - self.sdf(p - e[i]) for i in range(3)], axis=1)
        return n / np.maximum(_len(n)[:, None], 1e-9)

    def material(self, p):
        """The material name at each surface point: the nearest part's, then the decals on top."""
        dist = self.distances(p)
        nearest = np.argmin(dist, axis=1)
        mats = np.array([part.mat for part in self.parts], dtype=object)[nearest]
        for decal in self.decals:
            inside = decal.region(p) <= 0
            mats[inside] = decal.mat
        return mats

    def colour(self, p):
        mats = self.material(p)
        return np.array([self.palette[m] for m in mats], float), mats

    def bone_weights(self, p, sharpness=0.018, top=3):
        """Skin weights from part proximity: each part pulls its vertices to its bone; joints blend smoothly.
        Returns (joints (N, 4) int, weights (N, 4) float)."""
        dist = self.distances(p)
        nb = len(self.bones)
        acc = np.zeros((len(p), nb))
        dmin = dist.min(axis=1, keepdims=True)
        w = np.exp(-(dist - dmin) / sharpness)
        for i, part in enumerate(self.parts):
            acc[:, self.bone_index[part.bone]] += w[:, i]
        order = np.argsort(-acc, axis=1)[:, :4]
        wt = np.take_along_axis(acc, order, axis=1)
        wt[:, top:] = 0.0
        wt = wt / np.maximum(wt.sum(axis=1, keepdims=True), 1e-9)
        return order, wt

    def ambient_occlusion(self, p, n, step=0.012, count=5, strength=3.0):
        occ = np.zeros(len(p))
        for i in range(1, count + 1):
            h = step * i
            occ += (h - self.sdf(p + n * h)) / (2.0 ** i)
        return np.clip(1.0 - strength * occ / step, 0.0, 1.0)
