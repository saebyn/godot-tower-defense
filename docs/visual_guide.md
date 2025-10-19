# Multiple Spawn Areas - Visual Guide

## Before (Single Spawn Area)

```
Level Layout:
┌────────────────────────────────────────┐
│                                        │
│                                        │
│         [Target]                       │
│                                        │
│                                        │
│                    🟥                  │
│              Spawn Area                │
│           (All enemies spawn           │
│            from same area)             │
│                                        │
└────────────────────────────────────────┘

Enemy Flow:
All enemies → Single spawn point → Target
```

## After (Multiple Spawn Areas)

```
Level Layout:
┌────────────────────────────────────────┐
│  🟥 North                              │
│  Spawn                                 │
│                                        │
│         [Target]         🟥 East       │
│                          Spawn         │
│                                        │
│                                        │
│  🟥 South                              │
│  Spawn                                 │
└────────────────────────────────────────┘

Enemy Flow (Varied):
North Spawn → ↘
              → Target ← East Spawn
South Spawn → ↗

Random Distribution:
- Enemy 1: North Spawn → Target
- Enemy 2: South Spawn → Target  
- Enemy 3: East Spawn → Target
- Enemy 4: North Spawn → Target
- Enemy 5: South Spawn → Target
- ...continues randomly...
```

## Implementation Comparison

### Old Implementation (Single Area)
```gdscript
# enemy_spawner.gd
@export var spawn_area: MeshInstance3D

func find_random_spawn_position() -> Vector3:
    var bounds = spawn_area.get_aabb()
    return Vector3(
        randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
        randf_range(bounds.position.y, bounds.position.y + bounds.size.y),
        randf_range(bounds.position.z, bounds.position.z + bounds.size.z)
    )
```

### New Implementation (Multiple Areas)
```gdscript
# enemy_spawner.gd
@export var spawn_areas: Array[MeshInstance3D] = []

func find_random_spawn_position() -> Vector3:
    var spawn_area_to_use: MeshInstance3D
    
    if spawn_areas.is_empty():
        # Backward compatibility: find child mesh
        for child in get_children():
            if child is MeshInstance3D:
                spawn_area_to_use = child
                break
    else:
        # Pick random area
        spawn_area_to_use = spawn_areas.pick_random()
    
    var bounds = spawn_area_to_use.get_aabb()
    var local_position = Vector3(
        randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
        randf_range(bounds.position.y, bounds.position.y + bounds.size.y),
        randf_range(bounds.position.z, bounds.position.z + bounds.size.z)
    )
    # Transform to global coordinates
    return spawn_area_to_use.global_transform * local_position
```

## Scene Hierarchy Comparison

### Before
```
Level
└── EnemySpawner
    ├── MeshInstance3D (single spawn area)
    └── Wave1
```

### After (Backward Compatible)
```
Level
└── EnemySpawner
    ├── MeshInstance3D (still works!)
    └── Wave1
```

### After (Multiple Areas)
```
Level
└── EnemySpawner
    ├── NorthSpawnArea (MeshInstance3D)
    ├── SouthSpawnArea (MeshInstance3D)
    ├── EastSpawnArea (MeshInstance3D)
    └── Wave1
```

## Configuration in Godot Editor

```
EnemySpawner Node Properties:
┌──────────────────────────────────┐
│ Script Variables                 │
│ ┌──────────────────────────────┐ │
│ │ Spawn Areas (Array)          │ │
│ │   Size: 3                    │ │
│ │   [0]: NorthSpawnArea        │ │
│ │   [1]: SouthSpawnArea        │ │
│ │   [2]: EastSpawnArea         │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

## Spawn Distribution Example

With 3 spawn areas and 12 enemies:

```
Spawn Sequence (Random):
1. Enemy 1  → South Spawn  🟥 ↗
2. Enemy 2  → North Spawn  🟥 ↘
3. Enemy 3  → East Spawn   🟥 ←
4. Enemy 4  → South Spawn  🟥 ↗
5. Enemy 5  → North Spawn  🟥 ↘
6. Enemy 6  → East Spawn   🟥 ←
7. Enemy 7  → North Spawn  🟥 ↘
8. Enemy 8  → South Spawn  🟥 ↗
9. Enemy 9  → East Spawn   🟥 ←
10. Enemy 10 → South Spawn  🟥 ↗
11. Enemy 11 → North Spawn  🟥 ↘
12. Enemy 12 → East Spawn   🟥 ←

Result: Approximately even distribution
(~4 enemies from each spawn area)
```

## Benefits Visualization

### Single Spawn Area
```
Player Strategy: Simple
  ┌──────────────┐
  │  Build here  │  ← Single choke point
  │      ▲       │
  │      │       │
  │   Enemies    │
  │      ↑       │
  │   Spawn      │
  └──────────────┘
```

### Multiple Spawn Areas
```
Player Strategy: Complex and Dynamic
  ┌──────────────────────────────┐
  │  Spawn  →  Defend  ←  Spawn │
  │    ↓         ↓         ↓    │
  │    ↓    ← Target →    ↓    │
  │    ↓         ↑         ↓    │
  │  Spawn  →  Defend  ←  Spawn │
  └──────────────────────────────┘

Player must:
- Defend multiple fronts
- Allocate resources strategically
- React to changing enemy positions
```

## Key Takeaways

1. **Flexibility**: Level designers can create varied spawn patterns
2. **Backward Compatible**: Old levels still work without changes
3. **Random Distribution**: Enemies spread across all configured areas
4. **Strategic Depth**: Players face more complex defense scenarios
5. **Easy Setup**: Just add more MeshInstance3D nodes and configure the array
