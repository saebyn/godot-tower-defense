## Summary

An audit of the codebase has identified several areas where naming has drifted over time — where related things use different names for the same concept, or where code and docs are out of sync. This issue tracks the work to align all naming to agreed-upon canonical terms.

### Canonical Naming Decisions

| Concept | Canonical Name | Notes |
|---|---|---|
| The people being defended | **Survivor** | Rename from "target" in entity/group/file contexts |
| What an enemy or turret is currently attacking | **Target** (keep) | Generic attack-target; context-dependent, no rename needed |
| The visual HP overlay on entities | **Unit frame** (overall), **Health bar** (the ProgressBar within) | Exports and internal methods that refer to the whole overlay should say "unit frame" |
| Placeable player-built structures | **Building** | Align SFX enum, `.tres` files, and asset paths (already use "building"); update remaining "obstacle" references in sound effect names and comments to "building" where they refer to the concept generically |
| A playable game map/stage | **Scenario** | Finish the migration from "level" in UI text, node names, docs, and test comments |
| Descriptive/flavor text for buildings | **Towers, turrets, defenses** are fine in descriptive prose | Concrete code/API references should use specific building type names or "buildings" generally |

---

## Identified Drifts

### 🔴 1. "Target" → "Survivor" (HIGH — includes a bug)

The concept of "the people being defended" has evolved from generic "target" to "survivor" but the rename was only partially applied.

**Bug:** `health.gd` checks `parent.is_in_group("survivors")` to apply `COLOR_SURVIVOR`, but the actual Godot group assigned to survivor entities is "targets". Survivors never get their custom health bar color — they fall through to `COLOR_DEFAULT`.

**Scope of rename:**
- [ ] Godot global group: "targets" → "survivors" (in `project.godot` and all `.tscn` files)
- [ ] Directory: `Entities/Targets/` → `Entities/Survivors/`
- [ ] Script file: `target.gd` → `survivor.gd`
- [ ] Directory: `base_target/` → `base_survivor/`
- [ ] Update all `res://Entities/Targets/` paths in `.tscn` and `preload`/`load` calls
- [ ] Method: `on_target_died()` → `on_survivor_died()` (in `scenario.gd` and callers)
- [ ] Variable: `target_color` → `survivor_color` (minimap)
- [ ] Method: `_draw_obstacles_and_targets()` → `_draw_obstacles_and_survivors()` (minimap)
- [ ] Variable: `panic_behavior.gd` `var target` → `var survivor`
- [ ] Enemy export: `target_group = "targets"` → `survivor_group = "survivors"` (in `enemy.gd`)
- [ ] Log scopes: "Target" → "Survivor" (in `target.gd`/`survivor.gd`)
- [ ] Camera function comments and log messages referencing "targets" group
- [ ] `health.gd`: `is_in_group("survivors")` — will be correct after group rename
- [ ] Keep `current_target` in `enemy.gd` (attack-target context, not a survivor-specific name)
- [ ] Keep `target_group` in `dot_effect.gd` / `passive_damage.gd` (these target enemies, not survivors)

### 🟡 2. "Health bar" → "Unit frame" (MEDIUM)

The public API (`show_unit_frame()`, `hide_unit_frame()`) and tests already use "unit frame", but exports and some internal methods still say "health bar" when referring to the whole overlay.

- [ ] Export: `show_health_bar` → `show_unit_frame` (in `health.gd`)
- [ ] Update all `.tscn` files that set `show_health_bar = false` → `show_unit_frame = false`
- [ ] Method: `_update_health_bar_visuals()` → `_update_unit_frame_visuals()`
- [ ] Keep `health_bar` (`@onready var`) — this is the actual `ProgressBar` node within the unit frame
- [ ] Keep `health_label` — correct for the label node
- [ ] Optionally rename `bar_color` → `fill_color`, `use_custom_bar_color` → `use_custom_fill_color`

### 🟡 3. "Building" alignment (MEDIUM)

SFX enum already uses `BUILDING_*` prefix. Some callers, comments, and the `SoundCategory.BUILDING` are already aligned. Ensure remaining references use "building" consistently.

- [ ] `ZOMBIE_ATTACK` comment: "survivor or building" — already correct after this decision
- [ ] Verify all obstacle code that plays `BUILDING_*` sounds has appropriate comments
- [ ] Update GDD and docs to use "building" when referring to player-placed structures generically
- [ ] Keep `Entity_PlaceableObstacle` class name as-is for now (class rename is higher risk, can be a follow-up)

### 🟡 4. "Level" → "Scenario" (MEDIUM)

Code has fully migrated to "scenario" but UI and docs lag behind.

- [ ] `scenario_select.tscn`: rename root node from `LevelSelect` to `ScenarioSelect`
- [ ] `scenario_select.tscn`: change title label text from "LEVEL SELECTION" to "SCENARIO SELECTION" (or similar)
- [ ] `ARCHITECTURE.md`: Update state diagram text ("All Targets Destroyed" → "All Survivors Lost", "Retry Level" → "Retry Scenario", "Next Level" → "Next Scenario", "load level" → "load scenario", "Level Select" → "Scenario Select")
- [ ] `ARCHITECTURE.md`: ScenarioManager description uses "Level progression" — update
- [ ] `ACHIEVEMENT_UI_MOCKUPS.md`: `[LEVEL SELECT]` → `[SCENARIO SELECT]`
- [ ] `CLASS_HIERARCHY.md`: `UI_ScenarioSelect` described as "Level selection screen" — update
- [ ] `zom_nom_defense_gdd.md`: "## Level Structure" → "## Scenario Structure", "Sample Levels" → "Sample Scenarios", "Level 1/2/3" → "Scenario 1/2/3"
- [ ] `zom_nom_defense_gdd.md`: "challenge levels" → "challenge scenarios", "level completion" → "scenario completion"
- [ ] Test comments in `test_scenario_completion_flow.gd`: "Level ID", "Level 1", "Level 2" → "Scenario ID", "Scenario 1", "Scenario 2"

### 🟢 5. GDD terminology alignment (LOW)

The GDD uses "towers", "turrets", "defenses", and "obstacles" loosely. In descriptive/flavor text this is fine, but concrete references should use "building" or specific type names.

- [ ] Review GDD for places where "tower" or "obstacle" is used in concrete technical descriptions and update to "building" or specific type names
- [ ] Keep flavor text like "Upgradeable towers" and "Support towers" — these are fine in player-facing descriptions
- [ ] Update "No Turrets" challenge description if needed for consistency

### 📄 6. General docs pass

- [ ] `SCENARIO_ENVIRONMENTS.md`: example shows `└── Targets (Survivors around campfire)` — update to `Survivors`
- [ ] `multiple_spawn_areas.md`: diagrams show `[Target]` — update to `[Survivor]`
- [ ] `damage_numbers_system.md`: review for "target" references
- [ ] `copilot-instructions.md`: `Entities/Targets/` description — update path and description
- [ ] Any other docs referencing the old terminology

---

## Proposed Phasing

These can be done in phases to keep PRs reviewable:

1. **Phase 1 — "Target" → "Survivor"** (highest priority, fixes the health bar color bug)
   - Group rename, directory/file renames, code identifier updates
2. **Phase 2 — "Health bar" → "Unit frame"**
   - Export rename, method renames, `.tscn` updates
3. **Phase 3 — "Level" → "Scenario"**
   - UI node names, title text, doc updates
4. **Phase 4 — Docs alignment pass**
   - GDD terminology, architecture docs, all remaining doc references
   - "Building" alignment in docs
   - Flavor text review

Each phase should include updating tests to match the new names.

## Context

This audit was performed by scanning the codebase for inconsistently named concepts. Results were limited to 10 per search query, so there may be additional instances beyond what's listed. A thorough search during implementation is recommended.