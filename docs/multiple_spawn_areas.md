# Multiple Spawn Areas Feature

## Overview

The enemy spawner now supports spawning enemies in multiple areas across the level, providing more dynamic and interesting gameplay.


### Before (Single Spawn Area)

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

### After (Multiple Spawn Areas)

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

## Example: Configuring Multiple Spawn Areas

This example shows how to configure the enemy spawner with multiple spawn areas in a level.

### Scene Structure

```
Level
├── EnemySpawner
│   ├── NorthSpawnArea (MeshInstance3D) - Plane at position (-30, 1, -20)
│   ├── SouthSpawnArea (MeshInstance3D) - Plane at position (-30, 1, 20)
│   └── EastSpawnArea (MeshInstance3D) - Plane at position (20, 1, 0)
│   └── Wave1 (Node3D)
```

### Configuration Steps

1. **Create the Spawn Areas**:
   - Add MeshInstance3D nodes as children of EnemySpawner
   - Give them descriptive names (e.g., NorthSpawnArea, SouthSpawnArea)
   - Set their transforms to position them in different areas of the level
   - Assign a mesh (typically a PlaneMesh or BoxMesh) to define the spawn region

2. **Configure the EnemySpawner**:
   - Select the EnemySpawner node
   - In the Inspector, find the "Spawn Areas" property
   - Set the array size to match the number of spawn areas (e.g., 3)
   - Assign each spawn area to an element in the array:
     - Element 0: NorthSpawnArea
     - Element 1: SouthSpawnArea
     - Element 2: EastSpawnArea

3. **Add Wave Definitions** (as usual):
   - Add Wave nodes as children of EnemySpawner
   - Configure enemy types, counts, and timing

### Expected Behavior

When the game runs:
- Enemies from Wave1 will spawn randomly from any of the three spawn areas
- Each enemy spawned will appear at a random position within one of the three areas
- This creates more dynamic gameplay as enemies approach from multiple directions

### Example GDScript Configuration (Alternative Method)

You can also configure spawn areas programmatically:

```gdscript
extends Level

func _ready():
    var spawner = $EnemySpawner
    
    # Get references to spawn area meshes
    var north_area = spawner.get_node("NorthSpawnArea")
    var south_area = spawner.get_node("SouthSpawnArea")
    var east_area = spawner.get_node("EastSpawnArea")
    
    # Configure spawn areas
    spawner.spawn_areas = [north_area, south_area, east_area]
```

### Tips

- **Visualize Spawn Areas**: Keep the MeshInstance3D visible during development to see where enemies will spawn
- **Area Size**: Larger spawn areas create more variation in spawn positions
- **Strategic Placement**: Place spawn areas to create interesting gameplay challenges
- **Performance**: The spawner efficiently picks a random area for each spawn, so you can use many spawn areas without performance issues
