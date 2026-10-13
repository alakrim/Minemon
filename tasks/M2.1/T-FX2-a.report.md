# T-FX2-a report (M2.1 wave 2, group A: physical hits)

**Status: partial.** Recipes, textures, shot list and unit/lint checks are done. In-engine review is incomplete (see Issues).

**Files:** `minemon_fx/recipes/<move>.lua` for the 27 moves; `tools/gen_fx_textures_a2.py`; textures `fang`, `arc_wide`, `claw`, `slash_l`, `slash_r` (+ `_pm` copies); `tests/screenshot/fx2_a.json` (four slices, see Issues).

**Ideas:** tackle dust ball; scratch three parallel claws; pound ring that presses in; quick_attack afterimage streaks; slash three-blade fan; body_slam flat dust skirt and ground ring; headbutt orbiting dazed stars; take_down horizontal crack; double_edge gold rebound sparks; mega_punch three ripples; mega_kick low smile arc; karate_chop V chop; mach_punch five-jab stutter; low_kick sliding skids; double_kick two pulses; extreme_speed white lance; hyper_fang fang bite; horn_attack single spike; fury_swipes random flurry; stomp falling dust, delayed splash; peck pinprick and feathers; drill_peck helix; wing_attack feather arc; lick violet tongue, drips; leech_life motes flow back to user; rollout rock and crater; dig dirt fountain, hole at user.

**Checks:** luacheck 0 warnings; busted 514/0.

**Issues:**
- Stage target (wild Bulbasaur) fought back with poison and sleep. I used an uncommitted helper mod outside the repo (species 1 chooses no moves). The stage is unchanged.
- Melee needs d = 2.2 (range 2.5); the art_fx_types d = 5 misses.
- Impact and cast contexts have no `fwd`; five recipes now derive it from the user.
- Later shots: target shows "exhausted" and casts stop; melee and impact frames often missed; slash blades not seen; first shots of a run may load blank.
- Not verified in-engine: sizes (slash blades 2.0 may be large).
- ASSETS_LICENSES.md rows for the five new textures not added (outside brief list).
- Shot file: run each slice (warmup + 16 scenes) as its own run.
