"""Unit tests for tools/cobblemon_import.py (T-25a). Run: python3 -m unittest discover -s tools/tests"""

import math
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import cobblemon_import as ci  # noqa: E402


def _close(a, b, tol=1e-6):
    return all(abs(x - y) <= tol for x, y in zip(a, b))


def _matrix_from_column_major(m):
    """Row-major 3x4 view of a glTF column-major mat4 (the bottom row is 0 0 0 1)."""
    return [[m[0], m[4], m[8], m[12]],
            [m[1], m[5], m[9], m[13]],
            [m[2], m[6], m[10], m[14]]]


def _apply_column_major(m, p):
    rows = _matrix_from_column_major(m)
    return tuple(rows[r][0] * p[0] + rows[r][1] * p[1] + rows[r][2] * p[2] + rows[r][3] for r in range(3))


# A two-bone geometry: a root cube and a child cube rotated about z, so the inverse bind is not a pure translation.
SYNTHETIC = {
    "description": {"identifier": "geometry.test", "texture_width": 32, "texture_height": 16},
    "bones": [
        {"name": "root", "pivot": [0, 24, 0],
         "cubes": [{"origin": [-2, 24, -2], "size": [4, 8, 4], "uv": [0, 0]}]},
        {"name": "head", "parent": "root", "pivot": [0, 30, 0], "rotation": [0, 0, 30],
         "cubes": [{"origin": [-3, 30, -1], "size": [6, 5, 3], "uv": [16, 0], "inflate": 0.5,
                    "mirror": True}]},
    ],
}


class BoxUvTests(unittest.TestCase):
    def test_box_layout_matches_minecraft_unwrap(self):
        rects = ci.box_uv_rects(0, 0, 4, 8, 4)
        self.assertEqual(rects["east"], (0, 4, 4, 12))
        self.assertEqual(rects["north"], (4, 4, 8, 12))
        self.assertEqual(rects["west"], (8, 4, 12, 12))
        self.assertEqual(rects["south"], (12, 4, 16, 12))
        self.assertEqual(rects["up"], (4, 0, 8, 4))
        self.assertEqual(rects["down"], (8, 0, 12, 4))

    def test_mirror_swaps_u(self):
        rect = (0, 0, 4, 4)
        plain = ci.face_uv_corners(rect, False)
        mirrored = ci.face_uv_corners(rect, True)
        self.assertEqual(plain, [(0, 4), (4, 4), (4, 0), (0, 0)])
        self.assertEqual(mirrored, [(4, 4), (0, 4), (0, 0), (4, 0)])

    def test_per_face_uv_with_negative_size_keeps_order(self):
        cube = {"origin": [0, 0, 0], "size": [4, 4, 4],
                "uv": {"north": {"uv": [4, 4], "uv_size": [-4, 4]}, "up": {"uv": [0, 0], "uv_size": [4, 4]}}}
        faces = {face: rect for face, rect, _m in ci.cube_faces(cube, False)}
        self.assertEqual(faces["north"], (4.0, 4.0, 0.0, 8.0))
        self.assertEqual(faces["up"], (0.0, 0.0, 4.0, 4.0))
        self.assertEqual(set(faces), {"north", "up"})

    def test_bone_mirror_applies_when_cube_does_not_say(self):
        cube = {"origin": [0, 0, 0], "size": [4, 4, 4], "uv": [0, 0]}
        self.assertTrue(all(m for _f, _r, m in ci.cube_faces(cube, True)))
        self.assertFalse(any(m for _f, _r, m in ci.cube_faces(cube, False)))


class BoundsTests(unittest.TestCase):
    def test_inflate_grows_each_side(self):
        lo, hi = ci.cube_bounds({"origin": [0, 0, 0], "size": [4, 8, 4], "inflate": 1})
        self.assertEqual(lo, (-1.0, -1.0, -1.0))
        self.assertEqual(hi, (5.0, 9.0, 5.0))

    def test_negative_size_gives_ordered_bounds(self):
        lo, hi = ci.cube_bounds({"origin": [2, 2, 2], "size": [-4, 4, 4]})
        self.assertEqual(lo, (-2.0, 2.0, 2.0))
        self.assertEqual(hi, (2.0, 6.0, 6.0))


class RotationTests(unittest.TestCase):
    def test_pivot_rotation_about_offset_point(self):
        rot = ci.pivot_rot(ci.q_axis((0, 0, 1), 90), (10.0, 0.0, 0.0))
        out = ci.t_apply(rot, (11.0, 0.0, 0.0))
        self.assertTrue(_close(out, (10.0, 1.0, 0.0), 1e-9))

    def test_euler_order_is_rz_ry_rx(self):
        # Rx(90) takes +y to +z; then Ry(90) takes +z to +x. Applying Ry first would give a different answer.
        out = ci.q_rot(ci.q_euler((90.0, 90.0, 0.0)), (0.0, 1.0, 0.0))
        self.assertTrue(_close(out, (1.0, 0.0, 0.0), 1e-9))

    def test_inverse_transform_undoes_transform(self):
        xf = ci.t_mul(ci.pivot_rot(ci.q_euler((10.0, 20.0, 30.0)), (1.0, 2.0, 3.0)), ((0.0, 0.0, 0.0, 1.0), (5.0, -2.0, 7.0)))
        back = ci.t_mul(ci.t_inv(xf), xf)
        self.assertTrue(_close(back[0], ci.IDENTITY_Q, 1e-9))
        self.assertTrue(_close(back[1], (0.0, 0.0, 0.0), 1e-9))


class ModelTests(unittest.TestCase):
    def setUp(self):
        self.model = ci.build_model(SYNTHETIC)

    def test_lowest_point_sits_at_zero(self):
        lowest = min(p[1] for p in self.model["positions"])
        self.assertAlmostEqual(lowest, 0.0, places=6)

    def test_inverse_bind_is_rigid_and_matches_the_cube_corners(self):
        # Joint-local coordinates are the inverse bind applied to each vertex. Each joint's frame is rigid, so the
        # distances between a joint's vertices in joint space must equal the distances between the same Bedrock
        # cube corners. The expected corners come from the same face order the converter uses.
        expected = []
        for bone_index, bone in enumerate(SYNTHETIC["bones"]):
            for cube in bone.get("cubes", []):
                lo, hi = ci.cube_bounds(cube)
                for face, _rect, _mirror in ci.cube_faces(cube, bool(bone.get("mirror", False))):
                    corners, _normal = ci.face_corners(lo, hi, face)
                    for corner in corners:
                        expected.append((bone_index, corner))
        self.assertEqual(len(expected), len(self.model["positions"]))
        local = []
        for p, j in zip(self.model["positions"], self.model["joints"]):
            glb = tuple(c * ci.SCALE for c in p)
            local.append((j[0], _apply_column_major(self.model["inverse_bind"][j[0]], glb)))
        for joint in (0, 1):
            pts = [(loc, exp[1]) for loc, exp in zip(local, expected) if exp[0] == joint and loc[0] == joint]
            self.assertTrue(pts)
            for a in range(len(pts)):
                for b in range(a + 1, len(pts)):
                    d_joint = math.dist(pts[a][0][1], pts[b][0][1])
                    d_bedrock = math.dist(pts[a][1], pts[b][1])
                    self.assertAlmostEqual(d_joint / ci.SCALE, d_bedrock, places=3)

    def test_every_vertex_is_fully_weighted_to_one_bone(self):
        for w, j in zip(self.model["weights"], self.model["joints"]):
            self.assertEqual(w[0], 1.0)
            self.assertEqual(j[1:], (0, 0, 0))

    def test_indices_form_quads(self):
        self.assertEqual(len(self.model["indices"]) % 6, 0)
        self.assertEqual(len(self.model["positions"]) % 4, 0)

    def test_inflate_grows_the_model(self):
        plain = json_copy(SYNTHETIC)
        plain["bones"][1]["cubes"][0].pop("inflate")
        base = ci.build_model(plain)
        width = lambda m: max(p[0] for p in m["positions"]) - min(p[0] for p in m["positions"])  # noqa: E731
        self.assertGreater(width(self.model), width(base))


def json_copy(data):
    import json
    return json.loads(json.dumps(data))


if __name__ == "__main__":
    unittest.main()
