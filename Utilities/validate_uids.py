#!/usr/bin/env python3
"""
validate_uids.py

Scans all .tscn and .tres files in the project for ext_resource entries,
then verifies that each declared UID matches the UID stored in the
corresponding <path>.uid sidecar file.

Usage:
    python3 Utilities/validate_uids.py [project_root]

If project_root is omitted, the current working directory is used.

Exit codes:
    0 — all UIDs match (or no mismatches found)
    1 — one or more mismatches / missing sidecar files detected
"""

import os
import re
import sys

# Matches:  [ext_resource type="..." uid="uid://xxxx" path="res://..." id="..."]
EXT_RESOURCE_RE = re.compile(
    r'\[ext_resource\b[^\]]*\buid="(?P<uid>uid://[^"]+)"[^\]]*\bpath="res://(?P<path>[^"]+)"'
    r'|'
    r'\[ext_resource\b[^\]]*\bpath="res://(?P<path2>[^"]+)"[^\]]*\buid="(?P<uid2>uid://[^"]+)"'
)


IGNORE_SCENE_DIRS = {
    'external',           # git submodules
    'addons/twitcher/example',  # Twitcher example scenes reference res://example/ paths not present in this project
}


def find_scene_files(root: str):
    for dirpath, _dirnames, filenames in os.walk(root):
        # Skip hidden dirs and ignored directories
        rel_dir = os.path.relpath(dirpath, root)
        _dirnames[:] = [
            d for d in _dirnames
            if not d.startswith('.')
            and os.path.join(rel_dir, d).replace('\\', '/') not in IGNORE_SCENE_DIRS
            and d not in IGNORE_SCENE_DIRS
        ]
        if any(rel_dir.replace('\\', '/').startswith(ign) for ign in IGNORE_SCENE_DIRS):
            continue
        for fname in filenames:
            if fname.endswith(('.tscn', '.tres')):
                yield os.path.join(dirpath, fname)


def read_uid_sidecar(uid_path: str):
    """Return the uid string from a .uid sidecar file, or None if missing."""
    try:
        with open(uid_path, 'r', encoding='utf-8') as f:
            return f.read().strip()
    except FileNotFoundError:
        return None


def validate(root: str):
    errors = []
    checked = 0

    for scene_file in find_scene_files(root):
        rel_scene = os.path.relpath(scene_file, root)
        try:
            with open(scene_file, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
        except OSError as exc:
            errors.append(f"  [READ ERROR] {rel_scene}: {exc}")
            continue

        for m in EXT_RESOURCE_RE.finditer(content):
            declared_uid = m.group('uid') or m.group('uid2')
            res_path     = m.group('path') or m.group('path2')

            if not declared_uid or not res_path:
                continue

            # Build absolute filesystem path for the resource
            abs_res_path = os.path.join(root, res_path)
            uid_sidecar  = abs_res_path + '.uid'
            actual_uid   = read_uid_sidecar(uid_sidecar)

            checked += 1

            if actual_uid is None:
                # No sidecar — could be a built-in type or a missing file
                if not os.path.exists(abs_res_path):
                    errors.append(
                        f"  [MISSING RESOURCE] {rel_scene}\n"
                        f"    path : res://{res_path}\n"
                        f"    declared uid: {declared_uid}\n"
                        f"    (resource file does not exist)"
                    )
                # If file exists but has no .uid sidecar, skip silently
                # (some resource types don't generate sidecars)
            elif actual_uid != declared_uid:
                errors.append(
                    f"  [UID MISMATCH] {rel_scene}\n"
                    f"    path        : res://{res_path}\n"
                    f"    declared uid: {declared_uid}\n"
                    f"    actual uid  : {actual_uid}"
                )

    return checked, errors


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    root = os.path.abspath(root)

    print(f"Scanning: {root}\n")
    checked, errors = validate(root)

    print(f"Checked {checked} ext_resource entries across .tscn/.tres files.")

    if errors:
        print(f"\n{'='*60}")
        print(f"FOUND {len(errors)} PROBLEM(S):\n")
        for err in errors:
            print(err)
        print(f"{'='*60}\n")
        sys.exit(1)
    else:
        print("All UIDs match. ✓")
        sys.exit(0)


if __name__ == '__main__':
    main()
