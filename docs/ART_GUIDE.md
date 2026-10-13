# Art guide (M2.1, D-032) — for workers

The bar is **AAA within scope, on an AMD Vega 8**. Every visual change is judged in-engine with screenshots, never
from code alone. Read this whole file before any art task.

## 1. Tools you will use
| Tool | What it does |
|---|---|
| `tests/screenshot/minemon_stage` + `scripts/screenshot.sh` | Stages a scene on real terrain (lakeside meadow at x 182-190, z 174-182, seed 1337) and captures it. Shots are JSON (see the stage's header comment): creatures, a move cast on cue (`show_s`), a status, a lineup, mesh/texture overrides, any entity. |
| `tools/gen_fx_textures.py` | Our procedural effect textures (flipbooks, glows, rings, decals). Add a function, run it, look at `--preview`. |
| `tools/sculpt/` | Creatures as code: `sdf.py` primitives, `<species>.py` sculpt (shape, materials, bones, locators, clips), `preview.py` (ray-marched preview in seconds), `rig.py` (skin + clips + GLB), builders (`build_mesh.py`, `build_voxel.py`, `render_sprites.py`). |
| `tools/render_glb.py` | Offline four-view check of any GLB (pose, winding, orientation). Coarse colours: one texel per face. |
| `tools/cobblemon_import.py` | The Cobblemon converter (fallback models, and their locator bones). |

Run a capture: `bash scripts/assemble_game.sh && MINEMON_SHOT_EXTRA_MODS="tests/screenshot/minemon_stage <extra mods>" bash scripts/screenshot.sh <shots.json> <out_dir>`, then Read the PNGs.

Framing that works: camera `cam = [0, -0.62, -1.85]`, pitch -9 for a waist-high creature (the player's eye is 1.47 above
its position). Wild-creature yaw is only reliable below 180 degrees in the stage (use 150 or 115 for 3/4 views).
The capture lags the stage timer by about 0.45 s: to see an effect t seconds after launch, use `show_s = t - 0.45`.

## 2. Effects (minemon_fx)
A move's look is a **recipe**: `mods/minemon/minemon_fx/recipes/<move_id>.lua`, registered with
`minemon.fx.register_move("<move_id>", R)`. Phases (any subset; missing phases fall back to `type:<type>` then
`default`): `cast`, `launch`, `projectile` (return true), `beam`, `melee`, `area`, `aura`, `cloud`, `impact`.
`recipes/ember.lua` is the reference: copy its structure.

Every great effect has the same five beats:
1. **Anticipation** (cast): energy gathers where the move comes from (`F.anchor(user, "mouth")`), the creature's
   art profile reacts (Charmander's flame flares).
2. **Release** (launch): a flash at the muzzle, a burst along the direction.
3. **Travel** (projectile/beam): a body with its own light and a trail left in the world (`F.on(obj, ...)`
   spawners are free while the orb flies: no packets).
4. **Impact** in layers: a white catch light, the type's blast/burst, a shock ring, debris with gravity and
   bounce, smoke that rises, something on the victim, a **mark that stays** (`F.decal`), a sound.
5. **Aftermath**: smoke, embers, a status look. The hit feel (white flash, 80 ms hit stop, floating damage number)
   is added automatically for every damaging hit.

Library (lib.lua): `F.flare`, `F.burst` (radial), `F.smoke`, `F.flames`, `F.embers`, `F.ring`, `F.blast`,
`F.inhale`, `F.on(obj, def)`, `F.decal`, `F.number`, `F.hitstop`, `F.sound`, `F.anchor`, `F.tex`, `F.tint`.
Colours come from `c.palette` (core, main, edge, smoke per type). **Sizes are in nodes.**

Lessons from the in-engine reviews (they are rules now):
- `F.emit` makes particles up to 0.4 nodes 35% larger and lets them live 15% longer (`F.PRESENCE_*`, battles are
  watched from 5-10 nodes); the boost fades out by 0.9 nodes. Block particles (`node = {...}`) are capped at 0.16.
- The engine draws particles with nearest filtering: a big particle shows its texels. Smoke, dust and glow are 48-64
  px; keep dust and smoke at most 0.7 per particle, leaves and feathers at most 0.2.
- The trainer's camera is 2-3 nodes behind the user: area moves keep their dust low (vertical speed <= 0.3), or it
  drifts past the camera and fills the screen.
- Never give an entity a blended sprite (`use_texture_alpha = true` on a sprite near effects): it writes depth over
  its whole square and hides every particle behind it. Art parts are clipped; glow comes from halo particles.
- Glows: write `blend = "add"` as usual; `F.tex` draws it as a screen blend on the texture's premultiplied copy
  (Luanti's own add/sub multiply by the framebuffer alpha, which smoke and water lower: dark squares). After adding
  or regenerating a texture, run `python3 tools/premultiply_fx.py`. Fades on glows become brightness flipbooks.
  `blend = "sub"` becomes a dark alpha smoke.
- Capturing effects: give the scene `repeat_s` (the move is re-cast every repeat_s seconds), so a shot always
  catches it whatever the capture lag. Every shot needs its own scene `at` (closer than 0.004 nodes = same scene).

Textures: neutral (white/grey) ones are tinted with `F.tint`; painted ones (fire) are not. To add one, write a
`tex_<name>` function in tools/gen_fx_textures.py (numpy; deterministic), add it to `TEXTURES`, regenerate, add a
row to ASSETS_LICENSES.md.

## 3. Creature art profiles
`mods/minemon/minemon_fx/art/<species>.lua`, registered with `minemon.fx.register_art("<species>", profile)`.
`art/charmander.lua` is the reference. A profile has `parts` (glowing sprites riding locator bones, each with an
`emit` function for its particles, re-sent every 2 s to nearby players) and event handlers (`cast`).
What deserves a part: anything that glows, burns, sparks, drips or floats in the design (flames, electric cheeks,
glowing eyes at night, gems, ghost wisps). Keep one or two parts per species.

## 4. Performance budget (Vega 8, 30+ fps with 20 creatures on screen)
| Item | Budget at "high" |
|---|---|
| One move phase | cast 80, launch 60, projectile 90/s, impact 160, area 200 particles |
| Creature art part | 1 entity, <= 12 particles/s |
| Status look | <= 30 particles/s |
| Creature mesh | <= 3000 triangles (+ outline copy), one texture <= 512x512 |
| Decals | 16 alive at once (enforced) |
Never add a per-step network update (no `set_properties` or `add_particlespawner` in an on_step without a timer).
Long effects are attached spawners (`F.on`), not repeated calls.

## 5. Creature style: Micro-Voxel (owner's choice, D-032)
Reference: Charmander (`tools/sculpt/charmander.py`, built by `tools/sculpt/build_voxel.py`). Fine voxels (36 per
creature height), baked ambient occlusion, a ±3% colour jitter per voxel, top-lit faces, and **face-detail texels**:
voxel faces that show an eye, mouth or nostril are painted at 6x6 texels, so faces are crisp. Owner feedback that
shaped it: eyes stay on the curved head (no flat face plate); the body is chunky; the face gets extra effort.

How every species is built (`scripts/setup.sh` → `tools/cobblemon_import.py --style microvoxel`):
1. A hand-made sculpt `tools/sculpt/<species>.py` (with `build()` and `H`) wins: it is voxelized exactly like
   Charmander. Write these for the species that matter most (starters, early routes, eldritch giants).
2. Otherwise `tools/sculpt/voxel_cobblemon.py` voxelizes Cobblemon's model in the same style: its cubes, skin,
   skeleton and clips, with **anime eyes repainted** on every eye bone (pupil from the skin's darkest eye colour,
   iris from its most saturated one, two catch lights).
3. Size: `fx_logic.visual_height(height_m)` (mirrored in voxel_cobblemon.visual_height): small creatures read a
   bit larger than life, big ones are compressed, capped at 3.2 nodes; serpents are sized by bulk.

### Reviewing species (worker task)
Shoot lineups (`tests/screenshot/art_lineup.json` is the template: rows of 3-5 species at eye level, yaw 160) and
check each creature: upright, facing forward, feet on the ground, proportions, eyes readable, no stray geometry,
size believable next to the player (1.8 nodes). Fix with `tools/sculpt/voxel_overrides.json` (`hide` bones that are
attack props, `scale`, extra `eye_bones`), then re-run `bash scripts/setup.sh && bash scripts/assemble_game.sh`.
When the conversion cannot be made good, write a hand-made sculpt.

### Sculpting a creature (worker task)
Copy `tools/sculpt/charmander.py`. Keep its structure: PALETTE, BONES (same names as Charmander where the anatomy
matches, so `pose()` can be reused or adapted), LOCATORS (mouth, head, target, middle, eye_left/right, plus
anything an art profile rides), parts (ellipsoids and capsules, smooth-unioned), decals (belly, markings, eyes),
`pose(clip, u)`. Faces: eyes are tall ovals on the curved head with an iris low, an `iris_light` crescent and two
`eye_white` glints, high on the face and wide apart; a thin smile decal; nostrils. Preview with
`python3 -m tools.sculpt.preview <species> out.png`, build with `python3 -m tools.sculpt.build_voxel <species> out/`
and check in-engine through the stage (mesh/texture overrides from a test mod).

## 6. Eldritch creatures
Species with `fx_logic.is_eldritch` (weight >= 80 kg, or the huge and colossal classes; 42 species) carry a
presence (`mods/minemon/minemon_fx/eldritch.lua`): subtractive void smoke and violet motes around the body, eyes
that glow red at night on the model's eye locators, and for players within 14 / 8 nodes the world loses colour and
light (set_lighting, restored when they leave). Tune it there; never make them bigger than the size rule.
