# Progress

## Summary
M0, M1 and M2 delivered. M1 = playable creatures, combat, party, danger, lives, with Cobblemon models. M2.1 (art pass) in progress, paused 2026-10-13.

## Session log
- 2026-10-10: Project set up. Discovery round 1 answered (D-001..D-007). Worker effort verified (Haiku, high). Four scouts dispatched.
- 2026-10-10: Discovery round 2 answered (D-008..D-012). Draft brief in PLAN.md; Gate 1 pending.
- 2026-10-10: GitHub repo alakrim/minemon attached; owner GPU AMD Vega 8 (D-013); visuals via owner-supplied pack (D-014).
- 2026-10-10: Phase B done (D-015..D-017, critics applied). M0 built: T-01..T-06 verified, 144 tests. Windows zip delivered to the owner for the Vega 8 benchmark.
- 2026-10-11: M1 delivered: real Cobblemon models, starters, Party Ball, real-time combat, temperament AI, danger tuning, lives. Package Minemon-M1 (110 MB) in the owner's Downloads.

## M2 (2026-10-11)
Wave 1: T-26 capture, T-27 growth, T-28 Sanctuary (+T-28b fix), W1 cross-mod verifier (93-check loop test). Wave 2: T-29 move command bar, T-30 Dread variants, T-31 status-move pass. check.sh: 15 integration suites green. Build Minemon-M2 delivered.

## M2.1 art pass (2026-10-12 .. 2026-10-13, paused)
- Converter fixes (models were upside down, backwards, inside out); blink and layered fallback clips.
- minemon_fx effects library (D-032): recipes per move/type/default, status looks, hit feel, art profiles, presence
  boost; Ember + Charmander reference by Opus; wave 1 (T-FX-a/b/c): 17 type looks + 34 signature moves.
- Creature style: four Charmander options from one code sculpt; owner chose Micro-Voxel; every Cobblemon species
  converted in that style (tools/sculpt/voxel_cobblemon.py, 12k-triangle budget, paired shiny atlas); pack 676 MB -> 178 MB.
- Eldritch presence for 42 big species (aura, eyes, world darkening).
- Reviews in-engine: oversized dust/leaves fixed; dark squares traced to Luanti's add blend (multiplies by
  framebuffer alpha) and fixed with screen blend on premultiplied textures; stage repeat mode and passive dummy target.
- Wave 2 (T-FX2-a/b/c, Haiku): 99 more signature moves (physical hits, early specials, status/stat/weather); merged
  partly verified. Flame profiles for 6 fire species, Gastly gas, eldritch night tuning, converter hides alternate
  expressions. Unverified items and resume steps: docs/STATE.md "M2.1 status".
