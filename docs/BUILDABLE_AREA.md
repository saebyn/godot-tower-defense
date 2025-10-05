# Buildable Area System

## Overview

The buildable area system restricts where players can place obstacles/towers in a level. This ensures gameplay balance and prevents placing obstacles in unintended locations.

## How It Works

The buildable area is automatically defined by the **NavigationRegion3D** in each level. Obstacles can only be placed within the navigation mesh bounds, with a configurable margin from the edges.

### Why NavigationRegion3D?

Using the navigation region as the buildable area has several advantages:
- **Single source of truth**: The same mesh defines both enemy pathfinding and buildable areas
- **Visual editing**: Level designers can see and edit the buildable area in the Godot editor
- **Automatic validation**: No additional setup required - if a level has a navigation region, it has a buildable area
- **Performance**: Uses existing navigation mesh data, no extra collision shapes needed

## For Level Designers

### Setting Up a Buildable Area

1. **Add a NavigationRegion3D** to your level scene
2. **Configure the navigation mesh** by:
   - Setting the mesh geometry (vertices define the walkable/buildable area)
   - Baking the navigation mesh
3. **Connect to ObstaclePlacement**: Export the navigation_region reference to ObstaclePlacement node

Example scene structure:
```
Level
├── NavigationRegion3D (defines buildable area)
├── ObstaclePlacement (navigation_region = ../NavigationRegion3D)
└── ... other level components
```

### Adjusting the Border Margin

The `border_margin` property on ObstaclePlacement controls how far from the navigation region edge obstacles can be placed:

```gdscript
@export var border_margin: float = 2.0 ## Minimum distance from navigation region border
```

**Default**: 2.0 units
**Recommendation**: Keep at least 2.0 to prevent obstacles from being placed too close to the edge

### Visual Feedback

When a player attempts to place an obstacle:
- **Green preview**: Valid placement (inside buildable area)
- **Red preview**: Invalid placement (outside buildable area or other validation failure)

## For Programmers

### Validation Flow

The buildable area check is part of the placement validation pipeline:

```gdscript
func _validate_placement(target_position: Vector3) -> PlacementResult:
  if not _preview:
    return PlacementResult.new(false, ValidationError.NO_PLACEABLE_OBSTACLE, ...)
  
  # ✓ Buildable area check (ADDED)
  if not _is_within_navigation_region(target_position):
    return PlacementResult.new(false, ValidationError.OUTSIDE_NAVIGATION_REGION, "Outside buildable area")
  
  # Other validations...
  if _has_obstacle_collision(target_position): ...
  if not _has_terrain_support(target_position): ...
  if not _has_sufficient_clearance(target_position): ...
  if insufficient_funds: ...
  
  return PlacementResult.new(true)
```

### Implementation Details

The `_is_within_navigation_region()` method:
1. Gets the navigation mesh vertices
2. Calculates the AABB (Axis-Aligned Bounding Box) from all vertices
3. Transforms the target position to navigation region local space
4. Checks if the position is within bounds (accounting for border_margin)

```gdscript
func _is_within_navigation_region(target_position: Vector3) -> bool:
  if not navigation_region or not navigation_region.navigation_mesh:
    return false
  
  var nav_mesh := navigation_region.navigation_mesh
  var nav_region_transform := navigation_region.global_transform
  
  # Calculate AABB from vertices
  var min_bounds = vertices[0]
  var max_bounds = vertices[0]
  for vertex in vertices:
    min_bounds.x = min(min_bounds.x, vertex.x)
    min_bounds.z = min(min_bounds.z, vertex.z)
    max_bounds.x = max(max_bounds.x, vertex.x)
    max_bounds.z = max(max_bounds.z, vertex.z)
  
  # Transform to local space and check bounds
  var local_pos = nav_region_transform.affine_inverse() * target_position
  return (local_pos.x >= min_bounds.x + border_margin and
          local_pos.x <= max_bounds.x - border_margin and
          local_pos.z >= min_bounds.z + border_margin and
          local_pos.z <= max_bounds.z - border_margin)
```

### Extending the System

To implement more complex buildable areas:

1. **Multiple regions**: Create multiple NavigationRegion3D nodes and check against any of them
2. **Exclusion zones**: Add Area3D nodes and check for overlaps to exclude specific regions
3. **Custom shapes**: Replace navigation mesh check with custom collision shapes

### Error Handling

If no navigation region is set or the navigation mesh is empty:
- `_is_within_navigation_region()` returns `false`
- Placement validation fails with `OUTSIDE_NAVIGATION_REGION` error
- User sees red preview and cannot place obstacle

## Testing

### Manual Testing

1. Load a level with a navigation region
2. Attempt to place an obstacle inside the navigation region → Should show green preview and allow placement
3. Attempt to place an obstacle outside the navigation region → Should show red preview and prevent placement

### Automated Testing

See `/tmp/test_buildable_area.gd` for a validation test script.

## Performance Considerations

- **Validation frequency**: Called on every mouse movement during placement (via `_update_visual_feedback`)
- **Performance impact**: Minimal - simple AABB check against pre-calculated bounds
- **Optimization**: Navigation mesh vertices are read from existing mesh, no additional memory allocation

## Related Systems

- **ObstaclePlacement**: Main placement system (`Utilities/Placement/obstacle_placement/`)
- **PlacementResult**: Validation result with error types (`placement_result.gd`)
- **NavigationRegion3D**: Godot's built-in navigation system
- **ObstaclePreview**: Visual feedback during placement (`obstacle_preview.gd`)

## Configuration Options

Available in `ObstaclePlacement` node:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `navigation_region` | NavigationRegion3D | null | Reference to the navigation region defining buildable area |
| `border_margin` | float | 2.0 | Minimum distance from navigation region border |

## Future Enhancements

Possible improvements:
- [ ] Support for multiple buildable regions per level
- [ ] Visual debug overlay showing buildable area boundaries
- [ ] Per-obstacle-type buildable area restrictions
- [ ] Dynamic buildable areas that change during gameplay
- [ ] Cost multipliers for different buildable zones
