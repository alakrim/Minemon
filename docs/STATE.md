# STATE

- **Phase:** C build loop. **M1 delivered to the owner** (build Minemon-M1 in the owner's Downloads\Minemon-M1). Next: M2 capture and growth.
- **Stack:** Luanti 5.17.0 + VoxeLibre 0.92.3 + mods/minemon; Pokémon models converted from Cobblemon (D-029; generated in .tools, never committed).
- **Last session:** 2026-10-11

## Done in M1
Core API, 251-species data, Cobblemon models and animations (247 species), creature registration and spawning by biome and distance level, runtime hooks (single damage path, exhausted and faint), real-time combat (6 archetypes, statuses), wild brain (temperaments, aggression gate, danger tuning), party (starters, Party Ball, owned brain, HUD), lives.

## Blockers
- none

## Next action
1. Owner playtest feedback on M1 (fps, danger, feel).
2. M2 (capture and growth). Shortcut scout S-14 is done (docs/research/S-14-m2-shortcuts.md). Write M2 briefs: Poké Balls with catch formula and only-when-exhausted; ball and cry assets via the Cobblemon converter (owner directive covers Cobblemon assets); exp, levels and move learning; evolution (Link Cable item for trade evolutions); Pokémon Center (heal plus respawn checkpoint via mcl_spawn); PC box.
3. Process rule: every wave starts with a Haiku shortcut scout. Max 3 workers.

## Notes
- check.sh: luacheck, busted, Python tests, 9 integration suites (headless luantiserver). Screenshots: scripts/screenshot.sh (real client under Xvfb).
- Build: `bash scripts/build_windows.sh` (MINEMON_VERSION=Mx). Deliver the parts via SendUserFile, then device_commit_files (100 MB per call limit).
