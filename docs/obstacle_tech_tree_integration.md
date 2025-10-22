# Obstacle Tech Tree Integration

## Overview
This document describes the integration between the Obstacle system and the Tech Tree system, allowing obstacles to be unlocked via technology research.

## Changes Made

### 1. ObstacleTypeResource (`Config/Obstacles/obstacle_type_resource.gd`)

**Removed:**
- `unlock_conditions: Array[String]` - Generic string-based unlock system

**Added:**
- `required_tech_ids: Array[String]` - Array of technology IDs that must be unlocked for this obstacle to be available

**Behavior:**
- If `required_tech_ids` is empty, the obstacle is available from the start (no tech required)
- If `required_tech_ids` has values, ALL listed technologies must be unlocked for the obstacle to become available

### 2. ObstacleRegistry (`Utilities/Systems/obstacle_registry.gd`)

**Removed:**
- `apply_conditions(conditions: Array[String])` - Generic condition-based unlock system

**Added:**
- `_is_obstacle_unlocked(obstacle_type: ObstacleTypeResource) -> bool` - Checks if an obstacle meets its tech requirements
- `_on_tech_unlocked(tech_id: String)` - Signal handler for when a tech is unlocked
- `_on_tech_locked(tech_id: String)` - Signal handler for when a tech is locked (mutual exclusivity)
- `get_obstacle_type(obstacle_id: String) -> ObstacleTypeResource` - Retrieve an obstacle by ID
- `is_obstacle_available(obstacle_id: String) -> bool` - Check if an obstacle is currently available

**Enhanced:**
- `_ready()` now connects to TechTreeManager signals
- `_update_available_obstacles()` uses the tech tree system instead of generic conditions
- Better logging throughout

### 3. Obstacle Resource Files

Updated both `turret.tres` and `wall.tres`:
- Changed `unlock_conditions = Array[String]([])` to `required_tech_ids = Array[String]([])`
- Both obstacles currently have no tech requirements (available from start)

## How It Works

1. **Initialization**: On startup, ObstacleRegistry loads all obstacle types from `Config/Obstacles/`
2. **Tech Tree Connection**: ObstacleRegistry connects to TechTreeManager's `tech_unlocked` and `tech_locked` signals
3. **Availability Check**: For each obstacle, the registry checks if all `required_tech_ids` are unlocked
4. **Dynamic Updates**: When technologies are unlocked/locked, the registry automatically updates the available obstacles list
5. **Signal Emission**: The `obstacle_types_updated` signal is emitted with arrays of newly added/removed obstacles

## Usage Examples

### Defining an Obstacle with Tech Requirements

In an obstacle resource file (e.g., `advanced_turret.tres`):
```gdscript
required_tech_ids = Array[String](["basic_turret_tech", "damage_boost_tech"])
```
This obstacle requires BOTH "basic_turret_tech" AND "damage_boost_tech" to be unlocked.

### Defining Technologies that Unlock Obstacles

In a tech node resource file (e.g., `basic_turret_tech.tres`):
```gdscript
unlocked_obstacle_ids = Array[String](["advanced_turret"])
```
This is for UI/documentation purposes - the actual unlock logic is handled by ObstacleRegistry checking `required_tech_ids`.

### Checking Obstacle Availability in Code

```gdscript
# Check if a specific obstacle is available
if ObstacleRegistry.is_obstacle_available("advanced_turret"):
    # Player can place this obstacle
    pass

# Get all currently available obstacles
var available = ObstacleRegistry.available_obstacle_types
for obstacle in available:
    print("Available: %s" % obstacle.name)

# Listen for changes
func _ready():
    ObstacleRegistry.obstacle_types_updated.connect(_on_obstacles_updated)

func _on_obstacles_updated(added: Array[ObstacleTypeResource], removed: Array[ObstacleTypeResource]):
    for obstacle in added:
        print("New obstacle unlocked: %s" % obstacle.name)
    for obstacle in removed:
        print("Obstacle locked: %s" % obstacle.name)
```

## Integration with TechTreeManager

The ObstacleRegistry integrates seamlessly with TechTreeManager:

1. When a tech is unlocked via `TechTreeManager.unlock_tech(tech_id)`:
   - TechTreeManager emits `tech_unlocked` signal
   - ObstacleRegistry receives signal and calls `_update_available_obstacles()`
   - Any obstacles requiring that tech (and whose other requirements are met) become available

2. When a tech is locked (due to mutual exclusivity):
   - TechTreeManager emits `tech_locked` signal
   - ObstacleRegistry receives signal and calls `_update_available_obstacles()`
   - Any obstacles requiring that tech become unavailable

## Benefits

1. **Centralized Tech System**: All unlocking logic goes through the tech tree
2. **Automatic Updates**: Obstacles automatically become available/unavailable based on tech state
3. **Multiple Requirements**: Obstacles can require multiple technologies
4. **No Tech Requirements**: Obstacles with empty `required_tech_ids` are always available
5. **Graceful Degradation**: System works even if TechTreeManager is not available (logs warning, assumes all unlocked)
6. **Signal-Based**: UI and gameplay systems can react to obstacle availability changes

## Migration Notes

For existing code that used the old `apply_conditions()` method:
- Remove calls to `ObstacleRegistry.apply_conditions()`
- The registry now updates automatically via tech tree signals
- Use `ObstacleRegistry.is_obstacle_available(obstacle_id)` instead of checking conditions manually
