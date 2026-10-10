# PLAN

Status: **draft brief awaiting Gate 1** (project renamed Minemon). Architecture, milestones and acceptance criteria are added in Phase B.

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
- **Engine:** Godot 4.7, GDScript only; Compatibility or Mobile renderer, chosen by the M0 spike. Pending confirmation in Phase B.
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

## Architecture
Godot 4.7.2, statically typed GDScript, single project at the repo root. Folders:
```
core/      Pure logic, RefCounted only (no Node/scene): rng, stats, damage, catch, exp, typechart, lives
data/      JSON content: species.json, moves.json, types.json, items.json, blocks.json, regions/kanto.json
game/      Autoloads: Data (DataRegistry), Game (GameState+save), Settings, Packs (PackLoader)
world/     BlockRegistry, Chunk, TerrainGenerator, ChunkMesher, WorldStreamer, LandmarkStamper
entities/  Player, Creature, CreatureAI (behaviour state machine), CombatBody, MoveExecutor
vfx/       Move effect templates: projectile, beam, melee_arc, area_burst, aura, status_cloud
ui/        HUD, debug overlay, catch bar, party/menus
tests/     GUT tests: unit/ (core, data, world logic), contract/ (interfaces), smoke/ (scene boots)
scripts/   check.sh, setup.sh, export_windows.sh
addons/gut GUT test framework (vendored; permitted dependency)
```

### Interfaces (contract-tested; changing one = high-risk task + D-entry)
- `Rng` (core/rng.gd): `func _init(seed: int)`, `randf() -> float`, `randi_range(a:int,b:int) -> int`, `fork(tag: String) -> Rng` (deterministic sub-stream).
- `Data` autoload (game/data_registry.gd): `load_all(dir: String = "res://data") -> Array[String]` (returns validation errors, empty = OK), `species(id:int) -> SpeciesData`, `move(id:String) -> MoveData`, `type_multiplier(atk:String, defs:Array[String]) -> float`, `all_species_ids() -> Array[int]`.
- `SpeciesData` / `MoveData` (core/*.gd): typed read-only records built from JSON (fields = data contracts below).
- `Stats` (core/stats.gd): `static func calc(base:Dictionary, level:int, ivs:Dictionary, bond:int) -> Dictionary`.
- `Damage` (core/damage.gd): `static func compute(atk:CombatantView, def:CombatantView, move:MoveData, rng:Rng) -> DamageResult` (amount, crit, effectiveness).
- `Catch` (core/catch.gd): `static func chance(species:SpeciesData, hp_frac:float, ball:String, status:String) -> float` (0..1); `static func roll(chance:float, rng:Rng) -> bool`.
- `Exp` (core/exp.gd): `static func gain(defeated:SpeciesData, level:int, bond:int) -> int`, `static func level_for(total_exp:int, growth:String) -> int`.
- `Lives` (core/lives.gd): `lives_left:int` (starts 3), `on_death() -> String` returning `"respawn"` or `"permadeath"` (4th death).
- `TerrainGenerator` (world/terrain_generator.gd): `func _init(seed:int, region:RegionData)`, `generate(chunk_pos:Vector3i) -> Chunk`.
- `Chunk` (world/chunk.gd): size 16×16×16, `get_block(p:Vector3i) -> int`, `set_block(p:Vector3i, id:int)`; block 0 = air.
- `ChunkMesher` (world/chunk_mesher.gd): `static func build(chunk:Chunk, neighbours:Dictionary, blocks:BlockRegistry) -> ArrayMesh` (hidden faces culled). It must be thread-safe, with no scene access.
- `Packs` autoload (game/pack_loader.gd): `creature_model(dex:int) -> Node3D` (pack .glb or stand-in), `creature_icon(dex:int) -> Texture2D`, `creature_cry(dex:int) -> AudioStream` (may be null). Packs are read at runtime from `<exe dir>/packs/<pack>/<dex 3 digits>.{glb,png,ogg}`, and from `user://packs/` when running in the editor.

### Data contracts (JSON)
- species.json: `[{id:int 1-251, name, types:[1-2], base_stats:{hp,atk,def,spa,spd,spe}, catch_rate:int 3-255, growth_rate:"fast|medium_fast|medium_slow|slow|erratic|fluctuating", base_exp:int, gender_ratio:int -1..8, evolutions:[{to:int, method:"level|item|bond|trade", value}], learnset:[{level:int, move:String}], temperament:"aggressive|territorial|skittish|peaceful", size_class:"tiny|small|medium|large|huge|colossal", body_plan:"biped|quadruped|serpent|avian|blob|insect|fish|other", habitats:[String], eldritch:bool}]`
- moves.json: `{<move_id>: {name, type, category:"physical|special|status", power:int|null, accuracy:int|null, pp:int, archetype:"projectile|beam|melee_arc|area_burst|aura|status_cloud", range_m:float, cast_s:float, cooldown_s:float, effect:{status?, chance?, stat_changes?}}}`
- Our own design fields (temperament, size_class, body_plan, habitats, eldritch, archetype, range_m, cast_s, cooldown_s) are authored by rules and overrides, not taken from PokeAPI.

### Invariants
1. `core/` never references Node, SceneTree, Input or files. It is fully unit-tested headless.
2. All randomness goes through `Rng`, so the same seed gives the same world and the same test outcomes.
3. No species-specific or move-specific code. Behaviour comes from data fields plus archetypes.
4. Gameplay reads input only through InputMap action names; this keeps the Android touch mapping possible.
5. The repo never contains official Pokémon art, models or sounds. `packs/` is git-ignored except its README. Every committed asset has an entry in `ASSETS_LICENSES.md`.
6. Default render budget: Compatibility renderer, fog on, no real-time shadows, view distance set in Settings. Mobile/Vulkan is an option.
7. Save files are versioned JSON in `user://`.
8. `scripts/check.sh` passes on every commit to main.

## Milestones (each ends with something you can run)
| M | Result you can run | Key acceptance |
|---|---|---|
| M0 | Skeleton + world spike: a generated blocky world you can walk/fly in, with an fps/RAM overlay and a 60 s benchmark; Windows .zip | check.sh green; owner reports benchmark on the Vega 8 (≥30 fps at 720p at the default view distance) |
| M1 | Combat core: starter vs wild Rattata/Pidgey (stand-ins), behaviour AI, 4 moves / 3 effect templates, player damage when no Pokémon is out, lives/respawn/permadeath | Unit tests for damage/lives; a scripted fight passes the smoke test; owner plays |
| M2 | Catch and grow: balls + catch bar, party, exp/levels, bonding, save/load, pack loader live | Formula tests; owner drops a pack file and sees it in game |
| M3 | First playable slice: Pallet, Route 1, Viridian Forest edge, day/night, fog + sound dread, ~10 species, 2–3 missions | Owner playtest + tuning pass (Rattata can beat you) |
| M4 | All 251 species + Gen 1–2 moves, every archetype, evolutions | Data validation 100%; every move maps to an archetype |
| M5 | All Kanto towns placed, missions per town, gyms, crafting basics | Each town reachable; mission tests |
| M6 | Johto + eldritch giants (legendary encounters) | Owner playtest |
| M7 | Polish/performance pass; M8 Android port | Perf budget held |
