# S-hd2d: HD-2D sprite Charmander (art style option C) — M2.1, risk low

## Goal
One of four art-style options the owner will choose from. Pre-render the Charmander sculpt offline, with high-end
lighting, into **directional animated sprites** shown as a billboard in the 3D world (Octopath Traveler "HD-2D"
feel). Nearly free on an AMD Vega 8 GPU. Quality bar: soft key light + cool fill, ambient occlusion, a warm rim
light, a thin dark outline around the silhouette, crisp eyes. Readable at 160 px.

## Read
CLAUDE.md, docs/CONVENTIONS.md, then: tools/sculpt/sdf.py, tools/sculpt/charmander.py, tools/sculpt/preview.py
(its ray marcher is your starting point), tests/screenshot/minemon_stage/init.lua (header comment),
scripts/screenshot.sh (header).

## Facts you need
- `from tools.sculpt import charmander; s = charmander.build()`: `s.sdf(P)`, `s.normal(P)`,
  `s.colour(P) -> (rgb, materials)`, `s.ambient_occlusion(P, N)`, `s.pose(clip, u)` (bone rotations; you may ignore
  posing for this prototype: render the rest pose, plus a 4-frame idle made by bobbing the whole body up/down by
  0.006 nodes and squashing y by 1%). Units: nodes; feet at y=0; the creature faces -z.
- Luanti sprite entities: `visual = "sprite"`, `spritediv = {x = 6, y = FRAMES}`, and
  `obj:set_sprite({x = 0, y = 0}, FRAMES, 0.15, true)` (the last argument `select_x_by_camera`). With it, the
  engine picks the COLUMN from the camera direction: column 0, 1, 2, 3 for the four horizontal directions (each a
  90-degree sector) and columns 4/5 for looking from below/above. Rows are animation frames. Which column shows
  which side of the creature must be found empirically (render 4 different coloured test columns first if needed).
- Billboards always face the camera; a sprite's `visual_size` is in nodes.

## Steps
1. Write `tools/sculpt/render_sprites.py` (CLI: `python3 -m tools.sculpt.render_sprites charmander OUT_DIR
   --size 160`). Perspective-free (orthographic) camera at pitch 10 degrees, for 4 yaws 90 degrees apart (front, its
   left side, back, its right side); columns 4 and 5 = copies of the front. 4 idle frames. Shading: albedo from
   `s.colour`; key light from above-front-left (wrap lighting, soft), a cool sky fill, AO from
   `s.ambient_occlusion`, a warm rim light (fresnel term from the view direction), and a 2 px dark outline
   (#2a140c at 90% alpha) around the silhouette. Supersample 2x and downscale for anti-aliasing; straight alpha.
   Output `OUT_DIR/style_hd2d.png`: 6 columns x 4 rows of size x size cells.
2. Create the test-only mod `.tools/style_lab/minemon_lab_hd2d/` (mod.conf `name = minemon_lab_hd2d`, `textures/`)
   whose init.lua registers `minemon_lab_hd2d:charmander`: visual "sprite", textures {"style_hd2d.png"},
   spritediv {x = 6, y = 4}, visual_size about {x = 1.0, y = 1.0} (tune so Charmander's height is ~0.78 nodes),
   physical false, static_save false, and in on_activate `self.object:set_sprite({x=0,y=0}, 4, 0.18, true)`.
   Copy the PNG into its textures/.
3. Verify in-engine: write `.tools/style_lab/hd2d_shots.json` modelled on tests/screenshot/art_styles.json: a warmup
   shot and two close shots whose scene has no "user" but a "lineup" with one entry
   `{"entity": "minemon_lab_hd2d:charmander", "dx": 0, "y": 0.39, "yaw_deg": 180}` at scene `at` [186, 178.6] and
   [186, 178.61]; the second with yaw_deg 90. cam [0, 0.95, -2.3], pitch -12, time 0.42. Run:
   `bash scripts/assemble_game.sh && MINEMON_SHOT_EXTRA_MODS="tests/screenshot/minemon_stage .tools/style_lab/minemon_lab_hd2d" bash scripts/screenshot.sh .tools/style_lab/hd2d_shots.json .tools/style_lab/hd2d_out`
   Read the images. Fix the column order so yaw 180 shows the face to the camera, the feet touch the ground, and the
   sprite looks crisp and attractive. Re-run until right.

## Out of scope / do not touch
Do not edit any existing file (only create the new ones above). Do not commit. No new dependencies beyond numpy,
Pillow, scipy, scikit-image.

## Acceptance
- render_sprites.py runs in under 3 minutes; PNG 6x4 cells; in-engine shots correct and attractive.
Write `tasks/M2.1/S-hd2d.report.md` (max 120 words: status, files, render time, screenshot paths, issues).
If materially blocked: stop and write BLOCKED with one question in the report.
