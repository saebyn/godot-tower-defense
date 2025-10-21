#!/bin/bash
# Run GUT tests from command line
# Usage: ./run_tests.sh

cd "$(dirname "$0")"

./godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
