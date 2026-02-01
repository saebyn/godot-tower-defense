#!/usr/bin/env bash
# Run GUT tests from command line
# Usage: ./run_tests.sh

set -e  # Exit on any error

cd "$(dirname "$0")"

GODOT=godot

# If godot is not in PATH, use the local godot executable
if ! command -v $GODOT &> /dev/null
then
    GODOT="./godot"
fi


# Check if assets have been imported
if [ ! -d ".godot/imported" ]; then
  echo "ERROR: Assets not imported. Run './godot --headless --import --path .' first"
  exit 1
fi

$GODOT --headless -s addons/gut/gut_cmdln.gd  --path "$PWD" -gconfig=.gutconfig.json $@
