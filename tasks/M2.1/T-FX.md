# T-FX-<group>: battle effects for six types — M2.1, risk low

## Goal
The owner wants battle effects that look AAA and beat Cobblemon, while staying cheap on an AMD Vega 8. You give six
move types their own look: a `type:<type>` recipe (every move of that type uses it unless it has its own), plus
**two signature moves per type** with their own recipe. The reference is `mods/minemon/minemon_fx/recipes/ember.lua`
(hand-made by the art director): match its care and layering.

Your group (the launch prompt names it):
- **A**: water, ice, electric, flying, normal, steel
- **B**: grass, bug, poison, ground, rock, fighting
- **C**: psychic, ghost, dark, dragon, fire (type default; Ember keeps its own), plus polish of the five status
  looks in recipes/status.lua (burn, poison, paralysis, sleep, freeze)

## Read first (all of it)
CLAUDE.md, docs/CONVENTIONS.md, **docs/ART_GUIDE.md**, mods/minemon/minemon_fx/lib.lua, recipes/ember.lua,
recipes/default.lua, recipes/status.lua, mods/minemon/minemon_fx/fx_logic.lua (PALETTE), tools/gen_fx_textures.py,
tests/screenshot/minemon_stage/init.lua (header comment), tests/screenshot/art_charmander.json (a working shot list).

## Setup (you work in a git worktree)
Run from your worktree root: `ln -sfn /home/user/Minemon/.tools .tools` (the toolchain and creature pack are there;
never write inside it except your own run folders). Then `bash scripts/assemble_game.sh` (builds .games/ in YOUR
worktree). Captures: `MINEMON_SHOT_EXTRA_MODS="tests/screenshot/minemon_stage" bash scripts/screenshot.sh
<your shots.json> <out dir under your worktree>`, then look at every PNG with the Read tool.

## Design rules (from the art director)
- Each type must be recognisable from its silhouette and motion alone, not only its colour:
  water = droplets, splashes, foam rings, falling with gravity; ice = sharp shards and frost crystals, a cold mist,
  a frost decal; electric = jagged bolt flashes (flipbook bolts), crackling sparks with jitter, a blue-white core;
  flying = wind streaks (streak texture, vertical=false), feathers, a pressure ring; normal = clean white impact
  stars and a shock ring; steel = bright metal sparks that bounce (collision), a ringing white flash, steel-grey
  shards; grass = spinning leaves (texture with animation or several leaf textures in a texpool), pollen motes;
  bug = chitin shards, a buzzing swarm of tiny dots (jitter); poison = bubbling purple goo, dripping blobs with
  gravity, a toxic puddle decal; ground = **node particles of real blocks** (`node = {name = "mcl_core:dirt"}`) and
  dust, a crater decal, a ground ring; rock = node particles of stone/cobble, heavy chunks with gravity and bounce;
  fighting = impact stars, a speed-line burst, a short heavy hit stop (call F.hitstop with 0.12);
  psychic = concentric pink rings, floating runes/glyph motes, a slow pulse; ghost = wisps that drift and fade, a
  violet void (subtractive smoke, blend "sub"), eerie motes; dark = shadow tendrils and black smoke (blend "sub"),
  red glints; dragon = indigo-violet energy with gold sparks, a roaring shock ring; fire (type default) = flames,
  embers, blast, scorch decal (reuse the fire set; keep it distinct from Ember by size and shape).
- Five beats for every damaging move: anticipation (cast at `F.anchor(c.user, "mouth")`), release (launch flash),
  travel (projectile body + `F.on(obj, ...)` trail; or a beam), impact in layers (catch light, burst, ring, debris,
  smoke, a decal that stays for some types, a sound from VoxeLibre's sounds), aftermath.
- Sizes are in nodes. Budgets per phase (ART_GUIDE.md section 4) are hard limits.
- New textures: create `tools/gen_fx_textures_<group lowercase>.py` that imports helpers from tools/gen_fx_textures.py
  (grid, fbm, smoothstep, rgba, white, write via `Image.fromarray(...).save`) and writes
  `mods/minemon/minemon_fx/textures/minemon_fx_<name>.png` for your new textures only. Our own procedural art only.
  Flipbooks are vertical strips; add their frame count and frame size to a local table in your recipe files (do not
  edit lib.lua; pass `animation = {type = "vertical_frames", aspect_w = W, aspect_h = H, length = -1}` inside
  `F.tex` tables yourself, or set `t.animation` after calling `F.tex`).

## Files you may create (and nothing else)
- `mods/minemon/minemon_fx/recipes/type_<type>.lua` for each of your types: `minemon.fx.register_move("type:<type>", R)`
  with at least: cast, launch, projectile (return true), beam, melee, area, impact (aura and cloud may stay default).
- `mods/minemon/minemon_fx/recipes/<move_id>.lua` for two signature moves per type (pick the most iconic from
  moves.json of your types; e.g. thunder, hydro_pump, earthquake, psychic-type confusion...).
- `tools/gen_fx_textures_<group>.py` and the textures it writes.
- Group C only: you may also edit `mods/minemon/minemon_fx/recipes/status.lua`.
- `tests/screenshot/fx_<group>.json` (your shot list) and `tasks/M2.1/T-FX-<group>.report.md`.

## Verify
For every type: shots of the type recipe at four timings (cast, flight or beam, impact, aftermath) and of each
signature move at impact. Use the lakeside stage (scene `at` near [186, 178.x], user species 4 or any species,
target species 19; camera `cam` [0, 1.6, -5.5], pitch -10; time 0.42). Timing: the capture lags by about 0.45 s, so
`show_s = t - 0.45` shows the effect t seconds after its release. Iterate until each type is distinct, readable and
beautiful. Run `luacheck mods/minemon/minemon_fx` (0 warnings) and `busted tests/unit` (green).

## Commit
In your worktree: commit your files only, message `M2.1/T-FX-<group>: <types> battle effects`. Do not push.

## Report (`tasks/M2.1/T-FX-<group>.report.md`, max 150 words)
Status, files, per-type one line of what defines its look, particle counts at impact, the 4 best screenshot paths,
issues. If blocked: write BLOCKED and one question.
