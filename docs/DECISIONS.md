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
