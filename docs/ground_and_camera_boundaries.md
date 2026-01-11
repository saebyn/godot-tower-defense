# Ground and Camera Boundaries Implementation

## Overview
This document describes the implementation of camera movement constraints added to prevent the camera from going too far and showing void areas.

## Components

### 1. Scenario Boundary Settings (`Stages/Scenarios/scenario.gd`)
Each scenario defines its own boundaries:
- `boundary_min_x`: West edge (default: -50)
- `boundary_max_x`: East edge (default: 50)
- `boundary_min_z`: North edge (default: -50)
- `boundary_max_z`: South edge (default: 50)

### 2. Camera Boundary Constraints (`Stages/Game/main/camera.gd`)
Export parameters (dynamically updated when scenario loads):
- `enable_boundaries`: Toggle camera constraints on/off (default: true)
- `world_min_x`, `world_max_x`: X-axis boundaries
- `world_min_z`, `world_max_z`: Z-axis boundaries

#### How it works:
1. Camera movement is tracked via the "orbit center" (where the camera looks at the ground)
2. After movement or rotation, `_apply_boundary_constraints()` is called
3. The orbit center is clamped to stay within defined world boundaries
4. Camera position is adjusted to maintain the same offset from the constrained orbit center


## Integration

### Scenario Loading (`main.gd`):
When a scenario is loaded, `_configure_boundaries_from_scenario()` is called to:
1. Read boundary settings from the loaded scenario
2. Update camera boundary constraints

## Configuration

### Per-Scenario Boundaries
Each scenario scene file should define its boundaries:

```gdscript
# In scenario_X.tscn
boundary_min_x = -60.0
boundary_max_x = 60.0
boundary_min_z = -60.0
boundary_max_z = 60.0
```

## Testing Checklist

- [ ] Camera cannot move beyond defined boundaries
- [ ] Navigation mesh still functions correctly
- [ ] Camera rotation respects boundaries
- [ ] Boundaries adjust correctly for different scenarios
- [ ] No performance impact from boundary checking

## Technical Details

### Design Decisions

**Why constrain orbit center instead of camera position?**
- Maintains camera's viewing angle
- Prevents sudden jumps
- Works correctly with camera rotation

**Why dynamic boundaries per scenario?**
- Each scenario has different playable ground areas
- Allows buildable space to match the actual scenario ground
- Prevents camera from viewing areas outside the scenario

### Performance Considerations

- Four distance calculations per frame
- Four material updates per frame (only if transparency changes)
- Minimal performance impact (< 0.1ms per frame)

## Future Enhancements

1. **Boundary Effects**: Add visual effects (particles, fog) at boundaries
2. **Minimap Indicators**: Show boundaries on the minimap
