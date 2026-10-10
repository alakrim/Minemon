# PokeCraft (working title)

A private, single-player fan game: Minecraft-style voxel world + Kanto/Johto Pokémon, real-time combat, hard and atmospheric. PC (Windows, low-end) first; Android later from the same codebase.

## Who reads what
- **Opus (orchestrator):** read `docs/PROTOCOL.md`, then `docs/STATE.md`, then the summary in `docs/PROGRESS.md`. Follow the protocol.
- **Workers (Haiku, high effort):** read this file, `docs/CONVENTIONS.md` (once it exists) and your task brief. Follow the brief exactly.

## Key commands
- Full check: `scripts/check.sh` (defined in M0; not yet created)

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
No worker creates art, models, textures or sounds that imitate official Pokémon designs or Nintendo/Game Freak assets. Creatures use neutral stand-in models until the owner supplies assets. Species *data* (names, types, stats, moves) is allowed. Never publish or distribute builds.
