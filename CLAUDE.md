# Minemon

A private, single-player fan game: Minecraft-style voxel world + Kanto/Johto Pokémon, real-time combat, hard and atmospheric. PC (Windows, low-end) first; Android later from the same codebase.

## Who reads what
- **Opus (orchestrator):** read `docs/PROTOCOL.md`, then `docs/STATE.md`, then the summary in `docs/PROGRESS.md`. Follow the protocol.
- **Workers (Haiku, high effort):** read this file, `docs/CONVENTIONS.md` (once it exists) and your task brief. Follow the brief exactly.

## Key commands
- Setup (Godot 4.7.2 headless into `.tools/`, gdtoolkit): `bash scripts/setup.sh`
- Full check (format, lint, Godot import, GUT tests): `bash scripts/check.sh`

## File map
- `docs/STATE.md` — current source of truth (max 30 lines)
- `docs/PLAN.md` — approved brief, architecture, milestones (after Gate 1/2)
- `docs/DECISIONS.md` — append-only decision log
- `docs/PROGRESS.md`, `docs/LESSONS.md`, `docs/BACKLOG.md`
- `docs/research/` — scout digests (max 250 words each)
- `docs/ORIGINAL_BRIEF.md` — the owner's original project request
- `tasks/BOARD.md`, `tasks/M<n>/T-<nn>.md` (+ `.report.md`, `.verdict.md`)
- `.claude/agents/worker.md` — worker definition (model: haiku, effort: high)

## Hard content rule
Workers never create, draw, model or download art, models, textures, sprites or sounds that reproduce official Pokémon designs or Nintendo/Game Freak assets. The game loads creature visuals from an owner-supplied asset pack (`packs/`, see D-014) and falls back to neutral stand-in models. Species *data* (names, types, stats, moves) is allowed. Private use only; never publish builds.
