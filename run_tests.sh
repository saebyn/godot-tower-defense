#!/usr/bin/env bash
# Run GUT tests from command line
# Usage: ./run_tests.sh

cd "$(dirname "$0")"

GODOT=godot

# If godot is not in PATH, use the local godot executable
if ! command -v $GODOT &> /dev/null
then
    GODOT="./godot"
fi

$GODOT --headless -s addons/gut/gut_cmdln.gd  --path "$PWD" -gconfig=.gutconfig.json $@
