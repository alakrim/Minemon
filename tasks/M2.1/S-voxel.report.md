# S-voxel report (M2.1, option B: micro-voxel Charmander)

Status: DONE. Not blocked.

Files: tools/sculpt/build_voxel.py (new); .tools/style_lab/minemon_lab_voxel/; .tools/style_lab/voxel_shots.json; .tools/style_lab/voxel_out/.

Results: 3616 voxels, 4822 triangles (limit 6000), texture 64x64, build 0.4 s. Unit tests: 72 OK. All triangles CCW; signed volume matches voxel count.

Screenshots: /home/user/Minemon/.tools/style_lab/voxel_out/close_voxel_210.png (best), /home/user/Minemon/.tools/style_lab/voxel_out/close_voxel_160.png. Extra: detail_voxel_210.png.

Issues:
- Brief pitch -12 put the creature below the frame (camera is at feet + 0.95 + eye height), so close shots use pitch -36; detail uses -50.
- At cam -2.3 the creature fills about a quarter of frame height.
- Shots rebuilt the shared .games/minemon via assemble_game.sh.
- Stray cloud session created by mistake, then archived.
- No existing file edited; nothing committed.
