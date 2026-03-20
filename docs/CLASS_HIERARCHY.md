# Class Hierarchy and Naming Conventions

This document describes the class hierarchy, naming conventions, and organizational structure for nodes and scripts in Zom Nom Defense.

## Table of Contents
- [Overview](#overview)
- [Naming Conventions](#naming-conventions)
- [Class Organization](#class-organization)
- [Components vs Entities](#components-vs-entities)
- [Complete Class Reference](#complete-class-reference)

---

## Overview

All custom classes in Zom Nom Defense use a prefix-based naming system to organize them logically in Godot's "Create New Node" dialog. This makes it easy to find and use the right classes when building scenes.

### Benefits of Prefix-Based Naming

1. **Logical Grouping**: Related classes appear together alphabetically
2. **Easy Discovery**: Find what you need by category prefix
3. **Clear Purpose**: Class name immediately indicates its role
4. **Scalability**: Easy to add new classes within existing categories

---

## Naming Conventions

### Class Name Format

```gdscript
class_name <Prefix>_<DescriptiveName>
```

### Prefix Categories

| Prefix | Category | Purpose | Examples |
|--------|----------|---------|----------|
| `Component_` | Components | Reusable behavior modules | `Component_Health`, `Component_Attack` |
| `UI_` | User Interface | UI controls and displays | `UI_Hotbar`, `UI_Minimap` |
| `Resource_` | Resources | Data-only resource files | `Resource_EnemyType`, `Resource_ObstacleType` |
| `Entity_` | Game Entities | In-game objects with physics | `Entity_PlaceableObstacle`, `Entity_Scrap` |
| `System_` | Game Systems | High-level game logic | `System_EnemySpawner`, `System_Wave` |
| `Effect_` | Visual/Audio Effects | Effect controllers | `Effect_Shake` |
| `Utility_` | Utilities | Helper classes and tools | `Utility_ObstaclePlacement` |
| `Stage_` | Stages/Scenarios | Scenario classes | `Stage_Scenario` |

---

## Class Organization

### Components (`Component_*`)

**Location**: `Common/Components/`

Components are reusable, modular pieces of functionality that can be attached to entities as child nodes. They provide specific behaviors like health management, attack logic, or status effects.

**Key Characteristics:**
- ✅ **Should be classes only** (`.gd` files)
- ❌ **Should NOT be scenes** (`.tscn` files)
- Extend from base Godot nodes (`Node`, `Area3D`, etc.)
- Register themselves in parent's metadata for discovery
- Focus on single responsibility

**Available Components:**

| Class Name | Base Type | Purpose |
|------------|-----------|---------|
| `Component_Health` | `Node` | Manages hitpoints, damage, and death |
| `Component_Attack` | `Node` | Handles attack logic with cooldown |
| `Component_DotEffect` | `Area3D` | Damage over time effect area |
| `Component_PassiveDamage` | `Area3D` | Instant damage on contact |
| `Component_PanicBehavior` | `Node` | Panic animation controller |

**Usage Example:**
```gdscript
# Add to entity scene tree, not instantiated in code
# Component registers itself automatically in _ready()
var health: Component_Health
func _ready():
  if has_meta("health_component"):
    health = get_meta("health_component")
```

**Why Components Should Be Classes, Not Scenes:**

1. **Performance**: Instantiating scripts is faster than loading scenes
2. **Flexibility**: Easier to attach dynamically in code
3. **Simplicity**: No scene hierarchy to manage
4. **Composability**: Pure behavior, no visual structure

> **Note**: Some older components (`Component_Health` and `Component_Attack`) currently have both `.gd` and `.tscn` files. These should be refactored to remove the `.tscn` files in future updates, using the scripts directly instead.

---

### User Interface (`UI_*`)

**Location**: `Common/UI/` and `Stages/UI/`

UI classes handle player interaction, information display, and menu systems.

**Key Characteristics:**
- Extend from Control nodes or UI-specific base classes
- May be scenes with complex hierarchies
- Connected to game systems via signals and autoloads

**Available UI Classes:**

**Common UI** (`Common/UI/`):
| Class Name | Base Type | Purpose |
|------------|-----------|---------|
| `UI_Hotbar` | `Control` | Building selection bar (1-9 keys) |
| `UI_CurrencyDisplay` | `Control` | Shows scrap, XP, and level |
| `UI_StatsDisplay` | `Control` | Enemy defeats and placements |
| `UI_SpeedControls` | `Control` | Game speed control (1x/2x/3x) |
| `UI_Minimap` | `Control` | Top-down game view |
| `UI_SpawnIndicator` | `Control` | Wave countdown and enemies remaining |
| `UI_OffscreenIndicator` | `Control` | Direction arrows for offscreen enemies |
| `UI_FpsOverlay` | `Control` | FPS and performance display |
| `UI_SettingsMenu` | `Control` | Settings panel |
| `UI_VideoSettingsConfirmDialog` | `AcceptDialog` | Video settings confirmation |
| `UI_KeybindButton` | `HBoxContainer` | Keybinding editor button |
| `UI_AchievementNotification` | `Control` | Achievement popup |
| `UI_AchievementNotificationManager` | `CanvasLayer` | Manages achievement notifications |

**Menu UI** (`Stages/UI/`):
| Class Name | Base Type | Purpose |
|------------|-----------|---------|
| `UI_MainMenu` | `Control` | Main menu screen |
| `UI_PauseMenu` | `Control` | In-game pause menu |
| `UI_ScenarioSelect` | `Control` | Scenario selection screen |
| `UI_TechTree` | `Control` | Tech tree UI display |
| `UI_TechNodeCard` | `PanelContainer` | Individual tech node in tree |
| `UI_AchievementList` | `Control` | Achievement list screen |
| `UI_AchievementCard` | `Control` | Individual achievement card |

---

### Resources (`Resource_*`)

**Location**: `Config/`

Resource classes are pure data containers extending Godot's `Resource` class. They store configuration for enemies, obstacles, achievements, etc.

**Key Characteristics:**
- Extend from `Resource`
- No logic, only data properties
- Saved as `.tres` files
- Designer-editable in Godot Inspector

**Available Resources:**

| Class Name | Location | Purpose |
|------------|----------|---------|
| `Resource_EnemyType` | `Config/Enemies/` | Enemy configuration data |
| `Resource_ObstacleType` | `Config/Obstacles/` | Obstacle/tower configuration |
| `Resource_Achievement` | `Config/Achievements/` | Achievement definitions |
| `Resource_TechNode` | `Config/TechTree/` | Tech tree node data |

**Usage Example:**
```gdscript
# Defined in resource file
@export var enemy_types: Array[Resource_EnemyType] = []

# Loaded from .tres file
var enemy_config = load("res://Config/Enemies/grunt_config.tres") as Resource_EnemyType
```

---

### Entities (`Entity_*`)

**Location**: `Entities/`

Entities are game objects with physics bodies and scene hierarchies. They represent placeable objects in the game world.

**Key Characteristics:**
- ✅ **Should be scenes** (`.tscn` files with attached scripts)
- Extend from physics nodes (`StaticBody3D`, `CharacterBody3D`, etc.)
- Have child nodes (meshes, collision shapes, components)
- Composed with components for behavior

**Available Entities:**

| Class Name | Base Type | Location | Purpose |
|------------|-----------|----------|---------|
| `Entity_PlaceableObstacle` | `StaticBody3D` | `Entities/Obstacles/Templates/` | Base obstacle/tower class |
| `Entity_ShootingObstacle` | `Entity_PlaceableObstacle` | `Entities/Obstacles/Templates/` | Shooting tower variant |
| `Entity_Scrap` | `Node3D` | `Entities/Scrap/` | Collectible scrap item |

**Why Entities Should Be Scenes:**

1. **Visual Editing**: Easier to position child nodes (meshes, lights, particles)
2. **Hierarchy Management**: Complex node structures are easier in scene editor
3. **3D Model Integration**: Can directly place imported models and adjust transforms
4. **Component Composition**: Easy to add/remove component children visually
5. **Designer-Friendly**: Non-programmers can create variants

---

### Systems (`System_*`)

**Location**: `Common/Systems/`

Systems handle high-level game logic and coordination between entities.

**Available Systems:**

| Class Name | Base Type | Purpose |
|------------|-----------|---------|
| `System_EnemySpawner` | `Node3D` | Spawns and manages enemy waves |
| `System_Wave` | `Node3D` | Defines wave timing and composition |

---

### Effects (`Effect_*`)

**Location**: `Common/Effects/`

Effect classes control visual and audio effects.

**Available Effects:**

| Class Name | Base Type | Purpose |
|------------|-----------|---------|
| `Effect_Shake` | `Node` | Camera shake effect controller |

---

### Utilities (`Utility_*`)

**Location**: `Utilities/`

Utility classes provide helper functionality and tools.

**Available Utilities:**

| Class Name | Base Type | Purpose |
|------------|-----------|---------|
| `Utility_ObstaclePlacement` | `Node3D` | Handles obstacle placement logic |
| `Utility_ObstaclePreview` | `Node3D` | Shows placement preview ghost |
| `Utility_PlacementResult` | *N/A* | Placement validation result data |

---

### Stages (`Stage_*`)

**Location**: `Stages/`

Stage classes represent levels and scenarios.

**Available Stages:**

| Class Name | Base Type | Purpose |
|------------|-----------|---------|
| `Stage_Scenario` | `Node3D` | Scenario controller |

---

## Components vs Entities

This is a critical architectural distinction in Zom Nom Defense:

### Components = Classes (Scripts Only)

**What they are:**
- Pure behavior modules
- Lightweight and reusable
- No visual structure

**File structure:**
```
Common/Components/health/
├── health.gd          ✅ (class_name Component_Health)
└── health.gd.uid
```

**How to use:**
```gdscript
# In entity scene: Add Component_Health as child node
# Script automatically registers in parent metadata

# In entity script:
var health: Component_Health
func _ready():
  if has_meta("health_component"):
    health = get_meta("health_component")
```

### Entities = Scenes (with Scripts)

**What they are:**
- Complete game objects
- Have physics bodies and visual representations
- Composed of multiple child nodes

**File structure:**
```
Entities/Obstacles/Templates/base_obstacle/
├── obstacle.gd        ✅ (class_name Entity_PlaceableObstacle)
├── obstacle.tscn      ✅ (scene file)
├── obstacle.gd.uid
└── obstacle.tscn.uid
```

**Why the distinction matters:**

1. **Performance**: Components are instantiated faster
2. **Reusability**: Same component on many entity types
3. **Clarity**: Clear separation between behavior (component) and object (entity)
4. **Testing**: Components can be unit tested independently
5. **Maintenance**: Changes to component behavior affect all users automatically

---

## Complete Class Reference

### Quick Reference Table

| Class Name | Category | Base Type | Scene? | Location |
|------------|----------|-----------|--------|----------|
| `Component_Health` | Component | `Node` | ❌ | `Common/Components/health/` |
| `Component_Attack` | Component | `Node` | ❌ | `Common/Components/attack/` |
| `Component_DotEffect` | Component | `Area3D` | ❌ | `Common/Components/dot_effect/` |
| `Component_PassiveDamage` | Component | `Area3D` | ❌ | `Common/Components/passive_damage/` |
| `Component_PanicBehavior` | Component | `Node` | ❌ | `Common/Components/panic_behavior/` |
| `Effect_Shake` | Effect | `Node` | ❌ | `Common/Effects/shake_effect/` |
| `System_EnemySpawner` | System | `Node3D` | ✅ | `Common/Systems/spawner/` |
| `System_Wave` | System | `Node3D` | ❌ | `Common/Systems/spawner/` |
| `UI_Hotbar` | UI | `Control` | ✅ | `Common/UI/hotbar/` |
| `UI_SettingsMenu` | UI | `Control` | ✅ | `Common/UI/settings_menu/` |
| `UI_VideoSettingsConfirmDialog` | UI | `AcceptDialog` | ✅ | `Common/UI/settings_menu/` |
| `UI_KeybindButton` | UI | `HBoxContainer` | ✅ | `Common/UI/settings_menu/` |
| `UI_OffscreenIndicator` | UI | `Control` | ✅ | `Common/UI/offscreen_indicator/` |
| `UI_Minimap` | UI | `Control` | ✅ | `Common/UI/minimap/` |
| `UI_FpsOverlay` | UI | `Control` | ✅ | `Common/UI/fps_overlay/` |
| `UI_SpawnIndicator` | UI | `Control` | ✅ | `Common/UI/spawn_indicator/` |
| `UI_StatsDisplay` | UI | `Control` | ✅ | `Common/UI/stats_display/` |
| `UI_SpeedControls` | UI | `Control` | ✅ | `Common/UI/speed_controls/` |
| `UI_AchievementNotification` | UI | `Control` | ✅ | `Common/UI/achievement_notification/` |
| `UI_AchievementNotificationManager` | UI | `CanvasLayer` | ✅ | `Common/UI/achievement_notification/` |
| `UI_CurrencyDisplay` | UI | `Control` | ✅ | `Common/UI/currency_display/` |
| `UI_PauseMenu` | UI | `Control` | ✅ | `Stages/UI/pause_menu/` |
| `UI_ScenarioSelect` | UI | `Control` | ✅ | `Stages/UI/scenario_select/` |
| `UI_AchievementCard` | UI | `Control` | ✅ | `Stages/UI/achievement_list/` |
| `UI_AchievementList` | UI | `Control` | ✅ | `Stages/UI/achievement_list/` |
| `UI_TechTree` | UI | `Control` | ✅ | `Stages/UI/tech_tree/` |
| `UI_TechNodeCard` | UI | `PanelContainer` | ✅ | `Stages/UI/tech_tree/` |
| `UI_MainMenu` | UI | `Control` | ✅ | `Stages/UI/main_menu/` |
| `Entity_PlaceableObstacle` | Entity | `StaticBody3D` | ✅ | `Entities/Obstacles/Templates/base_obstacle/` |
| `Entity_ShootingObstacle` | Entity | `Entity_PlaceableObstacle` | ✅ | `Entities/Obstacles/Templates/shooting_obstacle/` |
| `Entity_Scrap` | Entity | `Node3D` | ✅ | `Entities/Scrap/` |
| `Resource_EnemyType` | Resource | `Resource` | ❌ | `Config/Enemies/` |
| `Resource_Achievement` | Resource | `Resource` | ❌ | `Config/Achievements/` |
| `Resource_ObstacleType` | Resource | `Resource` | ❌ | `Config/Obstacles/` |
| `Resource_TechNode` | Resource | `Resource` | ❌ | `Config/TechTree/` |
| `Utility_ObstaclePreview` | Utility | `Node3D` | ❌ | `Utilities/Placement/` |
| `Utility_PlacementResult` | Utility | *N/A* | ❌ | `Utilities/Placement/obstacle_placement/` |
| `Utility_ObstaclePlacement` | Utility | `Node3D` | ✅ | `Utilities/Placement/obstacle_placement/` |
| `Stage_Scenario` | Stage | `Node3D` | ✅ | `Stages/Scenarios/` |

---

## Best Practices

### When Creating New Classes

1. **Choose the right prefix** based on the class's primary role
2. **Follow the naming format**: `<Prefix>_<DescriptiveName>`
3. **Use PascalCase** for the descriptive name part
4. **Be specific** but not verbose: `Component_Health` not `Component_HealthManagementSystem`
5. **Avoid abbreviations** unless universally understood: `UI_FpsOverlay` is OK

### Component Guidelines

✅ **DO:**
- Create components as single `.gd` files
- Extend from appropriate Godot base node
- Register in parent metadata in `_ready()`
- Focus on single responsibility
- Use `@export` for designer-configurable properties

❌ **DON'T:**
- Create `.tscn` files for components (use scripts only)
- Put game logic in components (they're behavior, not brains)
- Hard-code references to specific entities
- Use `get_node()` to find components (use metadata)

### Entity Guidelines

✅ **DO:**
- Create entities as `.tscn` scenes with attached scripts
- Compose behavior using component children
- Keep entity scripts as "glue" between components
- Use scenes for anything with visual representation

❌ **DON'T:**
- Instantiate entities directly from scripts (load scene instead)
- Duplicate component logic in entity scripts
- Create complex inheritance hierarchies

---

## Migration Notes

### Legacy Components with Scene Files

Currently, `Component_Health` and `Component_Attack` have both `.gd` and `.tscn` files. This is legacy structure that should eventually be refactored:

**Current state:**
```
Common/Components/health/
├── health.gd          ✅
├── health.tscn        ⚠️ (legacy, should be removed)
└── health.gd.uid
```

**Future state:**
```
Common/Components/health/
├── health.gd          ✅
└── health.gd.uid
```

**Migration plan:**
1. Update all entity scenes to use script directly instead of scene
2. Test that component registration still works correctly
3. Remove `.tscn` files and update references
4. Document the change in release notes

---

## Conclusion

This naming and organizational system provides:

- ✅ **Discoverability**: Easy to find classes by category
- ✅ **Clarity**: Class purpose is immediately apparent
- ✅ **Consistency**: All classes follow same naming pattern
- ✅ **Scalability**: Easy to add new classes without confusion
- ✅ **Best Practices**: Components and entities clearly separated

When in doubt, refer to this document and follow the established patterns. Consistency is key to maintainability!

---

## Component_DamageNumbers Reference

`Common/Components/damage_numbers/damage_numbers.gd`

Displays floating damage numbers and scrap gain feedback above entities. Creates `Label3D` nodes dynamically — no scene file required. Registers itself in the parent's metadata as `"damage_numbers_component"` for discovery.

### Configuration Exports

| Export | Default | Description |
|---|---|---|
| `fade_duration` | `1.5` | Fade-out duration in seconds |
| `float_distance` | `2.0` | Upward travel distance |
| `vertical_offset` | `2.0` | Height above entity origin |
| `show_damage_numbers` | `true` | Toggle damage number display |
| `show_scrap_gain` | `true` | Toggle scrap gain display |

### Key Methods

- `show_damage(amount, damage_source)` — display a colour-coded damage number
- `show_scrap(amount)` — display a gold "+N" scrap gain number

### Color Mapping

| Type | Color | Trigger |
|---|---|---|
| Normal | White | default |
| Fire | Orange | `"fire"`, `"flame"` |
| Ice | Cyan | `"ice"`, `"frost"`, `"cold"` |
| Poison | Purple | `"poison"`, `"toxic"` |
| Critical | Red | `"critical"`, `"crit"` |
| Scrap gain | Gold | `show_scrap()` |

### Integration Pattern

```gdscript
# Discovery via parent metadata (used by Component_Health and enemy.gd)
if parent.has_meta("damage_numbers_component"):
    var dn = parent.get_meta("damage_numbers_component")
    dn.show_damage(amount, damage_source)
```

Add `Component_DamageNumbers` as a child of any `Node3D` entity (enemies, survivors, buildings, scrap boxes) to enable feedback. The component auto-registers on `_ready()`.
