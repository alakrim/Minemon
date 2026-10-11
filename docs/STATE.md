# STATE

- **Phase:** C build loop. **M1 delivered to the owner** (build Minemon-M1 in the owner's Downloads\Minemon-M1). M2 in progress (wave 1).
- **Stack:** Luanti 5.17.0 + VoxeLibre 0.92.3 + mods/minemon; Pokémon models converted from Cobblemon (D-029; generated in .tools, never committed).
- **Last session:** 2026-10-11

## Done in M1
Core API, 251-species data, Cobblemon models and animations (247 species), creature registration and spawning by biome and distance level, runtime hooks (single damage path, exhausted and faint), real-time combat (6 archetypes, statuses), wild brain (temperaments, aggression gate, danger tuning), party (starters, Party Ball, owned brain, HUD), lives.

## Blockers
- none

## Next action
1. M2 wave 1 building: T-26 capture, T-27 growth, T-28 Sanctuary (D-030). Then merge, build, deliver M2a to the owner.
2. M2 wave 2 candidates: manual move choice in combat, status-move pass (BACKLOG), Cobblemon ball models/cries check, evolution polish.
3. Process rule: every wave starts with a Haiku shortcut scout. Max 3 workers.

## Notes
- check.sh: luacheck, busted, Python tests, 9 integration suites (headless luantiserver). Screenshots: scripts/screenshot.sh (real client under Xvfb).
- Build: `bash scripts/build_windows.sh` (MINEMON_VERSION=Mx). Deliver the parts via SendUserFile, then device_commit_files (100 MB per call limit).
