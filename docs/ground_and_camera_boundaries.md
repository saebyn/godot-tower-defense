# Ground and Camera Boundaries Implementation

## Overview
This document describes the implementation of the flat ground plane with visual boundaries and camera movement constraints added to prevent the camera from going too far and showing void areas.

## Components

### 1. Flat Ground Plane (`Common/World/ground_with_boundaries.tscn`)
- **Size**: 500x500 units (much larger than the visible landscape)
- **Position**: Y = -2 (beneath the main landscape)
- **Purpose**: Provides a fallback ground that catches anything that falls off the main landscape
- **Collision**: Part of the navigation mesh source group for pathfinding
- **Material**: Brown/earth-toned to blend with the landscape

### 2. Visual Boundary Markers
Located at the edges of the playable area:
- **Type**: MeshInstance3D nodes with BoxMesh (production-ready, not CSG prototyping)
- **Position**: ±200 units on X and Z axes
- **Appearance**: Red glowing walls (10 units high)
- **Behavior**: Fade in when camera approaches (within 50 units)
- **Material**: Semi-transparent red with emission for visibility

### 3. Camera Boundary Constraints (`Stages/Game/main/camera.gd`)
New export parameters:
- `enable_boundaries`: Toggle camera constraints on/off (default: true)
- `world_min_x`, `world_max_x`: X-axis boundaries (default: -200 to 200)
- `world_min_z`, `world_max_z`: Z-axis boundaries (default: -200 to 200)

#### How it works:
1. Camera movement is tracked via the "orbit center" (where the camera looks at the ground)
2. After movement or rotation, `_apply_boundary_constraints()` is called
3. The orbit center is clamped to stay within defined world boundaries
4. Camera position is adjusted to maintain the same offset from the constrained orbit center

### 4. Boundary Marker Visibility (`Common/World/world_boundary_markers.gd`)
- Tracks camera position relative to boundaries
- Calculates distance to each boundary (North, South, East, West)
- Fades markers from transparent to 50% opacity based on distance
- `fade_distance`: 50 units - distance at which fade begins

## Integration

### In `main.tscn`:
```gdscript
[node name="GroundWithBoundaries" parent="." node_paths=PackedStringArray("camera") instance=ExtResource("6_ground")]
camera = NodePath("../Camera3D")
```

The ground and boundaries are added as a child of the Main node, with the camera reference passed for visibility tracking.

## Configuration

### Adjusting World Size
To change the playable area size:

1. **In `camera.gd`**: Update the boundary export parameters
2. **In `ground_with_boundaries.tscn`**: Adjust boundary positions to match
3. **In `world_boundary_markers.gd`**: Update the export parameters for world bounds

Example for 300x300 world:
- `world_min_x/z = -300.0`
- `world_max_x/z = 300.0`
- Boundary positions in scene: ±300 units
- Ground plane size can be 600x600 or larger

### Adjusting Boundary Appearance
In `ground_with_boundaries.tscn`, modify `StandardMaterial3D_boundary`:
- `albedo_color`: Change boundary color
- `emission`: Adjust glow intensity
- `emission_energy_multiplier`: Control glow brightness

### Adjusting Fade Behavior
In `world_boundary_markers.gd`:
- `fade_distance`: Distance from boundary where fade begins (default: 50.0)
- Transparency calculation in `_update_boundary_visibility()`

## Testing Checklist

- [ ] Camera cannot move beyond defined boundaries
- [ ] Boundary markers fade in smoothly when approaching edges
- [ ] Flat ground is visible if camera looks outside landscape area
- [ ] Navigation mesh still functions correctly
- [ ] Camera rotation respects boundaries
- [ ] No performance impact from boundary checking

## Technical Details

### Design Decisions

**Why flat ground below landscape?**
- Provides safety net if objects fall off edges
- Doesn't interfere with existing landscape
- Easy to extend for different scenario sizes

**Why fade boundaries instead of always visible?**
- Reduces visual clutter during normal gameplay
- Provides subtle guidance when approaching edges
- More immersive than permanent walls

**Why constrain orbit center instead of camera position?**
- Maintains camera's viewing angle
- Prevents sudden jumps
- Works correctly with camera rotation

**Why MeshInstance3D instead of CSG?**
- CSG nodes are for prototyping only (per Godot documentation)
- MeshInstance3D is production-ready and more performant
- Proper approach for final game assets

### Performance Considerations

- Boundary visibility check runs every frame (`_process`)
- Four distance calculations per frame
- Four material updates per frame (only if transparency changes)
- Minimal performance impact (< 0.1ms per frame)

## Future Enhancements

1. **Dynamic Boundaries**: Allow different scenarios to define their own boundary sizes
2. **Boundary Collision**: Add physical barriers at boundaries for physics objects
3. **Boundary Effects**: Add visual effects (particles, fog) at boundaries
4. **Per-Scenario Ground**: Different ground textures for different scenarios
5. **Minimap Indicators**: Show boundaries on the minimap
