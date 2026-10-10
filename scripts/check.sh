#!/usr/bin/env bash
# Full repo health check. Runs, in order: format check, lint, Godot import, GUT tests.
# Stops on the first failing step and exits non-zero. Exits 0 only after CHECK PASSED.
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT=${GODOT:-.tools/godot}
LOG_DIR=".godot"
GUT_JUNIT_RES="res://.godot/gut_junit.xml"
GUT_JUNIT="$LOG_DIR/gut_junit.xml"

step() {
	echo
	echo "=== $1 ==="
}

# Lint and format set: every .gd file except addons/, .tools/, .godot/ and .git/.
mapfile -t GD_FILES < <(find . \( -path ./addons -o -path ./.tools -o -path ./.godot -o -path ./.git -o -path ./.claude \) -prune -o -name '*.gd' -print | sort)
if [ "${#GD_FILES[@]}" -eq 0 ]; then
	echo "No .gd files found to check"
	exit 1
fi

mkdir -p "$LOG_DIR"

step "(a) format check: gdformat --check (${#GD_FILES[@]} files)"
gdformat --check "${GD_FILES[@]}"

step "(b) lint: gdlint (${#GD_FILES[@]} files)"
gdlint "${GD_FILES[@]}"

[ -x "$GODOT" ] || { echo "FAIL: Godot not found at $GODOT — run scripts/setup.sh"; exit 1; }

step "(c) Godot import: $GODOT --headless --import"
IMPORT_LOG="$LOG_DIR/import.log"
rc=0
"$GODOT" --headless --path . --import >"$IMPORT_LOG" 2>&1 || rc=$?
if [ "$rc" -ne 0 ] || grep -qE 'ERROR:|SCRIPT ERROR' "$IMPORT_LOG"; then
	grep -E 'ERROR|WARNING' "$IMPORT_LOG" || true
	echo "FAIL: Godot import reported errors (exit code $rc, full log: $IMPORT_LOG)"
	exit 1
fi
echo "import OK (full log: $IMPORT_LOG)"

step "(d) tests: GUT"
rm -f "$GUT_JUNIT"
GUT_LOG="$LOG_DIR/gut.log"
rc=0
"$GODOT" --headless --path . -s res://addons/gut/gut_cmdln.gd \
	-gdir=res://tests -ginclude_subdirs \
	-gjunit_xml_file="$GUT_JUNIT_RES" -gexit 2>&1 | tee "$GUT_LOG" || rc=$?
echo "GUT process exit code: $rc"
if [ "$rc" -ne 0 ]; then
	echo "FAIL: GUT process exited with code $rc"
	exit 1
fi
# GUT silently drops test files that fail to compile, so scan its log for compile problems.
BAD_LINES=$(grep -E 'SCRIPT ERROR|Parse Error|Compile Error|Failed to load' "$GUT_LOG" || true)
if [ -n "$BAD_LINES" ]; then
	echo "$BAD_LINES"
	echo "FAIL: GUT log reports script compile or load errors (full log: $GUT_LOG)"
	exit 1
fi
if [ ! -f "$GUT_JUNIT" ]; then
	echo "FAIL: GUT wrote no JUnit file at $GUT_JUNIT"
	exit 1
fi
python3 - "$GUT_JUNIT" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
cases = list(root.iter("testcase"))
failures = sum(1 for c in cases if c.find("failure") is not None)
errors = sum(1 for c in cases if c.find("error") is not None)
total = len(cases)
print(f"tests={total} failures={failures} errors={errors}")
if total == 0:
    print("FAIL: no tests ran")
    sys.exit(1)
if failures + errors > 0:
    print("FAIL: test failures or errors")
    sys.exit(1)
PY

echo
echo "CHECK PASSED"
