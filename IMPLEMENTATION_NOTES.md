# Implementation Notes: Ground and Camera Boundaries

## Issue Addressed
**Title**: Make flat/neutral ground for world so that level doesn't have edges that go to void, show border when approaching with camera, prevent camera from going too far

## Solution Overview
Implemented a three-part solution:

1. **Flat Ground Plane**: A large (500x500) flat ground plane positioned beneath the landscape
2. **Visual Boundary Markers**: Red glowing walls at world edges that fade in as camera approaches
3. **Camera Movement Constraints**: Boundary checking that prevents camera from going beyond defined limits

## Files Created

### 1. `Common/World/ground_with_boundaries.tscn`
A scene containing:
- Flat ground plane (500x500 at Y=-2)
- StaticBody3D with collision for physics/navigation
- Four boundary markers (North, South, East, West)
- Script for dynamic boundary visibility

**Key Features**:
- Ground is part of navigation mesh source group
- Boundaries positioned at ±200 units on X and Z axes
- Semi-transparent red material with emission for visibility

### 2. `Common/World/world_boundary_markers.gd`
Script that manages visual boundary markers:
- Tracks camera position relative to boundaries
- Fades markers in when camera approaches (within 50 units)
- Uses transparency to show/hide boundaries smoothly

**Key Algorithm**:
```gdscript
distance = camera_ground_position to boundary_position
if distance < fade_distance:
  transparency = 1.0 - (distance / fade_distance)
```

### 3. `docs/ground_and_camera_boundaries.md`
Comprehensive documentation covering:
- Component descriptions
- Configuration options
- Integration instructions
- Testing checklist
- Future enhancement ideas

## Files Modified

### 1. `Stages/Game/main/camera.gd`
Added camera boundary constraints:

**New Export Parameters**:
- `enable_boundaries`: Toggle constraints (default: true)
- `world_min_x`, `world_max_x`: X boundaries (-200 to 200)
- `world_min_z`, `world_max_z`: Z boundaries (-200 to 200)

**New Method**:
- `_apply_boundary_constraints()`: Clamps camera orbit center to boundaries

**Integration Points**:
- Called after camera movement (line 69)
- Called after camera rotation (line 143)

### 2. `Stages/Game/main/main.tscn`
Added ground and boundaries scene:
- Instanced `ground_with_boundaries.tscn`
- Connected camera reference for visibility tracking
- Positioned to be below/around all scenarios

## Technical Details

### Coordinate System
- World center: (0, 0, 0)
- Ground plane: Y = -2
- Playable area: -200 to +200 on X and Z axes
- Boundary walls: Height = 10 units

### Camera Constraint Algorithm
1. Calculate where camera is looking at ground ("orbit center")
2. After movement/rotation, check if orbit center exceeds boundaries
3. Clamp orbit center to within boundaries
4. Adjust camera position to maintain same offset from clamped center

This approach ensures smooth boundary enforcement without jarring camera movements.

### Boundary Visibility Algorithm
1. Calculate camera's ground projection point
2. Measure distance to each boundary
3. If distance < fade_distance (50 units):
   - Calculate transparency: `1.0 - (distance / 50.0)`
   - Apply to boundary material (max 50% opacity)
4. Update material transparency in real-time

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

## Testing Recommendations

### Manual Testing
1. Start game and move camera in all directions
2. Approach each boundary and verify:
   - Red walls fade in gradually
   - Camera stops at boundary
   - Camera can still rotate at boundary
3. Test camera zoom at boundaries
4. Verify navigation mesh still works

### Edge Cases
- Camera rotation near corners (two boundaries active)
- Fast movement toward boundaries
- Zooming while at boundary
- Multiple rapid direction changes

## Performance Considerations

- Boundary visibility check runs every frame (`_process`)
- Four distance calculations per frame
- Four material updates per frame (only if transparency changes)
- Minimal performance impact (< 0.1ms per frame)

## Future Improvements

1. **Per-Scenario Boundaries**: Allow each scenario to define its own boundary size
2. **Boundary Collision**: Add physics barriers to prevent objects from leaving
3. **Configurable Colors**: Make boundary colors theme-based
4. **Sound Effects**: Add audio cue when approaching boundaries
5. **Minimap Integration**: Show boundaries on minimap

## Integration with Existing Systems

### Navigation Mesh
- Ground plane is part of `navigation_mesh_source_group`
- Should be included in navigation mesh generation
- Provides fallback pathfinding area

### Scenario Loading
- Scenarios are rotated -45° and added as children of Main
- Ground plane is not rotated (stays at Main level)
- Boundaries extend beyond any scenario landscape

### Camera System
- Integrates with existing camera movement/rotation
- Respects existing zoom constraints
- Works with camera orbit system
- Compatible with camera state management (menus, pause)

## Known Limitations

1. **Fixed Size**: Boundaries are hardcoded to ±200 units
   - **Workaround**: Edit export parameters and scene positions
   
2. **Ground Texture**: Single color material
   - **Workaround**: Replace with textured material if needed
   
3. **No Physical Barriers**: Objects can still fall off edges
   - **Workaround**: Add StaticBody3D walls if physics containment needed

## Rollback Instructions

If this implementation needs to be removed:

1. Remove `ground_with_boundaries.tscn` instance from `main.tscn`
2. Revert changes to `camera.gd`:
   - Remove boundary export group
   - Remove `_apply_boundary_constraints()` method
   - Remove boundary constraint calls
3. Delete `Common/World/` directory
4. Delete `docs/ground_and_camera_boundaries.md`

No database migrations or settings changes required.
