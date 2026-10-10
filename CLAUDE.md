# Minemon

A private Pokémon adventure in Minecraft for the owner and one friend: Cobblemon (Minecraft Java 1.21.1, Fabric) + the Cobblemon Johto world + our own text-only "Minemon layer" that makes it hard, scary and alive (lives/permadeath, aggression, dread, eldritch giants, missions). See docs/PLAN.md (v2) and D-022/D-023.

## Who reads what
- **Opus (orchestrator):** docs/PROTOCOL.md, then docs/STATE.md, then the docs/PROGRESS.md summary.
- **Workers (Haiku, high effort):** this file, docs/CONVENTIONS.md and your task brief. Follow the brief exactly.

## Key commands
- Setup (pip: mecha, nbtlib): `bash scripts/setup.sh`
- Full check (JSON, mecha, nbtlib, layer validator): `bash scripts/check.sh`
- Package the layer zip: `bash scripts/package_layer.sh` → `builds/minemon-layer.zip`

## File map
- `layer/datapack/minemon/` — our datapack (pack_format 48, namespace `minemon`)
- `layer/config/` — config overrides for Cobblemon and the add-ons
- `layer/resourcepack/minemon/` — language, sounds and texture tweaks (never Pokémon art)
- `reference/` — real files extracted from the owner's installed mods (read-only ground truth for formats)
- `tools/` — validators and generators (Python)
- `data/` — Gen 2 species data from the Godot prototype (temperament etc.), used by generators
- `docs/`, `tasks/` — the protocol memory (see docs/PROTOCOL.md)
- Branch `godot-prototype` — the archived Godot engine (not used)

## Hard content rule
Never create, draw, model or download Pokémon art, models, textures or sounds, and never commit third-party mod jars or assets. The owner installs mods and the map through the launcher. Private use only.
