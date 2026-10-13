# T-FX2-<group>: signature effects for the most used moves — M2.1 wave 2, risk low

## Goal
Wave 1 gave every type its own look (`recipes/type_<type>.lua`) and 37 moves their own recipe. Most of the 228 moves
still borrow their type's look, so Tackle, Scratch and Body Slam all look alike. The owner wants more skills, more
creativity, and effects that beat Cobblemon's, still cheap on an AMD Vega 8. You write **one recipe per move** in
your list, each with its own idea: a shape or motion that only this move has.

Your group (the launch prompt names it):
- **A — physical hits** (melee_arc unless noted): tackle, scratch, pound, quick_attack, slash, body_slam, headbutt,
  take_down, double_edge, mega_punch, mega_kick, karate_chop, mach_punch, low_kick, double_kick, extreme_speed,
  hyper_fang, horn_attack, fury_swipes, stomp, peck, drill_peck, wing_attack, lick, leech_life, rollout, dig.
- **B — early specials** (archetype from moves.json): water_gun, bubble, bubble_beam, octazooka, crabhammer,
  thunder_shock, spark, zap_cannon, thunder_punch, fire_punch, ice_punch, flame_wheel, sacred_fire, fire_spin,
  confusion, psybeam, dream_eater, gust, absorb, mega_drain, giga_drain, vine_whip, petal_dance, poison_sting, smog,
  sludge, powder_snow, aurora_beam, swift, ancient_power, outrage.
- **C — status and stat moves** (status_cloud / aura): sleep_powder, stun_spore, poison_powder, spore,
  cotton_spore, leech_seed, sing, supersonic, confuse_ray, thunder_wave, leer, growl,
  scary_face, glare, mean_look, sand_attack, smokescreen, string_shot, spider_web, sweet_scent, haze; and auras
  swords_dance, harden, agility, amnesia, barrier, reflect, light_screen, protect, detect, recover, synthesis,
  moonlight, rest, focus_energy, growth, double_team, substitute; weather sunny_day, rain_dance, sandstorm.

## Read first (all of it)
CLAUDE.md, docs/CONVENTIONS.md, **docs/ART_GUIDE.md**, mods/minemon/minemon_fx/lib.lua, recipes/ember.lua (the
reference), recipes/default.lua (every phase and its context `c`), the `type_<type>.lua` of each type in your list,
two or three wave-1 signature recipes (e.g. recipes/thunderbolt.lua, recipes/razor_leaf.lua, recipes/psychic.lua),
mods/minemon/minemon_core/data/moves.json (archetype of each move), mods/minemon/minemon_combat/archetypes.lua
(which phases each archetype plays and the `c` fields it passes), tests/screenshot/art_fx_types.json (shot format).

## Setup (you work in a git worktree)
From your worktree root: `ln -sfn /home/user/Minemon/.tools .tools`, then `bash scripts/assemble_game.sh`.
Captures: `MINEMON_SHOT_EXTRA_MODS="tests/screenshot/minemon_stage" bash scripts/screenshot.sh <shots.json> <out dir
under your worktree>`, then look at every PNG with the Read tool. Never run more than one capture at a time.

## Design rules (from the art director)
- **One idea per move**, readable in half a second from 6 nodes away. Examples: Quick Attack = white afterimage
  streaks along the dash and a sharp star; Body Slam = a ground shock ring and dust skirt (low, flat); Slash = three
  thin crescents in a fan; Water Gun = a pressurised jet of droplets that splashes into foam rings; Thunder Shock =
  one short jagged bolt, not a storm (keep Thunder bigger); Confusion = a pink ripple that wobbles the victim's
  outline (rings at the victim, offset left/right); Sleep Powder = slow blue-white pollen that sinks; Swords Dance =
  blades of light orbiting the user then crossing; Protect = a hex-shell flash round the user; Recover = rising
  green-white motes with a soft glow; Rain Dance = a ring of falling streaks round the user.
- Five beats for damaging moves (ART_GUIDE 2). Status/aura moves: a wind-up, the look itself, an aftermath.
- Moves of one type must still read as that type (use `c.palette`), but differ from the type recipe in shape,
  motion or timing. Weak moves (power <= 40) are small and quick; strong ones (>= 90) are big and slow.
- **Sizes are in nodes and they matter** (M2.1 review): dust and smoke at most 0.7 per particle, leaves and
  feathers at most 0.2, sparks 0.05-0.12; area moves keep their dust low (vertical speed <= 0.3) because the
  trainer's camera is 2-3 nodes behind the user and anything that drifts past it fills the screen. Node particles
  (`node = {...}`) are capped at 0.16 by lib.lua. Flares may be bigger (they live 0.15 s).
- **Never** give an entity a blended (use_texture_alpha) sprite: it hides every particle behind its square. Bodies of
  projectiles are `c.obj:set_properties({ textures = {...} })` with an opaque-centred texture (glow) plus particles.
- Budgets per phase (ART_GUIDE 4) are hard limits. Prefer `F.on(obj, ...)` trails over repeated spawners.
- Reuse the textures in mods/minemon/minemon_fx/textures. A new texture only if a move needs a shape none has:
  add it to `tools/gen_fx_textures_<group lowercase>2.py` (copy the pattern of tools/gen_fx_textures_b.py, sizes 32
  or 64 px: big particles need 64 px, the engine draws them with nearest filtering) and list it in your report.

## Files you may create (and nothing else)
- `mods/minemon/minemon_fx/recipes/<move_id>.lua` for the moves in your list (`minemon.fx.register_move`).
- `tools/gen_fx_textures_<group>2.py` and the textures it writes (only if needed).
- `tests/screenshot/fx2_<group>.json` and `tasks/M2.1/T-FX2-<group>.report.md`.

## Verify
Shots: copy the entries of tests/screenshot/art_fx_types.json (lakeside stage, user 4 or a species that learns the
move, target 1, `repeat_s` 1.1, two shots per move at wait_s 5 and 6). Give each scene its own `at` at least 0.5
apart on x (scenes closer than that are matched to the wrong shot). Look at every shot; iterate until each move is
distinct and clean (no screen-filling particles, no squares). Run `luacheck mods/minemon/minemon_fx` (0 warnings) and
`busted tests/unit` (green).

## Commit
In your worktree: commit your files only, message `M2.1/T-FX2-<group>: <n> signature move effects`. Do not push. Do
not create scheduled routines, triggers or reminders of any kind.

## Report (`tasks/M2.1/T-FX2-<group>.report.md`, max 200 words)
Status, files, one line per move (its idea), the 4 best screenshot paths, issues. If blocked: BLOCKED and one
question.
