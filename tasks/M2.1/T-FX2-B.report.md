# T-FX2-B report: early specials (PARTIAL, unverified)

Status: PARTIAL. All 31 recipes written. luacheck minemon_fx: 0 warnings. busted: 514 successes. Owner paused the project during batch B, so 21 moves were never captured.

In-engine checked (one timed pass, 10 moves): water_gun, bubble, bubble_beam, octazooka, crabhammer, thunder_shock, spark, zap_cannon, thunder_punch, fire_punch. Changes to spark, thunder_shock, thunder_punch and bubble_beam after that pass are not re-verified. The other 21 moves are unverified.

Files: recipes/<move>.lua (31); textures minemon_fx_flame_wheel_anim and minemon_fx_petal (+ _pm); tools/gen_fx_textures_b2.py; tests/screenshot/fx2_b.json (63 shots, repeat mode).

Ideas: water_gun jet + foam crown; bubble soap bubbles, pop; bubble_beam bubble chain; octazooka ink blob, navy splat; crabhammer water geyser; thunder_shock one small bolt; spark round fizz, firecracker pop; zap_cannon collapsing ring, bolt crown; thunder_punch punch star + bolts; fire_punch flame star; ice_punch frost stamp, shards; flame_wheel rolling flame ring, scorch tracks; sacred_fire gold light pillar; fire_spin flame cage; psybeam prism trail; confusion side rings; dream_eater wisps drawn back; gust speed lines; absorb sipped motes; mega_drain leaf line; giga_drain leaf vortex; vine_whip tendril snap; petal_dance petal whirl; poison_sting needle; smog fog bank; sludge goo rope; powder_snow falling crystals; aurora_beam swaying ribbons; swift star shower; ancient_power orbiting rock; outrage crescent fan.

Best screenshots (absolute, in this worktree's fx2_runs/rA): fire_punch_a.png, crabhammer_a.png, bubble_a.png, octazooka_a.png.

Issues:
- Water jet is faint on grass; launch frames show little.
- Spark, thunder_shock, thunder_punch impacts were faint in pass 1 (enlarged, not re-checked).
- bubble_beam shows a pale rectangular patch at aftermath; cause unconfirmed.
- Shot list lacks the two pad scenes needed after server start; first two scenes of a run failed on "no ground".
- Timed captures: show_s 0.0 is effect start. The target's own AI casts purple/green clouds, which add noise.
