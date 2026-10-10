# Lessons

- 2026-10-10: Agent definitions in `.claude/agents/` load at session start only. A new definition is not usable in the session that creates it; spawn `general-purpose` with `model: haiku` meanwhile.
- 2026-10-10: Scouts counted tables/sources toward word limits inconsistently; briefs should say "sections only, max N words".
- 2026-10-10: GUT silently drops test scripts that fail to compile; check.sh must scan the GUT log for SCRIPT ERROR/Parse Error. Always include a compile-error adversarial test when verifying test tooling.
