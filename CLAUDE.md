# Minemon

A private, free Pokémon game for the owner and one friend: Luanti 5.17.0 + the VoxeLibre game (Minecraft-like) + our Lua mods in `mods/minemon/`. Hard, scary, alive: real-time creature combat, capture after defeat, 3 lives then permadeath, Kanto + Johto towns and missions, eldritch giants. See docs/PLAN.md (v3) and D-024/D-025.

## Who reads what
- **Opus (orchestrator):** docs/PROTOCOL.md, docs/STATE.md, then the docs/PROGRESS.md summary.
- **Workers (Haiku, high effort):** this file, docs/CONVENTIONS.md and your task brief. Follow the brief exactly.

## Key commands
- `bash scripts/setup.sh`: apt deps, builds luantiserver 5.17.0 into `.tools/`, clones VoxeLibre (pinned) into `.tools/voxelibre`, installs luacheck and busted. Idempotent.
- `bash scripts/assemble_game.sh`: builds `.games/minemon` (VoxeLibre plus our mods).
- `bash scripts/check.sh`: luacheck, busted unit tests, headless integration tests.
- `bash scripts/build_windows.sh`: portable Windows build in `builds/`.

## File map
- `mods/minemon/`: our modpack (one folder per mod)
- `tests/unit/`: busted specs; `tests/integration/<name>/`: headless test mods
- `tools/`: Python generators (data, stand-in models)
- `scripts/`: setup, check, assembly, test runner, build
- `docs/`, `tasks/`: project memory (docs/PROTOCOL.md)
- `.tools/` (git-ignored): luantiserver, VoxeLibre clone, assembled game

## Content rule (amended by owner directive D-032, M2.1)
Private, non-commercial use only. We may author our own creature art in any form (code-sculpted models, generated textures, effects) and use any permissively licensed tool or source; Cobblemon (D-029) is one tool among many. Never use assets ripped from official games. The quality bar is "AAA within scope" and every asset must run well on an AMD Vega 8 (docs/ART_GUIDE.md budgets).
