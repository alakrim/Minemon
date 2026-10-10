# Conventions (all workers)

## What we write
- Only text: datapack files (.mcfunction, .json), config files (.json, .toml, .json5), resource pack files (.json, .lang), and Python tools in `tools/`.
- Minecraft 1.21.1, datapack `pack_format` 48, namespace `minemon`. 1.21 folder names are singular: `function/`, `advancement/`, `predicate/`, `loot_table/`, `tags/function/`.
- Cobblemon 1.8.1 formats: copy the structure of the real files in `reference/` (once present). Never invent keys. If reference/ lacks a format you need, say so in your report and mark the item UNVERIFIED.
- Function files: one command per line, `#` comments allowed, no trailing spaces. Use the scoreboard objectives and tags documented in `layer/datapack/minemon/README.md`, and add new ones there.
- Per-tick work: `minemon:tick` must stay cheap. Heavy logic runs on `schedule function ... 10t` or 20t loops, with selectors limited by distance or limit (PLAN invariant 5).
- Multiplayer-safe: every rule works per player (`@s` inside `execute as @a`), never with global flags for player state.
- English for code and comments. Player-facing text uses JSON text components, written in English.

## Tests and checks
- `bash scripts/check.sh` must exit 0 before a task can be BUILT. It covers JSON parsing, `mecha -m 1.21` on all functions, nbtlib on .snbt, and `tools/validate_layer.py`.
- Every brief lists an **in-game test checklist** (exact commands the owner runs and the result to expect). Put it in your report under "In-game checks".

## Files
- Never commit `builds/`, `.tools/` or third-party jars/assets. `reference/` holds extracted text files only (JSON/MoLang) from the owner's installed mods, for format reference.
- Change only the files your brief allows. No git commit or push (Opus commits after verification), except in a worktree when the brief or launch prompt says so.
- Reports: builder `tasks/M<n>/T-<nn>.report.md` (max 120 words), verifier `.verdict.md` (max 100 words). Writing these files is required.
- If your brief is unclear: mark it BLOCKED in your report and ask one specific question.
