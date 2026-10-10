# Conventions (all workers)

## Code
- Godot 4.7.2. GDScript only, **statically typed**: type every variable, parameter and return value (`var x: int`, `-> void`).
- snake_case files and functions, PascalCase `class_name`, UPPER_SNAKE constants. One `class_name` per file.
- Format with `gdformat`; lint with `gdlint` (gdtoolkit 4.x). The settings live in `gdlintrc` at the repo root.
- `core/` holds pure logic (`extends RefCounted`) and must never touch Node, SceneTree, Input or files. This is invariant 1 in PLAN.md.
- All randomness goes through `Rng`. Never call `randi()`/`randf()` directly (invariant 2).
- No code that is specific to one species or one move (invariant 3). Gameplay reads input only through InputMap action names (invariant 4).
- No new addons, plugins or pip packages unless your brief explicitly permits them.

## Tests
- Use GUT. Put tests in `tests/unit/`, `tests/contract/` and `tests/smoke/`, named `test_<thing>.gd`, with each test as `func test_<behaviour>() -> void`.
- Tests must be deterministic: use a fixed `Rng` seed and no wall-clock time.
- Every acceptance criterion in a brief maps to at least one test, or to a stated command whose output is checked.

## Commands
- `scripts/setup.sh`: installs tools (Godot 4.7.2 headless into `.tools/`, gdtoolkit through pip). It is idempotent.
- `scripts/check.sh`: runs, in order, the format check, lint, Godot import, data validation and every GUT test. It must exit 0 before a task can be BUILT.
- The Godot binary path comes from `$GODOT`, which defaults to `.tools/godot`.

## Files and assets
- Never commit `.tools/`, `.godot/`, `builds/` or `packs/*` (except `packs/README.md`).
- Every committed asset needs a line in `ASSETS_LICENSES.md` giving file, source URL, author and licence. Only CC0, CC-BY or OFL licences are allowed.
- Never create, draw, model or download official Pokémon art, models, sprites or sounds.

## Workflow
- Change only the files your brief allows. Run no git commit or push yourself; Opus commits work after it has been verified.
- Builder report: `tasks/M<n>/T-<nn>.report.md`, max 120 words. Verifier verdict: `T-<nn>.verdict.md`, max 100 words. The formats are in docs/PROTOCOL.md section 8.
- If your brief is unclear: set the task to BLOCKED in your report and ask one specific question.
