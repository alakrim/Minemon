# T-FX-c report (M2.1, group C)

**Status: partial.** Code, textures and shot list are committed. In-engine checks are incomplete (see Issues).

**Files:** `minemon_fx/recipes/`: type_psychic, type_ghost, type_dark, type_dragon, type_fire; signatures psychic,
hypnosis, night_shade, curse, crunch, bite, dragon_rage, twister, flamethrower, fire_blast; status.lua (polished).
Textures: wisp, rune, tendril. Also `tools/gen_fx_textures_c.py`, `tests/screenshot/fx_c.json`.

**Look per type:** psychic = pink rings, rune motes, ground sigil. Ghost = wisps and a subtractive void. Dark =
shadow strands, black smoke, red glints. Dragon = indigo halo, gold sparks, shock rings. Fire = flame comet, rising embers.

**Impact particles (high):** psychic ~45, ghost ~41, dark ~56, dragon ~80, fire ~54.

**Best shots:** `fx_shots/psy_impact.png`, `fx_shots/sig_psychic_impact.png`, `fx_shots/status_burn.png`.

**Issues:**
- Capture timing is unreliable on the shared 4-CPU box; most flight and impact frames missed the effect.
- Rattata is Normal, so ghost moves do nothing to it. Patch shots against Bulbasaur are not yet clean.
- Pursuit missed; no move in moves.json reaches type:ghost projectile or beam.
- No ASSETS_LICENSES.md rows added for the 3 new textures (not in the brief's file list).
- Luacheck 0 warnings; busted 514/0.
