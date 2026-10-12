# S-hd2d report (M2.1, art option C: HD-2D sprites)

**Status:** done, with one open item (faint speckles in the engine side view, see Issues).

**Files (new only, nothing committed):**
- `/home/user/Minemon/tools/sculpt/render_sprites.py`
- `/home/user/Minemon/.tools/style_lab/hd2d_render/style_hd2d.png` (960x640: 6x4 cells of 160 px)
- `/home/user/Minemon/.tools/style_lab/minemon_lab_hd2d/` (mod.conf, init.lua, textures/)
- `/home/user/Minemon/.tools/style_lab/hd2d_shots.json`, `hd2d_shots_side.json`

**Render time:** 39 s at `--size 160`.

**Screenshots:** `/home/user/Minemon/.tools/style_lab/hd2d_out/` (warmup, hd2d_front, hd2d_side, contact).

**In-game checks:**
- Yaw 180 shows the face to the camera, feet on the grass: pass.
- Yaw 90 shows the left profile, snout to screen left, feet level: pass.
- Columns: 0 right, 1 front, 2 left, 3 back, 4-5 front. Right and back not checked in-engine.

**Issues:**
1. The stage does not clear lab entities between scenes. In the brief's single run the side scene (after front) landed low and lost the front creature, so the side shot is from a warmup-then-side run.
2. Faint dark speckles on the head and back in the engine side view. The source cell is clean; probably engine mip/anisotropic sampling. Unverified.
3. `charmander.py` changed on disk mid-task (not by me). I re-rendered after the change.
4. By mistake I created a Claude Code Remote session (`session_01QT78oYrW5X1Fi9cTjCnfaK`); I archived it.
