# PLAN

Status: Gate 1 approved 2026-10-10; Phase B in progress (Gate 2 pending). Project name: Minemon.. Architecture, milestones and acceptance criteria are added in Phase B.

## Project brief (draft)
- **Goal:** A private, single-player Pokémon fan game in a blocky voxel world: hard, alive and scary, with real-time combat, all 251 Kanto + Johto species, and missions in every Kanto + Johto town.
- **User:** the owner. No coding experience; plays Windows builds by unzipping and double-clicking. Android later (D-001).
- **Core rules:**
  - Wild Pokémon must be defeated before you can try to catch them.
  - Ball type changes the catch rate, and the odds are shown as a bar.
  - Levels come from battling and from bonding with your Pokémon.
  - Each species is aggressive, skittish or peaceful.
  - Each move has an animation, built from shared effect templates.
  - Wild Pokémon attack the player only when no Pokémon of theirs is out.
  - The player has 3 lives; the 4th death is permanent.
- **World:** generated voxel terrain, with the named towns, routes and landmarks of Kanto/Johto placed roughly where they belong in canon. Everything between them is generated.
- **First playable slice:** Pallet Town, Route 1 and the edge of Viridian Forest, with:
  - day/night,
  - about 10 species,
  - one starter,
  - combat, catching and levelling.

## Success metrics
1. **Performance:** the slice runs at 30 fps or more (60 is the target) at 720p on the owner's PC (AMD Radeon Vega 8, 6 GB RAM; D-013), using less than 3 GB of RAM.
2. **Completeness:** the slice can be played end-to-end, from choosing a starter to reaching Viridian Forest.
3. **Data:** all 251 species and their moves load and pass validation tests.
4. **Difficulty:** in owner playtests, a fresh starter against a wild Rattata is a real fight that the player can lose.
5. **Usability:** every milestone produces a Windows .zip that the owner can run without installing anything.

## Constraints
- **Engine:** Godot 4.7.2, GDScript only (D-015). Default renderer decided by the M0 performance gate.
- **Assets:** free assets only (CC0 or compatible), with each licence tracked.
- **Creature visuals:** loaded per species from an owner-supplied pack in `packs/`; neutral stand-ins otherwise. Workers never create or fetch official Pokémon art (D-014).
- **Workers:** Haiku at high effort only, with at most 3 running at once. No other models.

## Non-goals for v1
- Multiplayer or online play
- Public distribution
- The Android build (planned for later)
- Generation 3 and later species
- An exact copy of the canon map
- Trading

## Assumptions (owner can override)
- **Respawning:** after a death, the player respawns at the last Pokémon Center and loses half their money. Lives never come back.
- **Deadline:** none. Work proceeds milestone by milestone, with an owner playtest at each milestone close.

## Risks and the cheapest test for each
| Risk | Cheapest test |
|---|---|
| Voxel performance on the Vega 8 (old 2021 driver) | An M0 prototype that measures fps and RAM on the owner's PC |
| Animating moves for 251 species is too big a job | A data-driven library of effect templates. Prototype 5 moves in M1. |
| Stand-ins (where no pack asset exists) weaken the horror | Fog, sound, scale, darkness and revealing giants in fragments. Test with one giant in the slice. |
| Haiku struggles with complex systems | Small tasks with tests written first; scale back on failure (protocol C8) |
| Running Godot headless in Linux CI | Install Godot in M0 and run one GUT test with `--headless` |

---
# Phase B — Options, architecture, milestones (Gate 1 approved 2026-10-10)

## Options compared (D-015)
| Option | Value | Effort | Feasibility | Risk |
|---|---|---|---|---|
| A. Godot 4.7 + GDScript, own voxel world (**chosen**) | High: full control of combat, horror, packs; Android export | Medium-high | High: headless tests verified here (4.7.2) | Voxel perf (spike in M0) |
| B. Luanti game in Lua (reuse) | Medium: voxel world for free, Android port exists | Medium | Medium: entity/animation system limits action combat; weak test story | Hitting engine limits mid-project |
| C. Minecraft Java + Cobblemon add-on (reuse/minimal) | Medium: fastest to "something" | Low at first | Low for goals: no Android, Java+mods heavy on 6 GB, little control of horror/combat | Dead end for Android |
Strongest alternative: B. It would win if the M0 spike shows Godot voxel perf is poor on the Vega 8.

## Gameplay model decisions (D-016)
- Real-time combat in the style of Legends: Arceus, but in action form. The player's active Pokémon follows the player under its own AI. The player fires its 4 moves with keys 1–4, aimed at the crosshair target. Moves have cast times, cooldowns and hitboxes. Damage uses a Gen-2-style formula with STAB, type chart, crits and random spread.
- The player can sprint, dodge-roll and throw balls. Wild Pokémon may target the player only while no owned Pokémon is out (D-009).
- Capture: only possible once a wild Pokémon is "defeated" (HP 0 makes it *exhausted*, not fainted, for a short window). Catch chance uses the Gen-style formula (catch rate × ball × status × HP) and is shown as a bar.
- Levels: experience from battles. Bond points come from play/feed/walk and give an exp multiplier and stat bonus, Gen-2 friendship style.
- Blocks are mineable and placeable (Minecraft core). Crafting is minimal and added later (M5+).

## Architecture (revised after critic review, D-017)
Godot 4.7.2, statically typed GDScript, single project at the repo root. Folders:
```
core/      Pure logic, RefCounted only (no Node/scene/files): rng, typechart, stats, damage, catch, exp, lives, creature_instance, records
data/      JSON content: species.json, moves.json, types.json, items.json, blocks.json, regions/ (M3)
game/      Autoloads: Data (DataRegistry), Settings, Game (GameState + save, M1), Packs (PackLoader, M2)
world/     BlockRegistry, Chunk, ChunkSnapshot, TerrainGenerator, ChunkMesher, ChunkMeshData, WorldStreamer, environment.tscn
entities/  Player, Creature, CreatureAI, CombatBody, MoveExecutor
vfx/       Move effect templates: projectile, beam, melee_arc, area_burst, aura, status_cloud
ui/        HUD, debug overlay, catch bar, menus
tests/     GUT: unit/, contract/, smoke/, fixtures/
tools/     Dev scripts that run outside check.sh (benchmarks, data extraction)
scripts/   setup.sh, check.sh, export_windows.sh
addons/gut GUT (vendored, MIT)
```

### Interfaces (contract-tested; changing one = high-risk task + D-entry)
- `Rng` (core/rng.gd): `_init(seed:int)`, `randf()->float`, `randi_range(a:int,b:int)->int`, `fork(tag:String)->Rng` (child seed = `hash(str(seed)+tag)`).
- `TypeChart` (core/typechart.gd): `_init(chart:Dictionary)`, `multiplier(atk:String, defs:Array[String])->float`.
- `SpeciesData`, `MoveData`, `ItemData` (core/records.gd): typed records with `static func from_dict(d:Dictionary)->X`. The fields follow the data contracts below.
- `CombatantView` (core/records.gd): `level:int, stats:Dictionary(hp,atk,def,spa,spd,spe), types:Array[String], status:String, stages:Dictionary(atk..spe, acc, eva: -6..6)`.
- `DamageResult` (core/records.gd): `amount:int, crit:bool, effectiveness:float, missed:bool`.
- `Stats` (core/stats.gd): `static func calc(base:Dictionary, level:int, ivs:Dictionary, bond:int)->Dictionary`. IVs are 0–15 (Gen 2 DVs). Bond 0–255 adds +floor(bond/25)% to each stat. There is no stat experience; bond replaces it (D-017).
- `Damage` (core/damage.gd): `static func compute(atk:CombatantView, def:CombatantView, move:MoveData, chart:TypeChart, rng:Rng)->DamageResult`.
- `Catch` (core/catch.gd): `static func chance(sp:SpeciesData, hp_frac:float, ball_mult:float, status:String)->float`, `static func roll(chance:float, rng:Rng)->bool`.
- `Exp` (core/exp.gd): `static func gain(defeated:SpeciesData, defeated_level:int, bond:int)->int`, `static func exp_for_level(level:int, growth:String)->int`, `static func level_for(total_exp:int, growth:String)->int`.
- `Lives` (core/lives.gd): `lives_left:int=3`, `on_death()->String` returning "respawn" or "permadeath" (4th death). Respawn goes to the last checkpoint. A Pokémon Center is one kind of checkpoint (M3); before M3 the checkpoint is the spawn point.
- `CreatureInstance` (core/creature_instance.gd): `uid:String, species_id:int, nickname:String, level:int, total_exp:int, ivs:Dictionary, bond:int, current_hp:int, status:String, moves:Array (≤4, each {id:String, pp:int}), held_item:String, ball:String, shiny:bool, caught_at:String`. Also `to_dict()->Dictionary` and `static from_dict(d)->CreatureInstance`.
- `Data` autoload (game/data_registry.gd): `load_all(dir:String="res://data")->Array[String]` (validation errors; empty = OK), `species(id:int)->SpeciesData`, `move(id:String)->MoveData`, `item(id:String)->ItemData`, `chart()->TypeChart`, `all_species_ids()->Array[int]`.
- `Chunk` (world/chunk.gd): a **column** of 16×128×16 blocks (D-017). Blocks are stored as a PackedByteArray and block 0 is air. Methods: `_init(pos:Vector2i)`, `get_block(p:Vector3i)->int`, `set_block(p:Vector3i, id:int)`.
- `ChunkSnapshot` (world/chunk_snapshot.gd): an immutable copy of a chunk's blocks plus its 4 neighbours' border slices. Built on the main thread, read on worker threads.
- `ChunkMesher` (world/chunk_mesher.gd): `static func build(snap:ChunkSnapshot, blocks:BlockRegistry)->ChunkMeshData`. It produces packed vertex/normal/colour/index arrays, culls hidden faces, and has no Node or Resource creation, so it is thread-safe.
- `TerrainGenerator` (world/terrain_generator.gd): `_init(seed:int)`, `generate(pos:Vector2i)->Chunk`, `surface_height(x:int, z:int)->int` (deterministic, needs no chunk).
- `WorldStreamer` (world/world_streamer.gd, Node3D): `seed`, `view_radius:int` (columns), `collision_radius:int=2`, `set_focus(pos:Vector3)`, `loaded_count()->int`, `has_collision_at(pos:Vector3)->bool`, `flush()` (blocks until queued jobs finish; for tests and spawn). Generation and meshing run on WorkerThreadPool. The main thread builds the ArrayMesh, plus trimesh collision only for columns within collision_radius. Each column is 1 draw call.
- `Packs` autoload (M2): `creature_model(dex)->Node3D`, `creature_icon(dex)->Texture2D`, `creature_cry(dex)->AudioStream`. Files are loaded at runtime with `GLTFDocument.append_from_file`, `Image.load_from_file` and `AudioStreamOggVorbis.load_from_file` from `<exe dir>/packs/<pack>/<dex:03d>.{glb,png,ogg}` (or `user://packs/` in the editor). If a file is missing, the stand-in is used.

### Data contracts (JSON)
- **types.json:** `{"types":[17 Gen-2 type names, no fairy], "chart":{atk:{def:mult}}}`. Only entries that are not 1.0 are listed.
- **species.json:** `[{id, name, types:[1-2], base_stats:{hp,atk,def,spa,spd,spe}, catch_rate:3-255, growth_rate:"fast|medium_fast|medium_slow|slow|erratic|fluctuating", base_exp, gender_ratio:-1..8, evolutions:[{to:int, conditions:{min_level?, item?, held_item?, time_of_day?:"morning|day|night", min_bond?, stat_relation?:"atk>def|atk<def|atk=def", trade?:true}}], learnset:[{level, move}], temperament:"aggressive|territorial|skittish|peaceful", size_class:"tiny|small|medium|large|huge|colossal", body_plan:"biped|quadruped|serpent|avian|blob|insect|fish|other", habitats:[String], eldritch:bool}]`.
  - All conditions on an evolution must hold at once (AND).
  - In single-player, `trade` is satisfied by using the "link_cable" item (D-017).
- **moves.json:** `{move_id:{name, type, category:"physical|special|status", power:int|null, accuracy:int|null, pp, priority:int, archetype:"projectile|beam|melee_arc|area_burst|aura|status_cloud", range_m, cast_s, cooldown_s, effect:{status?, status_chance?, stat_changes?:[{stat,stages,target:"self|target"}], fixed_damage?:int|"level", ohko?, hits?:[min,max], drain_frac?, recoil_frac?, recharge?, flinch_chance?, high_crit?, heal_frac?, weather?}}}`.
  - `category` is filled in by the Gen 2 rule (it follows from the move's type) when the data is extracted. The engine reads the per-move field (D-017).
- **items.json:** `{item_id:{name, kind:"ball|medicine|evo|held|key", catch_mult?, heal?, price}}`. Balls in M0: poke 1, great 1.5, ultra 2, master 255.
- **blocks.json:** `[{id:0-255, name, color:"#rrggbb", solid, transparent}]`.
- **Save** (`user://save_<slot>.json`, from M1): `{save_version:int, seed, player:{pos, lives_left, money, checkpoint}, party:[CreatureInstance], box:[], inventory:{item:count}, world_edits:{"x,z":{index:block}}, flags:{}, time:float}`.
  - When the save version is older than the current one, `migrate_v<n>` functions run in order.
  - Unknown keys are kept, never deleted.
- Defined in their own milestone's brief: region/landmark format (M3) and missions/dialogue format (M3).

### Invariants
1. `core/` never references Node, SceneTree, Input or files. It is fully unit-tested headless.
2. All randomness goes through `Rng`, so the same seed gives the same world and the same test outcomes.
3. No species-specific or move-specific code. Behaviour comes from data fields plus archetypes.
4. Gameplay reads input only through InputMap action names; this keeps the Android touch mapping possible.
5. The repo never contains official Pokémon art, models or sounds. `packs/` is git-ignored except its README. Every committed asset or vendored code has an entry in `ASSETS_LICENSES.md`.
6. Only the main thread touches the scene tree or creates Resources and Nodes. Worker threads receive snapshots and return packed data.
7. Save files are versioned JSON in `user://`.
8. `scripts/check.sh` passes on every commit to main.

### Performance gate (M0, D-017)
- **Settings:** 1280×720 window, view radius 4 columns (81 draw calls for terrain), fog on, no shadows. The benchmark flies the fixed path for 60 s.
- **Pass:** average fps ≥ 30 and 1% low ≥ 20 on the owner's Vega 8, on at least one renderer.
- **Default renderer:** the renderer with the better result becomes the shipped default (D-entry at M0 close). Until then, Compatibility is the default.

## Milestones (each ends with something you can run)
| M | Result you can run | Key acceptance |
|---|---|---|
| M0 | Skeleton + world spike: a generated blocky world you can walk/fly in, with an fps/RAM overlay and a 60 s benchmark; Windows .zip | check.sh green; owner reports benchmark on the Vega 8 (≥30 fps at 720p at the default view distance) |
| M1 | Combat core: starter vs wild Rattata/Pidgey (stand-ins), behaviour AI, 4 moves / 3 effect templates, player damage when no Pokémon is out, lives/respawn at checkpoint/permadeath, save v1 | Unit tests for damage/lives; a scripted fight passes the smoke test; owner plays |
| M2 | Catch and grow: balls + catch bar, party, exp/levels, bonding, save/load, pack loader live | Formula tests; owner drops a pack file and sees it in game |
| M3 | First playable slice: Pallet, Route 1, Viridian Forest edge, day/night, fog + sound dread, ~10 species, 2–3 missions | Owner playtest + tuning pass (Rattata can beat you) |
| M4 | All 251 species + Gen 1–2 moves, every archetype, evolutions; spawn tables spread species across the slice plus an in-game Pokédex viewer | Validation 100%; values cross-checked against PokeAPI CSV; every move maps to an archetype or appears in docs/unsupported_moves.md |
| M5 | All Kanto towns placed, missions per town, gyms, crafting basics | Each town reachable; mission tests |
| M6 | Johto + eldritch giants (legendary encounters) | Owner playtest |
| M7 | Polish/performance pass; M8 Android port | Perf budget held |
