# Buildable Area System

## Overview

The buildable area system restricts where players can place obstacles/towers in a level. This ensures gameplay balance and prevents placing obstacles in unintended locations such as near enemy spawners or map edges.

## How It Works

The buildable area is defined by an **Area3D** node in each level. Obstacles can only be placed within this area's collision shape. This approach allows level designers to create buildable zones that are **smaller** than the navigation region, keeping spawners and map edges clear for enemy pathfinding.

### Why Area3D?

Using Area3D for the buildable area has several advantages:
- **Precise control**: Define exact boundaries separate from navigation mesh
- **Smaller than navigation**: Keep enemy spawners and map edges clear
- **Visual editing**: Level designers can see and edit the buildable area in the Godot editor
- **Flexible shapes**: Use any collision shape (box, polygon, compound shapes)
- **Optional**: If not defined, placement is allowed anywhere (backward compatible)
- **Performance**: Uses efficient physics point queries

## For Level Designers

### Setting Up a Buildable Area

1. **Add an Area3D** to your level scene
   ```
   Level
   ├── BuildableArea (Area3D)
   │   └── CollisionShape3D (BoxShape3D, or any shape)
   ├── ObstaclePlacement
   └── ... other level components
   ```

2. **Configure the Area3D**:
   - Add a CollisionShape3D as a child
   - Choose an appropriate shape (BoxShape3D for rectangular areas, or custom polygon shapes)
   - Set the collision layer (e.g., layer 8 for buildable areas)
   - Position and scale the shape to define your buildable zone
   - **Important**: Make this area **smaller** than the NavigationRegion3D to keep spawners and edges clear

3. **Connect to ObstaclePlacement**: 
   - Select the ObstaclePlacement node
   - In the inspector, find the "Node References" section
   - Assign the BuildableArea node to the `buildable_area` export variable

Example scene structure:
```
Level
├── NavigationRegion3D (defines enemy pathfinding area - larger)
├── BuildableArea (Area3D - smaller, inset from edges)
│   └── CollisionShape3D (BoxShape3D)
├── ObstaclePlacement (buildable_area = ../BuildableArea)
├── EnemySpawner (outside buildable area)
└── ... other level components
```

### Design Guidelines

**Size Relationship:**
- NavigationRegion3D: Full walkable area for enemies
- BuildableArea: Inset from edges and spawners
- Recommended: Keep at least 5-10 units clearance from spawners and map edges

**Example Layout:**
```
┌─────────────────────────────────────┐
│ NavigationRegion3D (Full Area)      │
│  ┌───────────────────────────────┐  │
│  │ BuildableArea (Inset)         │  │
│  │                               │  │
│  │  [Players place towers here]  │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│ [Enemy Spawner]      [Map Edge]     │
└─────────────────────────────────────┘
```

### Visual Feedback

When a player attempts to place an obstacle:
- **Green preview**: Valid placement (inside buildable area)
- **Red preview**: Invalid placement (outside buildable area or other validation failure)

### Optional Feature

If no buildable area is defined (`buildable_area` is null), the system allows placement anywhere for backward compatibility. This means:
- Existing levels without Area3D continue to work
- New levels can opt-in to buildable area restrictions by adding an Area3D

## For Programmers

### Validation Flow

The buildable area check is part of the placement validation pipeline:

```gdscript
func _validate_placement(target_position: Vector3) -> PlacementResult:
  if not _preview:
    return PlacementResult.new(false, ValidationError.NO_PLACEABLE_OBSTACLE, ...)
  
  # ✓ Buildable area check (uses Area3D)
  if not _is_within_buildable_area(target_position):
    return PlacementResult.new(false, ValidationError.OUTSIDE_NAVIGATION_REGION, "Outside buildable area")
  
  # Other validations...
  if _has_obstacle_collision(target_position): ...
  if not _has_terrain_support(target_position): ...
  if not _has_sufficient_clearance(target_position): ...
  if insufficient_funds: ...
  
  return PlacementResult.new(true)
```

### Implementation Details

The `_is_within_buildable_area()` method uses physics point queries:

```gdscript
func _is_within_buildable_area(target_position: Vector3) -> bool:
  # If no buildable area is defined, allow placement anywhere (legacy behavior)
  if not buildable_area:
    return true
  
  # Use physics point query to check if position is within the buildable area
  var space_state = get_world_3d().direct_space_state
  var query = PhysicsPointQueryParameters3D.new()
  query.position = target_position
  query.collision_mask = buildable_area.collision_layer
  
  var results = space_state.intersect_point(query)
  
  # Check if any of the results is our buildable area
  for result in results:
    if result.collider == buildable_area:
      return true
  
  return false
```

**Key Points:**
1. Returns `true` if no buildable area is set (backward compatible)
2. Uses `PhysicsPointQueryParameters3D` for efficient point-in-area check
3. Checks collision layer match to ensure correct area is detected
4. Works with any collision shape (box, sphere, polygon, compound)

### Extending the System

To implement more advanced buildable areas:

1. **Multiple regions**: Use multiple Area3D nodes with compound collision shapes
2. **Dynamic shapes**: Modify collision shapes at runtime based on game state
3. **Exclusion zones**: Use negative space or additional validation checks
4. **Custom validation**: Override `_is_within_buildable_area()` for custom logic

### Error Handling

If buildable area is set but placement is outside:
- `_is_within_buildable_area()` returns `false`
- Placement validation fails with `OUTSIDE_NAVIGATION_REGION` error
- User sees red preview and cannot place obstacle

If no buildable area is set:
- `_is_within_buildable_area()` returns `true` (backward compatible)
- No restriction on placement area

## Testing

### Manual Testing

1. **Without buildable area** (legacy mode):
   - Load a level without a buildable area defined
   - Attempt to place an obstacle anywhere → Should work (backward compatible)

2. **With buildable area**:
   - Create an Area3D with a BoxShape3D collision shape
   - Assign it to ObstaclePlacement's `buildable_area` property
   - Inside the area: Should show green preview and allow placement
   - Outside the area: Should show red preview and prevent placement

3. **Design verification**:
   - Ensure buildable area is smaller than navigation region
   - Check spawners are outside the buildable area
   - Verify map edges have clearance from buildable area

## Performance Considerations

- **Validation frequency**: Called on every mouse movement during placement (via `_update_visual_feedback`)
- **Performance impact**: Minimal - uses efficient physics point query
- **Optimization**: Consider caching buildable area checks if performance issues arise

## Related Systems

- **ObstaclePlacement**: Main placement system (`Utilities/Placement/obstacle_placement/`)
- **PlacementResult**: Validation result with error types (`placement_result.gd`)
- **NavigationRegion3D**: Godot's built-in navigation system
- **ObstaclePreview**: Visual feedback during placement (`obstacle_preview.gd`)

## Configuration Options

Available in `ObstaclePlacement` node:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `buildable_area` | Area3D | null | Defines the buildable area (optional, smaller than navigation region) |
| `navigation_region` | NavigationRegion3D | null | Reference to navigation region for enemy pathfinding |
| `placement_clearance` | float | 3.0 | Minimum distance from other obstacles |

## Future Enhancements

Possible improvements:
- [ ] Multiple buildable regions per level (e.g., separate zones with different costs)
- [ ] Visual debug overlay showing buildable area boundaries in-game
- [ ] Per-obstacle-type buildable area restrictions
- [ ] Dynamic buildable areas that expand/shrink during gameplay
- [ ] Cost multipliers for different buildable zones
- [ ] Buildable area editor tool for easier level design
