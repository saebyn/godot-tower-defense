# Example: Configuring Multiple Spawn Areas

This example shows how to configure the enemy spawner with multiple spawn areas in a level.

## Scene Structure

```
Level
├── EnemySpawner
│   ├── NorthSpawnArea (MeshInstance3D) - Plane at position (-30, 1, -20)
│   ├── SouthSpawnArea (MeshInstance3D) - Plane at position (-30, 1, 20)
│   └── EastSpawnArea (MeshInstance3D) - Plane at position (20, 1, 0)
│   └── Wave1 (Node3D)
```

## Configuration Steps

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

## Expected Behavior

When the game runs:
- Enemies from Wave1 will spawn randomly from any of the three spawn areas
- Each enemy spawned will appear at a random position within one of the three areas
- This creates more dynamic gameplay as enemies approach from multiple directions

## Example GDScript Configuration (Alternative Method)

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

## Tips

- **Visualize Spawn Areas**: Keep the MeshInstance3D visible during development to see where enemies will spawn
- **Area Size**: Larger spawn areas create more variation in spawn positions
- **Strategic Placement**: Place spawn areas to create interesting gameplay challenges
- **Performance**: The spawner efficiently picks a random area for each spawn, so you can use many spawn areas without performance issues
