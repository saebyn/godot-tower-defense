# Quick Reference: Ground and Camera Boundaries

## What Was Implemented

✅ Flat ground plane extending beyond all landscapes  
✅ Visual boundary markers that fade in when approaching  
✅ Camera movement constraints to prevent going too far  

## Key Files

| File | Purpose |
|------|---------|
| `Common/World/ground_with_boundaries.tscn` | Ground plane and boundary markers scene |
| `Common/World/world_boundary_markers.gd` | Script for dynamic boundary visibility |
| `Stages/Game/main/camera.gd` | Camera constraint implementation |
| `Stages/Game/main/main.tscn` | Integration of ground system |

## Quick Configuration

### Change World Size

**In `camera.gd` (Camera3D node)**:
```gdscript
@export var world_min_x: float = -300.0  # Default: -200.0
@export var world_max_x: float = 300.0   # Default: 200.0
@export var world_min_z: float = -300.0  # Default: -200.0
@export var world_max_z: float = 300.0   # Default: 200.0
```

**In `ground_with_boundaries.tscn` scene**:
- Update boundary positions in scene tree to match above values
- Adjust ground plane size if needed (500x500 is sufficient for most cases)

**In `world_boundary_markers.gd` script parameters**:
- Update `world_min_x/z` and `world_max_x/z` to match camera values

### Adjust Boundary Appearance

**In `ground_with_boundaries.tscn`**:
- Select any boundary (e.g., NorthBoundary)
- Edit `StandardMaterial3D_boundary`
- Modify `albedo_color` for boundary color
- Modify `emission_energy_multiplier` for glow intensity

**Via Export Parameters**:
```gdscript
@export var fade_distance: float = 50.0          # When markers start appearing
@export var max_boundary_opacity: float = 0.5    # Maximum visibility (0.0-1.0)
```

### Disable Boundaries (If Needed)

**In Camera3D inspector**:
```gdscript
@export var enable_boundaries: bool = false  # Set to false to disable
```

## Important Coordinates

| Element | Position | Size |
|---------|----------|------|
| World Center | (0, 0, 0) | - |
| Ground Plane | Y = -2 | 500x500 |
| Boundaries | ±200 on X/Z | 10 units high |
| Fade Zone | 50 units from boundary | - |

## Testing Checklist

Run through `tests/manual/test_ground_boundaries.md` for comprehensive testing.

Quick smoke test:
1. Start game
2. Move camera to each edge (WASD keys)
3. Verify red walls appear and camera stops
4. Zoom out - verify no void visible

## Common Issues

### Boundaries Not Visible
- Check camera reference is set in GroundWithBoundaries node
- Verify `world_boundary_markers.gd` is attached
- Check console for errors

### Camera Goes Beyond Boundaries
- Verify `enable_boundaries = true` in Camera3D
- Check boundary values match in camera.gd and scene
- Ensure `_apply_boundary_constraints()` is called

### Ground Not Visible
- Check GroundWithBoundaries is child of Main
- Verify position is Y=-2 (below landscape)
- Check if camera far plane includes that distance

## Performance Notes

- Boundary checks: ~0.1ms per frame (negligible)
- Material updates: Only when transparency changes
- Safe for all platforms

## Further Documentation

- **Full Guide**: `docs/ground_and_camera_boundaries.md`
- **Technical Details**: `IMPLEMENTATION_NOTES.md`
- **Architecture**: `docs/ground_boundaries_diagram.txt`
- **Testing**: `tests/manual/test_ground_boundaries.md`

## For Future Scenarios

Each scenario can override boundary sizes by modifying export parameters on instanced nodes.
Ground system is at Main level (not rotated with scenarios), so it works universally.
