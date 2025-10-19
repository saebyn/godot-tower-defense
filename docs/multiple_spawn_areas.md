# Multiple Spawn Areas Feature

## Overview

The enemy spawner now supports spawning enemies in multiple areas across the level, providing more dynamic and interesting gameplay.

## How to Use

### Single Spawn Area (Original Behavior)

The original single spawn area configuration is still supported:

```gdscript
# In your level scene, the EnemySpawner will work with a single spawn area
# as defined in the enemy_spawner.tscn template
```

### Multiple Spawn Areas (New Feature)

To spawn enemies from multiple locations:

1. Add multiple `MeshInstance3D` nodes to your level
2. Configure them as spawn areas (they can be planes, boxes, or any mesh)
3. Assign them to the `spawn_areas` array in the EnemySpawner inspector

Example in scene tree:
```
Level
├── EnemySpawner
│   ├── SpawnArea1 (MeshInstance3D)
│   ├── SpawnArea2 (MeshInstance3D)
│   └── SpawnArea3 (MeshInstance3D)
```

In the inspector:
- Select the EnemySpawner node
- In the "Spawn Areas" array, add 3 elements
- Assign SpawnArea1, SpawnArea2, and SpawnArea3 to the array

## How It Works

When an enemy spawns:
1. The spawner randomly selects one of the configured spawn areas
2. It generates a random position within that area's AABB (bounding box)
3. The enemy is placed at that position

This creates varied spawn patterns and prevents enemies from always appearing in the same location.

## Backward Compatibility

Existing levels using the old `spawn_area` property will continue to work:
- The spawner automatically falls back to finding MeshInstance3D child nodes if `spawn_areas` is empty
- No changes are required to existing levels

## Technical Details

- **File Modified**: `Common/Systems/spawner/enemy_spawner.gd`
- **Scene Modified**: `Common/Systems/spawner/enemy_spawner.tscn`
- **Property**: `@export var spawn_areas: Array[MeshInstance3D]`
- **Method**: `find_random_spawn_position()` - Now randomly selects from available spawn areas
