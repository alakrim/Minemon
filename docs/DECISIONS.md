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
