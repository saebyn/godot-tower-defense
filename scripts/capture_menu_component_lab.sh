#!/usr/bin/env bash
set -euo pipefail

godot \
  --display-driver x11 \
  --rendering-driver opengl3 \
  --audio-driver Dummy \
  --path . \
  --script res://scripts/capture_menu_component_lab.gd \
  "$@"
