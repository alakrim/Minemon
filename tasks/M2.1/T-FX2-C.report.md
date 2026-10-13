# T-FX2-C report (M2.1 wave 2, group C: status, stat, aura, weather)

**Status: partial, unverified.** Owner paused the project; work stopped mid-verification. All 41 recipes exist and
pass luacheck (0 warnings) and busted (514/0). Only a first capture round was reviewed; tuning after it was not re-shot.

**Files:** `mods/minemon/minemon_fx/recipes/<move>.lua` (41), `tools/gen_fx_textures_c2.py`, 8 textures plus `_pm` copies
(eye, hex, note, petal, seed, tuft, web, zed), `tests/screenshot/fx2_c.json`.

**Ideas:** sleep_powder sinking pollen; stun_spore jittering grains; poison_powder poured column; spore bloom;
cotton_spore floating tufts; leech_seed planted seed and vines; sing notes; supersonic wobbling rings; confuse_ray
helix; thunder_wave floor sweep; leer eyes; glare dashed pulses; mean_look converging runes; sand_attack grit arcs;
smokescreen flat smoke bank; string_shot beaded loops; spider_web web sprite; sweet_scent petal drift; haze falling
mist; growl dash barks; scary_face dark starburst; swords_dance orbiting blades; harden chips; agility backward streaks;
amnesia star pops; barrier converging plates; reflect glint arc; light_screen bar grille; protect hex shell; detect scan
band; recover rising motes; synthesis falling rays; moonlight crescent; rest Z letters; focus_energy inward lines;
growth ground leaves; double_team afterimages; substitute spinning decoy; sunny_day sun flare; rain_dance drop ring;
sandstorm swirling grit.

**In-engine checks:** status round 1 (sleep_powder to haze, before tuning), aura and weather round (swords_dance to
sandstorm). Those aura/weather shots were taken off the meadow (x 192-201), so the user is partly out of frame.
Tuning after the first look is unverified. Shot list `fx2_c.json` now uses the meadow rows (z 178.8, 177.8, 176.8).

**Issues:** many effects are faint at 5 nodes (sand_attack, string_shot, scary_face, rest, growth, focus_energy). Synthesis
was blank in one frame. Detect's band was a dark square, now replaced by sparks but not re-shot. Leer eyes placement
unverified. One crash (`F.TEX.star`) found and fixed. Captures were very slow (machine contention).
