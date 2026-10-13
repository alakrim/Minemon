# T-FX2-C report (group C: status, stat, aura, weather)

**Status: partial, unverified.** Owner paused the project. All 41 recipes exist; luacheck 0 warnings, busted 514/0.

**Files:** `minemon_fx/recipes/<move>.lua` (41), `tools/gen_fx_textures_c2.py`, 8 textures plus `_pm` copies,
`tests/screenshot/fx2_c.json`.

**Ideas (one per move):** sleep_powder sinking pollen; stun_spore jittering grains; poison_powder poured column;
spore bloom; cotton_spore tufts; leech_seed planted seed and vines; sing notes; supersonic wobbling rings; confuse_ray
helix; thunder_wave floor sweep; leer eyes; glare dashed pulses; mean_look converging runes; sand_attack grit arcs;
smokescreen smoke bank; string_shot beaded loops; spider_web web; sweet_scent petals; haze falling mist; growl dash
barks; scary_face starburst; swords_dance blades; harden chips; agility streaks; amnesia stars; barrier plates; reflect
arc; light_screen bars; protect hex shell; detect scan band; recover motes; synthesis rays; moonlight crescent; rest Zs;
focus_energy lines; growth leaves; double_team afterimages; substitute decoy; sunny_day sun; rain_dance drops; sandstorm
swirl.

**In-engine:** status round 1 (before tuning) and aura/weather round, all captured once. Aura/weather shots were off the
meadow (user partly out of frame). Tuning after the first look is not re-shot. Shot list now uses meadow rows.

**Issues:** faint at 5 nodes (sand_attack, string_shot, scary_face, rest, growth, focus_energy). Synthesis blank in one
frame. Detect band was a dark square (replaced, not re-shot). Leer eye placement unverified. Fixed a crash
(`F.TEX.star`). Captures very slow under machine contention.
