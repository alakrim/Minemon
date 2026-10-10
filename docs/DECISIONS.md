# Decisions (append-only)

## D-001 — PC first, Android later (2026-10-10)
Options: PC first / Android first / both at once. Chosen: PC (Windows) first.
Why: instant run/debug, no touch UI yet, more performance headroom, easier automated testing.
Constraint kept: one engine that exports to Android, input behind abstract actions, scalable UI, mobile-class render budget.
Would change if: the owner decides Android is the only target.

## D-002 — Pokémon fan game, private use only (2026-10-10)
Owner chose Kanto + Johto Pokémon over an original roster.
Consequences: no public distribution (no Steam/Play Store); Claude and workers do not create likenesses of official Pokémon; creatures use neutral stand-in models until the owner supplies art; species data is data-driven ("species packs") so an original pack stays possible.
Would change if: the owner wants to publish (then switch to an original pack).

## D-003 — Real-time action combat in the world (2026-10-10)
Options: real-time in-world / turn-based in-world / turn-based separate screen. Owner chose real-time.
Why it fits: easiest way to make early fights hard and the world scary.
Second-order: needs hit detection, AI behaviour, dodge/stamina; more animation work per move.

## D-004 — Blocky voxel look like Minecraft; no existing assets (2026-10-10)
Assets will come from CC0/permissive packs or simple procedural generation. Licences tracked per asset.

## D-005 — Minimum target PC: Intel HD integrated graphics, 6 GB RAM, Windows x64 (2026-10-10)
Acceptance tests will include a performance budget derived from this (set in Phase B).

## D-006 — Repo lives on GitHub (private); owner's PC pulls it to play (2026-10-10)
Options: folder on owner's PC / GitHub / cloud-only. Chosen: GitHub.
Why: workers run in the cloud workspace, which does not persist between sessions; GitHub lets every session clone and push, and the owner pulls to play locally.
Would change if: the owner has no GitHub account or wants work done directly on the PC.

## D-007 — Workers: Haiku at high effort (2026-10-10)
Mechanism: `.claude/agents/worker.md` with `model: haiku` + `effort: high` (loads at session start); in sessions where it is not loaded, spawn with `model: haiku` from a high-effort parent.
Evidence: smoke test transcript showed `claude-haiku-5-5`, `effort=high`.

## D-008 — World: generated terrain with canon towns/landmarks placed approximately (2026-10-10)
Options: hand-built canon map / hybrid / fully random. Owner chose hybrid; precision not required.

## D-009 — Danger and death (2026-10-10)
Wild Pokémon attack the player only when no Pokémon of the player's is out. Player has 3 lives; the 4th death is permanent. Assumed (owner may override): respawn at last Pokémon Center, lose half money, lives do not regenerate.

## D-010 — Owner has no coding experience (2026-10-10)
Every milestone ships a Windows .zip build (export in the cloud, delivered in chat); the owner needs no Git, editor or install. Playtest instructions must be click-level. Git on the owner's PC is optional.

## D-011 — At most 3 workers in parallel (2026-10-10)
Owner limit to save tokens. Overrides protocol C3 "2–4 builders" and A "2–4 scouts" → max 3. Architecture-critical double-scouting still allowed within the cap.

## D-012 — First playable slice and defaults (2026-10-10)
Slice: Pallet Town, Route 1, Viridian Forest edge, day/night, ~10 species, one starter, combat/catch/level. Single-player only. No deadline. Capture odds shown as a bar. GPU assumed Intel HD 520/620 until reported.

## D-013 — Target GPU is AMD Radeon Vega 8 (supersedes the GPU part of D-005) (2026-10-10)
Owner's PC: AMD Radeon Vega 8 integrated (Ryzen APU), 2 GB dedicated + shared, DirectX 12 FL 12.1, driver from Feb 2021; 6 GB RAM. Supports Vulkan, so Godot's Mobile renderer is a candidate alongside Compatibility; M0 spike measures both.
Would change if: the spike shows driver problems (then: owner updates AMD driver, or Compatibility/ANGLE).

## D-014 — Pokémon visuals come from an owner-supplied asset pack (2026-10-10)
Owner wants real Pokémon visuals for a private game with a friend. Claude and workers do not create or fetch Pokémon art/models (Claude's content policy, not a legal judgement). Instead the engine loads per-species models/sprites/sounds from `packs/<pack>/` by species ID with a documented format; any species without pack assets uses a stand-in. The owner supplies the pack.

## D-015 — Engine: Godot 4.7.2, statically typed GDScript, own voxel world (2026-10-10)
Options: Godot (own voxel) / Luanti game / Minecraft+Cobblemon add-on (see PLAN). Evidence: two independent scouts agreed; Godot 4.7.2 verified running headless in the workspace; Windows export templates downloadable (1.3 GB). C# rejected (Android export). Strongest alternative: Luanti. Would change if: the M0 spike gives under 30 fps at 720p on the Vega 8 with a 4-chunk view radius.

## D-016 — Gameplay model (2026-10-10)
Action-combat model (owner commands their Pokémon's moves 1–4 in real time; the Pokémon follows under its own AI); capture only after a wild Pokémon is defeated (exhausted window); Gen-style formulas; bond = friendship-style; blocks are mineable and placeable; crafting later. Assumed without asking (owner asked for no unnecessary questions).

## D-017 — Architecture revisions after critic review (2026-10-10)
Source: docs/research/CRITIC-architecture.md and CRITIC-briefs-M0.md. Accepted:
- **Chunks:** chunks are 16×128×16 columns, so terrain costs 1 draw call per column (81 at radius 4). Meshing works from immutable snapshots on worker threads and returns packed arrays. The main thread builds meshes; collision is built only within 2 columns of the player.
- **Gen 2 rules:**
  - 17 types (no Fairy);
  - evolution conditions are AND-combined, covering level, item, held item, time of day, bond and stat relation, and trade (replaced by a "link_cable" item in single-player);
  - move category is stored per move but filled by the Gen 2 rule (category follows from type);
  - stat experience is dropped and bond replaces it;
  - the move-effect schema now covers fixed damage, one-hit KO, multi-hit, drain, recoil, recharge, flinch, healing and weather.
- **New contracts:** CreatureInstance, CombatantView, DamageResult, TypeChart, items.json, the save v1 format with migrations, and exp_for_level.
- **Performance gate:** fixed at 720p, radius 4. Pass is an average of at least 30 fps and a 1% low of at least 20 on either renderer; the better renderer becomes the default.
- **Parallel builds:** builders in a parallel wave run in separate git worktrees. T-01 owns all of project.godot (autoloads, InputMap) and main.tscn's structure.
- **Checkpoints:** respawn goes to the last checkpoint; Pokémon Centers become checkpoints in M3.
Rejected or deferred: missions and region formats are defined in M3's briefs (not needed earlier). Pack loading stays in M2, with the runtime-loading APIs now named in the contract.

## D-018 — Record files split; GDScript noise (2026-10-10)
The core records are split into one file per class_name (CONVENTIONS rule) instead of core/records.gd. Terrain noise is GDScript gradient noise rather than FastNoiseLite, so worker threads never touch Resources. Bench after optimisation: about 25 ms per column (headless debug). Would change if the M0 gate fails (see BACKLOG perf candidates).

## D-019 — M0 performance gate PASSED on the owner's Vega 8; Compatibility is the default renderer (2026-10-10)
Evidence: docs/benchmarks/M0_vega8_gl_compatibility_20261010_1810.txt. Average 58.8 fps (vsync-capped), 1% low 20.5 (gate 20), worst frame 52 ms, radius 4, 100 columns peak. Vulkan was not measured; Compatibility stays the default.
Margin on the 1% low is thin: every visual change must keep the low at or above 20 on the owner's PC. M0b also targets better lows.
Gap: `max_static_mb` reads 0 in release builds (Performance.MEMORY_STATIC is debug-only); needs another memory metric.

## D-020 — Owner priority: world beauty. New milestone M0b "Visual pass" before M1 (2026-10-10)
Owner: "We want to make it look nice." Plan:
- textured blocks from an open-licence 16×16 pack, in a single atlas so draw calls stay at 1 per column;
- per-vertex ambient occlusion and smooth lighting;
- cross-quad plants (grass, flowers);
- transparent water and alpha leaves;
- sky gradient with sun and clouds, plus fog tuning.

The performance gate is re-run by the owner afterwards. M1 (combat) follows.

## D-021 — Block art: our own procedural pixel-art atlas, with pack override later (2026-10-10)
The workspace cannot reach kenney.nl, opengameart.org or itch.io (egress policy). The only reachable complete CC0 pack (ProgrammerArt, npm) is crude, saturated "programmer art" (contact sheet reviewed by Opus) and was rejected.
Chosen: a Python tool (`tools/gen_textures.py`, Pillow, dev-time only) generates a cohesive 16×16 atlas from a hand-tuned palette. We own it, so it is licence-free and art-directable (it also suits the horror tone), and it can be regenerated.
The engine must also accept an owner texture pack (16×16 PNGs by block texture name) later via packs/ (M2), so any pack the owner downloads can replace it.
Rejected: ProgrammerArt (ugly); CC BY-SA packs (licence rule; can be reconsidered for private use if the owner supplies one).
Visual review loop: screenshots rendered in the container (Xvfb + gl_compatibility), reviewed by Opus before each owner build.

## D-022 — PIVOT: build on Cobblemon (Minecraft Java) instead of a custom Godot engine (2026-10-10)
Owner request: use existing open work (Cobblemon) for significant shortcuts, with 95% of the work done by Haiku workers. Opus decides on the owner's behalf from now on.
Options considered:
- (a) continue Godot;
- (b) a Fabric/NeoForge Java add-on mod;
- (c) **an existing Cobblemon modpack as the base, plus our "Minemon layer" of datapacks, resource packs, configs, scripts and quests, all text with no compiling.**

Chosen: (c), falling back to (b) only where text cannot do the job.
Evidence:
- the cloud workspace cannot reach Maven, Gradle, Modrinth or Mojang (proxy policy), so compiling Java mods here is impossible;
- text content can be written and statically validated here, and delivered straight into the owner's game folder through the linked PC.

What this gives us for free:
- every Pokémon with models and animations, battles, balls and catch rates, levels and evolutions, move animations;
- a Minecraft world with beautiful shader options;
- multiplayer with the owner's friend.

Consequences:
- Each player needs Minecraft Java Edition.
- Battles become Cobblemon's turn-based in-world battles. Real-time danger stays in the form of wild Pokémon attacking the player when no Pokémon is out (D-009), which supersedes D-003.
- Android goes through Java-launcher apps (unofficial) and drops from guaranteed scope.
- The Godot prototype is archived on branch `godot-prototype`. Godot-specific decisions (D-015..D-021) are superseded, but the Gen 2 data work and the lessons are kept.
Would change if: the base modpack cannot be customised enough with text (then a small Java add-on is built on the owner's PC).

## D-023 — Base stack chosen by Opus on the owner's behalf (2026-10-10)
The stack:
- Modrinth App;
- Minecraft Java 1.21.1, Fabric;
- Cobblemon Official Modpack (Cobblemon 1.8.1; lightest stack, 3 GB RAM);
- the "Cobblemon Johto" adventure world (towns, gyms, story, Kanto post-game), owner-downloaded;
- Fight or Flight Reborn and Server-Side Horror (both MIT);
- Iris with Complementary Reimagined Potato/Low.

Our work is a text-only layer (datapack, configs, resource pack) validated with mecha, json, nbtlib and our own schema checks against real Cobblemon 1.8.1 reference files staged from the owner's PC.
Rejected:
- COBBLEVERSE and CobbleKanto: heavier (6 GB+), All Rights Reserved, and on Cobblemon 1.7.3;
- a generated world plus gym mods: more work, and the Johto map already covers towns, gyms and story.

Approximations accepted:
- Aggression "only when no Pokémon is out" may become "aggressive species attack whoever is nearest" if no text-only gate exists. A Java add-on is reconsidered at M1' close.
- Capture-after-weakening uses an existing mod, or is deferred.

Requirement surfaced to the owner: each player needs Minecraft Java Edition (paid).

## D-024 — PIVOT 2: Luanti (free, open source) replaces Cobblemon/Minecraft (2026-10-10)
Owner: no purchases (no Minecraft); use every shortcut available. Opus decides.
Options:
- Luanti plus an existing Minecraft-like game (Mineclonia or VoxeLibre) plus our Lua mods;
- Minosoft (an open Minecraft client that still needs Mojang assets and a licence: rejected);
- back to Godot (more work).

Chosen: **Luanti 5.14 + a Minecraft-like base game + our "Minemon" Lua mods**.
Why:
- free, with an official Android app (restores the Android goal), built for low-end PCs, with built-in shaders (dynamic shadows, bloom, volumetrics), multiplayer, day/night and weather;
- Lua mods are plain text that Haiku workers can write;
- **the cloud workspace can apt-install build deps and git-clone GitHub**, so we can build a headless `luantiserver` and run real integration tests.

Combat returns to real-time in the world (D-003 restored), using Luanti entities.
Pokémon visuals: still the owner-supplied pack (D-014). We write code that loads the owner's files; we never create or fetch Pokémon art. Stand-ins are our own procedural blocky creatures.
Supersedes D-022/D-023 (the Cobblemon base). Kept from them: the lives design, the temperament data and the layer ideas.
Would change if: the base game cannot be obtained or tested here, or Lua entity performance is too low on the Vega 8.
