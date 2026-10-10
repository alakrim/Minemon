# PLAN

Status: **draft brief awaiting Gate 1**. Architecture, milestones and acceptance criteria are added in Phase B.

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
1. **Performance:** the slice runs at 30 fps or more (60 is the target) at 720p on the owner's PC (Intel HD, 6 GB RAM), using less than 3 GB of RAM.
2. **Completeness:** the slice can be played end-to-end, from choosing a starter to reaching Viridian Forest.
3. **Data:** all 251 species and their moves load and pass validation tests.
4. **Difficulty:** in owner playtests, a fresh starter against a wild Rattata is a real fight that the player can lose.
5. **Usability:** every milestone produces a Windows .zip that the owner can run without installing anything.

## Constraints
- **Engine:** Godot 4.7, GDScript only, Compatibility renderer. This is pending confirmation in Phase B.
- **Assets:** free assets only (CC0 or compatible), with each licence tracked.
- **Art:** nothing that imitates official Pokémon designs.
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
- **GPU class:** Intel HD 520/620, until the owner reports the exact model.
- **Deadline:** none. Work proceeds milestone by milestone, with an owner playtest at each milestone close.

## Risks and the cheapest test for each
| Risk | Cheapest test |
|---|---|
| Voxel performance on Intel HD graphics | An M0 prototype that measures fps and RAM on the owner's PC |
| Animating moves for 251 species is too big a job | A data-driven library of effect templates. Prototype 5 moves in M1. |
| Stand-in models weaken the horror | Fog, sound, scale, darkness and revealing giants in fragments. Test with one giant in the slice. |
| Haiku struggles with complex systems | Small tasks with tests written first; scale back on failure (protocol C8) |
| Running Godot headless in Linux CI | Install Godot in M0 and run one GUT test with `--headless` |
