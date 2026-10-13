# STATE

- **Phase:** C build loop. **M2 built** (Windows build Minemon-M2 sent to the owner). **M2.1 art pass in progress, paused by the owner on 2026-10-13** (see "M2.1 status"). Then M3 (dread and atmosphere).
- **Stack:** Luanti 5.17.0 + VoxeLibre 0.92.3 + mods/minemon; Pokémon models converted from Cobblemon (D-029; generated in .tools, never committed).
- **Last session:** 2026-10-13 (M2.1, paused on owner request; everything committed and pushed)

## Done in M1
Core API, 251-species data, Cobblemon models and animations (247 species), creature registration and spawning by biome and distance level, runtime hooks (single damage path, exhausted and faint), real-time combat (6 archetypes, statuses), wild brain (temperaments, aggression gate, danger tuning), party (starters, Party Ball, owned brain, HUD), lives.

## Blockers
- none

## Done in M2
Capture (thrown balls, odds HUD, shakes, break-free enrage), growth (exp, levels, moves, bond, evolution with cinematic, stones, Link Cable), Sanctuaries (altar heal + respawn, ward, PC, shop, coins, potions), move command bar (Z cycles), status-move pass, Dread variants (night eldritch forms, shards, Umbral Ball). D-030, D-031.

## M2.1 status (art pass, D-032; paused 2026-10-13)
Done:
- Creature style chosen by the owner: **Micro-Voxel** (Charmander reference, tools/sculpt/charmander.py). Every
  Cobblemon species is converted into it by tools/sculpt/voxel_cobblemon.py (247 of 251; 243-245 and 251 have no
  Cobblemon model and keep stand-ins). Size rule fx_logic.visual_height. Overrides: tools/sculpt/voxel_overrides.json.
- **minemon_fx** effects library: 17 type recipes + 134 move recipes (35 wave 1 incl. Ember + 27/31/41 wave 2 by T-FX2-a/b/c), of the 228 moves,
  status looks, hit feel, art profiles (Charmander, Charmeleon, Charizard, Magmar, Cyndaquil line, Gastly), eldritch
  presence for 42 big species (aura, glowing eyes from dusk, world darkening near them).
- Review fixes: glows drawn with screen blend on premultiplied textures (no dark squares), presence boost fades for
  big particles, block chips capped, 48-64 px smoke/dust/glow, camera-safe dust, guarded F.after.
Not verified yet (do first on resume):
1. `bash scripts/setup.sh` (the converter changed: GLOBAL_HIDE now hides alternate expressions and held-item
   planes; rebuild takes about 25 min), then `bash scripts/assemble_game.sh`.
2. Shoot tests/screenshot/art_lineup.json and art_eldritch.json (warmup wait_s 30) and review: Gastly (gas profile,
   hidden expression planes), the new flame profiles, eldritch at night (darkness was cut; eyes brighter).
3. Shoot art_fx_types.json and the wave-2 lists (tests/screenshot/fx2_a/b/c.json; add a 30 s warmup and two pad
   scenes first) with the stage's passive dummy target; fix faint effects (worker reports in tasks/M2.1/T-FX2-*.report.md
   list them: e.g. sand_attack, string_shot, scary_face, rest, growth, focus_energy; water_gun faint on grass).
4. Then close M2.1: owner review with screenshots, Windows build.

## Next action
1. Resume M2.1 at "Not verified yet" above (owner decides when).
2. Owner playtest of M2. Owner decision pending: Cobblemon cries/ball sounds/ball models (D-031).
3. M3 (dread and atmosphere: fog, ambience, rare scares, graphics presets). Start with a Haiku shortcut scout. BACKLOG has M2 follow-ups.
4. Max 3 workers; one cross-mod verifier per wave.

## Notes
- check.sh: luacheck, busted, Python tests, 9 integration suites (headless luantiserver). Screenshots: scripts/screenshot.sh (real client under Xvfb).
- Build: `bash scripts/build_windows.sh` (MINEMON_VERSION=Mx). Deliver the parts via SendUserFile, then device_commit_files (100 MB per call limit).
