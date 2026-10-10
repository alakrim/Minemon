# PLAN (v2, after the pivot D-022; the Godot plan is archived on branch `godot-prototype`)

## Project brief (approved goals, unchanged)
A private Pokémon game in a Minecraft world for the owner and one friend. It should be hard, alive and scary, with Kanto + Johto Pokémon, missions in Kanto + Johto towns, eldritch giants, and look beautiful while running on an AMD Vega 8 with 6 GB RAM.

**Rules:**
- Defeat a wild Pokémon before catching it.
- Ball type changes the catch rate.
- Levels come from battles and bonding.
- Species are aggressive or peaceful.
- Wild Pokémon attack the player when no Pokémon of theirs is out.
- 3 lives; the 4th death is permanent.

## Approach (D-022, D-023)
Base + layer:
1. **Base (installed by the owner in the Modrinth App):** Minecraft Java 1.21.1, Fabric, the Cobblemon Official Modpack (Cobblemon 1.8.1 plus a performance stack).
2. **Adventure world:** the "Cobblemon Johto" map (CurseForge, JondGames). It has Johto towns, gyms, the Elite Four and Team Rocket, with Kanto gyms post-game. The owner downloads it (All Rights Reserved, private use).
3. **Extra mods (owner installs from Modrinth):** Cobblemon Fight or Flight Reborn (aggression), Server-Side Horror (eerie events). Further add-ons only after compatibility checks on 1.8.1.
4. **Beauty:** Iris plus the Complementary Reimagined shaders (Potato/Low profile first), Better Leaves, and our own atmosphere tweaks (biome fog colours and ambient sounds).
5. **The Minemon layer (our work, text only; built by Haiku workers):**
   - `layer/datapack/minemon/`: functions, spawn pools, Cobblemon NPC/dialogue JSON, advancements, predicates;
   - `layer/config/`: config overrides for Cobblemon and the add-ons;
   - `layer/resourcepack/minemon/`: language, sounds and texture tweaks (never Pokémon art).

   It is installed into the owner's world or instance folder by Opus through the linked PC (device file tools), or by the owner from a zip.

## Validation (cloud, no Minecraft available)
`scripts/check.sh` runs:
- JSON parsing of every .json;
- `mecha -m 1.21` on every .mcfunction;
- nbtlib on .snbt;
- `tools/validate_layer.py`: schema checks for our own files against reference samples taken from the real Cobblemon 1.8.1 jar on the owner's PC (`reference/`), pack.mcmeta `pack_format` 48, namespace and path rules, and that every function and tag referenced exists.

Then an in-game test checklist per milestone that the owner (or Opus via computer use) runs.

## Invariants
1. We never ship or create Pokémon art, models or sounds, nor any third-party jars or assets without a redistribution licence. The owner installs mods through the launcher.
2. Everything we author is text in `layer/` and passes check.sh.
3. All gameplay rules are per-player and multiplayer-safe (the owner plus a friend).
4. The layer never edits the adventure map's own files. It adds a datapack and configs only, so it can be removed cleanly.
5. Performance: no feature may add per-tick work that scans all entities every tick. Use schedules (every 10–20 ticks) and limited selectors (distance, limit).

## Milestones
| M | Result the owner can play | Acceptance |
|---|---|---|
| M0' | Base installed on the owner's PC (pack, Johto world, shaders, 3 GB RAM); repo restructured; validator; **lives system** (3 lives, then permadeath) | check.sh green; owner screenshot of the lives HUD; fps ≥ 30 with shaders |
| M1' | **Danger:** aggressive and peaceful species set for dex 1–251 (Fight or Flight config from our temperament data); spawns limited to Kanto + Johto with region level curves; difficulty config (exp, catch); the no-Pokémon-out aggression rule (best feasible approach); capture-after-weakening (mod or rule) | Owner playtest: a Rattata is a real threat |
| M2' | **Dread:** night and cave atmosphere (fog colours, ambient sounds, Server-Side Horror tuning), Alpha/Titan spawns | Owner playtest |
| M3' | **Eldritch giants:** rare titanic encounters (scale, darkness, boss bar, telegraphing, special loot) for Gengar, Onix, Gyarados, Lugia and others | Owner playtest |
| M4' | **Missions:** extra Kanto + Johto town missions via Cobblemon NPCs and dialogues, on top of the map's story | Each mission is completable |
| M5' | Friend multiplayer (shared instance plus e4mc), polish | Two players online |
