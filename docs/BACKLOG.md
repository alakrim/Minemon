# Backlog

- Android port (after PC milestones; see D-001)
- Full design brainstorm (living world, difficulty, dread, missions, move animations) → folded into the Gate 1 brief
- M1: WorldStreamer public `set_block(world_pos, id)` + re-mesh API (T-03 verifier finding)
- M1: WorldStreamer `_closing` is permanent after _exit_tree; re-adding the streamer silently disables it
- Perf candidates if the M0 gate fails: FastNoiseLite created on main thread and read-only in workers; GDExtension mesher; lower view radius
- Fullscreen setting stored but not applied (T-04)
- Data: base_exp values are modern PokeAPI, not Gen 2; Curse typed ghost (no ??? type)
- Perf: ChunkSnapshot.from_raw pads twice per job (default _init pads an all-air array); remove to halve worker padding (T-06 verifier)
- Perf: initial fill to 81 columns took ~13 s on the 2-core container; check on owner's 4-core Ryzen
- Delivery: builds over 30 MB can't go through chat. Make export_windows.sh also produce 25 MB parts plus a JUNTAR-JOIN .bat, and write them to the owner's Downloads\Minemon folder (M0 was split by hand).
- Lives: the stale banner timer can cut a new banner short after rejoin (minemon_lives/init.lua:116-126). Also drop `luacheck: globals minemon` in minemon_lives (T-15 verifier).
- Controls: the inventory key is I in Luanti (E is aux1). Consider remapping to E for Minecraft familiarity after the owner's feedback.
- Stand-ins look too cheerful for the horror tone. Give aggressive species angry brows, slit pupils or glowing eyes at night (T-18 follow-up, M3 dread).
- Creature do_punch skips mcl knockback, crits, tool wear and hunger. Restore knockback and crits for player hits on creatures (T-24 deviation).
- 43 status moves have no effect yet; flinch, confusion, trap, protect, leech seed and similar are ignored (T-23). M2 status pass.
- Combat rng is clock-seeded; tests pin accuracy. Consider a seeded rng per encounter.
- An unexplained 4/60 creature vanish at dedicated_server_step 0.0 (T-21a verifier, not reproduced). Low priority.
