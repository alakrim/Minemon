# PLAN v3: Luanti + VoxeLibre + Minemon mods (D-024, D-025)
Earlier plans are superseded: Godot (branch `godot-prototype`) and Cobblemon (D-022/D-023).

## Brief (owner goals, unchanged)
A private Pokémon game in a Minecraft-like world for the owner and one friend.
- **Look and performance:** hard, alive, scary and beautiful; runs on an AMD Vega 8 with 6 GB RAM; Android later.
- **Pokémon:** all 251 Kanto + Johto species, each aggressive or peaceful, fought with real-time combat in the world.
- **Catching and growth:** wild Pokémon must be defeated before capture, balls have different catch rates, and levels come from battling and bonding.
- **Danger:** wild Pokémon attack the player when no Pokémon of theirs is out. 3 lives, then permadeath.
- **World and story:** missions in Kanto + Johto towns; eldritch giants; free, with no purchases.

## Architecture
- **Engine:** Luanti 5.17.0 (client: the official win64 zip; testing: luantiserver built from source in `.tools/`).
- **Base game:** VoxeLibre, pinned to a release tag, cloned into `.tools/voxelibre` and never edited.
- **Our code:** `mods/minemon/` is a modpack (modpack.conf) of small mods, each with its own `mod.conf` and `depends`:
  - `minemon_core`: shared utilities (rng, data loading, logging), species/move data in `minemon_core/data/*.json`, and a public API table `minemon`;
  - `minemon_lives`: 3 lives, then ghost mode;
  - later: `minemon_creatures` (entities via mcl_mobs), `minemon_combat`, `minemon_capture`, `minemon_progress` (exp, levels, bond), `minemon_party` (UI), `minemon_dread`, `minemon_towns`, `minemon_titans`, `minemon_packs` (owner visual packs).
- **Game assembly:** `scripts/assemble_game.sh` writes `.tools/games/minemon/`. It contains game.conf (`title = Minemon`), VoxeLibre's `mods/*`, our `mods/minemon`, and VoxeLibre's menu and settingtypes where needed.
- **Tests:**
  - `tests/unit/*_spec.lua`: busted, pure Lua with mocks of `core`;
  - `tests/integration/<name>/`: a test mod run inside the assembled game by `scripts/run_luanti_test.sh`. It writes `test_result.txt` and calls `core.request_shutdown`.
- **Assets:** `tools/*.py` generate our own stand-in creature models (.glb, our art). Pokémon visuals come only from owner-supplied packs (D-014).

## Invariants
1. VoxeLibre and Luanti sources are never modified. We hook only through public APIs (mcl_mobs, core callbacks, overrides in our own mods).
2. Every gameplay rule is per player and multiplayer-safe. Player state lives in player meta (`minemon:*` keys) or mod storage.
3. No globalstep does unbounded work. Use timers of at least 0.5 s for scans, limit radius and object counts, and keep per-entity on_step cheap.
4. No species-specific or move-specific code; behaviour is driven by data.
5. We never create or fetch Pokémon art, models or sounds. Stand-ins are procedural and our own.
6. `bash scripts/check.sh` passes before every commit: luacheck, busted, and headless integration tests.

## Milestones
| M | Playable result | Acceptance |
|---|---|---|
| M0 | Portable Windows build of Minemon (VoxeLibre world) with the lives system; tooling; all 251 species' data | check.sh green; owner runs it and reports fps (≥30, F5 overlay) |
| M1 | Creatures: Kanto + Johto species spawn by biome with stand-in models, temperaments (aggressive hunt the player when no Pokémon is out), level by distance; real-time fights | Integration tests; owner playtest: a Rattata is dangerous |
| M2 | Capture and growth: balls (catch rates), capture only when defeated, party UI, send out and recall, exp, levels, bond, evolutions, saves | Tests; owner catches and levels a starter |
| M3 | Dread: night and cave atmosphere, fog, ambience, rare scares; graphics presets for the Vega 8 | Owner playtest |
| M4 | Towns and missions: Kanto/Johto towns via VoxeLibre villages placed near canon positions, NPC quests, Pokémon Centers as respawn checkpoints | Each mission completable |
| M5 | Eldritch giants (titans) | Owner playtest |
| M6 | Owner Pokémon visual packs; multiplayer with the friend; Android check | — |
