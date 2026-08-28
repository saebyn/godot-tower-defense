#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

"$GODOT_BIN" \
  --headless \
  --path . \
  --import

"$GODOT_BIN" \
  --display-driver x11 \
  --rendering-driver opengl3 \
  --audio-driver Dummy \
  --path . \
  --script res://scripts/capture_menu_component_lab.gd \
  "$@"
