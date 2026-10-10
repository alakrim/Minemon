# STATE

- **Phase:** D: M0 close, waiting on the owner's benchmark (the performance gate)
- **Milestone:** M0 built and verified (T-01..T-06 DONE). Not tagged yet.
- **Last session:** 2026-10-10

## Active tasks
- none

## Blockers
- Owner benchmark results from the Vega 8. The build is in the owner's Downloads\\Minemon folder (two parts plus a JUNTAR-JOIN .bat).

## Decisions needed from owner
- none (just run the two benchmark .bat files and send the results)

## Next action
1. Read the owner's benchmark files. Pass = avg ≥ 30 fps and low1 ≥ 20 at radius 4 on either renderer.
2. Pass: record the default-renderer D-entry, tag `m0-done`, update PROGRESS, then plan M1 (combat core) briefs. Fail: try the BACKLOG perf candidates (T-07), and if still failing, reconsider Luanti (D-015).
3. M1 briefs must include: WorldStreamer set_block/re-mesh API, and a fix for `_closing` (BACKLOG).

## Notes
- Workers: spawn `worker` agent type if loaded, else `general-purpose` with model haiku (D-007). Max 3 at once (D-011).
- Repo: github.com/alakrim/Minemon. A cloud session clones it to /home/claude/minemon, then runs `bash scripts/setup.sh`.
- Build the zip with `bash scripts/export_windows.sh` (downloads 1.3 GB of templates on first run).
