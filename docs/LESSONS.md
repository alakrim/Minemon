# Lessons

- 2026-10-10: Agent definitions in `.claude/agents/` load at session start only. A new definition is not usable in the session that creates it; spawn `general-purpose` with `model: haiku` meanwhile.
- 2026-10-10: Scouts counted tables/sources toward word limits inconsistently; briefs should say "sections only, max N words".
- 2026-10-10: GUT silently drops test scripts that fail to compile; check.sh must scan the GUT log for SCRIPT ERROR/Parse Error. Always include a compile-error adversarial test when verifying test tooling.
- 2026-10-10: Face-count tests could not catch inverted triangle winding; rendering defects need a render or winding test. The verifier's Xvfb render check found it.
- 2026-10-10: Worker-thread tasks bound to Callable(node) lock the Node, so free() is refused. Run jobs on a RefCounted runner.
- 2026-10-10: check.sh must exclude .claude/worktrees/ when parallel worktree builds exist.
- 2026-10-10: Headless benchmarks using engine delta hide spikes; always measure wall-clock (Time.get_ticks_usec). Profile main-thread costs before shipping a perf build.
