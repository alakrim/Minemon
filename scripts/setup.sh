#!/usr/bin/env bash
# Installs the dev tools for this repo. Idempotent: a step whose result exists is skipped.
#   - Godot 4.7.2 (headless Linux binary) into .tools/, with .tools/godot as a symlink.
#   - gdtoolkit 4.x (gdformat, gdlint) through pip.
# GUT is vendored in addons/gut and needs no download here.
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT_VERSION="4.7.2-stable"
GODOT_ZIP="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ZIP}"
GODOT_BIN="Godot_v${GODOT_VERSION}_linux.x86_64"
TOOLS_DIR=".tools"

mkdir -p "$TOOLS_DIR"

if [ -x "$TOOLS_DIR/$GODOT_BIN" ]; then
	echo "[setup] Godot ${GODOT_VERSION} already present, skipping download"
else
	echo "[setup] Downloading Godot ${GODOT_VERSION}"
	curl -fL --retry 3 -o "$TOOLS_DIR/$GODOT_ZIP" "$GODOT_URL"
	unzip -q -o "$TOOLS_DIR/$GODOT_ZIP" -d "$TOOLS_DIR"
	rm -f "$TOOLS_DIR/$GODOT_ZIP"
	chmod +x "$TOOLS_DIR/$GODOT_BIN"
fi

if [ "$(readlink "$TOOLS_DIR/godot" 2>/dev/null || true)" = "$GODOT_BIN" ]; then
	echo "[setup] .tools/godot symlink already set"
else
	ln -sfn "$GODOT_BIN" "$TOOLS_DIR/godot"
	echo "[setup] linked .tools/godot -> $GODOT_BIN"
fi

if python3 -m pip show gdtoolkit >/dev/null 2>&1; then
	echo "[setup] gdtoolkit already installed, skipping"
else
	echo "[setup] Installing gdtoolkit 4.x"
	python3 -m pip install --break-system-packages "gdtoolkit==4.*"
fi

echo "[setup] done"
