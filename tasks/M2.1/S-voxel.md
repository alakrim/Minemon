# S-voxel: Micro-Voxel Charmander (art style option B) — M2.1, risk low

## Goal
One of four art-style options the owner will choose from. Build the Charmander sculpt as a **micro-voxel** creature:
the smooth sculpt voxelized at a fine grain (about 1/40 node), coloured per voxel with baked ambient occlusion, rigid
per-part animation. Target look: Cube World / Teardown creatures — far more detailed than Minecraft mobs, but clearly
voxel, matching the blocky VoxeLibre world. Must stay cheap on an AMD Vega 8 iGPU: **at most 6000 triangles**, one
texture of at most 512x512.

## Read
CLAUDE.md, docs/CONVENTIONS.md, then: tools/sculpt/sdf.py, tools/sculpt/charmander.py, tools/sculpt/rig.py,
tools/sculpt/preview.py, tests/screenshot/minemon_stage/init.lua (header comment), scripts/screenshot.sh (header).

## Facts you need
- `from tools.sculpt import charmander; s = charmander.build()` gives a Sculpt: `s.sdf(P)`, `s.normal(P)`,
  `s.colour(P) -> (rgb (N,3), material names)`, `s.ambient_occlusion(P, N)`, `s.bone_weights(P)`, `s.bones`,
  `s.locators`, `s.pose(clip, u)`. Units are nodes; feet at y=0; the creature faces -z. Run python as
  `python3 -m tools.sculpt.<module>` from the repo root.
- `tools.sculpt.rig.export_glb(sculpt, positions, normals, uvs, joints, weights, indices, path)` writes an animated
  GLB that Luanti plays with the existing creature code. Triangles must be counter-clockwise seen from outside
  (Luanti culls back faces). joints/weights are (N,4).
- Luanti's glTF loader ignores vertex colours: colour must come from the texture through UVs.

## Steps
1. Write `tools/sculpt/build_voxel.py` (CLI: `python3 -m tools.sculpt.build_voxel charmander OUT_DIR --voxel 0.025`):
   a. Sample `s.sdf` on a grid of cell size `--voxel` (nodes) over the bounding box (x -0.35..0.35, y -0.02..0.82,
      z -0.35..0.55). A cell is solid when sdf(centre) <= 0.
   b. Each solid voxel gets ONE bone: the bone with the highest weight from `s.bone_weights` at its centre.
   c. Emit only exposed faces (neighbour empty). Do not merge faces across different colours or bones. Greedy-merge
      coplanar neighbours with the same colour AND bone to cut triangles (stay under 6000 triangles).
   d. Colour: sample `s.colour` and `s.ambient_occlusion` at the voxel centre pushed onto the surface
      (p - n*sdf(p)); multiply colour by (0.55 + 0.45*ao). Add a per-voxel brightness jitter of +-3% (seeded) so
      large areas are not flat. Faces: top x1.08, sides x1.0, bottom x0.8 (baked sun).
   e. Texture: a palette atlas. Give every distinct (colour, face shade) a 2x2-texel cell; UVs of all 4 corners of
      a face point to the centre of its cell (so nearest filtering shows a flat colour). PNG at most 512x512.
   f. Export with `rig.export_glb` to OUT_DIR/style_voxel.glb and OUT_DIR/style_voxel.png. Per-vertex joints =
      (bone, 0, 0, 0), weights (1, 0, 0, 0). Normals = the face normal.
   g. Print the triangle count and texture size.
2. Create the test-only mod `.tools/style_lab/minemon_lab_voxel/` (mod.conf `name = minemon_lab_voxel`, an empty
   init.lua, `models/`, `textures/`), and copy the two files there.
3. Verify in-engine: write `.tools/style_lab/voxel_shots.json` modelled on tests/screenshot/art_styles.json: a
   warmup shot and two close shots of Charmander (species 4) with `"mesh": "style_voxel.glb", "texture":
   "style_voxel.png"` at scene `at` [186, 178.5] and [186, 178.51], user_yaw_deg 210 and 160, cam [0, 0.95, -2.3],
   pitch -12, time 0.42. Run:
   `bash scripts/assemble_game.sh && MINEMON_SHOT_EXTRA_MODS="tests/screenshot/minemon_stage .tools/style_lab/minemon_lab_voxel" bash scripts/screenshot.sh .tools/style_lab/voxel_shots.json .tools/style_lab/voxel_out`
   Look at the images (Read tool). The creature must be upright, facing the camera at yaw 210, feet on the ground,
   colours right (orange body, cream belly, dark eyes with white glints, white claws). Fix and re-run until so.
4. Also run `python3 -m unittest discover -s tools/tests` (must stay green).

## Out of scope / do not touch
Do not edit any existing file (only create the new ones above). Do not commit. No new dependencies beyond numpy,
Pillow, scipy, scikit-image (already installed).

## Acceptance
- build_voxel.py runs in under 60 s; <= 6000 triangles; texture <= 512x512.
- In-engine shots show a correct, attractive micro-voxel Charmander (paths of the two best PNGs in the report).
Write `tasks/M2.1/S-voxel.report.md` (max 120 words: status, files, triangle count, screenshot paths, issues).
If materially blocked: stop and write BLOCKED with one question in the report.
