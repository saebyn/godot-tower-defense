# Manual Test: Ground and Camera Boundaries

## Test Setup
1. Open the project in Godot Editor
2. Open scene: `res://Stages/Game/main/main.tscn`
3. Press F5 to run the game

## Test Cases

### Test 1: Visual Ground Plane
**Objective**: Verify flat ground is visible beyond landscape edges

**Steps**:
1. Start the game
2. Zoom out to maximum zoom level
3. Move camera to each edge of the landscape
4. Look for brown/earth-colored flat ground beyond landscape

**Expected Result**:
- Flat ground plane is visible beyond landscape edges
- Ground color is brown/earth tone (RGB: 0.3, 0.25, 0.2)
- No void/empty space visible

### Test 2: Boundary Markers Fade In
**Objective**: Verify red boundary walls appear when approaching edges

**Steps**:
1. Start at center of map
2. Move camera toward North edge (negative Z)
3. Continue until camera stops
4. Repeat for South, East, and West edges

**Expected Result**:
- Red glowing wall appears gradually (not suddenly)
- Wall becomes visible around 50 units from boundary
- Wall is semi-transparent (max 50% opacity)
- Wall has red glow/emission

### Test 3: Camera Boundary Constraints
**Objective**: Verify camera cannot move beyond boundaries

**Steps**:
1. Move camera to North edge
2. Try to move further North (hold W key)
3. Verify camera stops at boundary
4. Try moving in other directions while at boundary
5. Repeat for all four edges

**Expected Result**:
- Camera stops at boundary (orbit center at ±200 units)
- Camera can still move parallel to boundary
- Camera can move away from boundary
- Camera cannot go beyond boundary

### Test 4: Camera Rotation at Boundaries
**Objective**: Verify rotation works correctly at boundaries

**Steps**:
1. Move camera to any edge
2. Press Q to rotate left 90°
3. Press E to rotate right 90°
4. Verify camera stays within bounds during rotation

**Expected Result**:
- Camera rotates smoothly
- Orbit center stays within boundaries during rotation
- No sudden jumps or position changes
- Boundary markers update correctly after rotation

### Test 5: Camera Zoom at Boundaries
**Objective**: Verify zoom works normally at boundaries

**Steps**:
1. Move camera to edge
2. Zoom in (mouse wheel up or -)
3. Zoom out (mouse wheel down or +)
4. Verify boundary constraints still apply

**Expected Result**:
- Zoom works normally
- Camera stays within boundaries while zooming
- Boundary markers remain visible if within fade distance

### Test 6: Corner Boundaries
**Objective**: Verify multiple boundaries can be visible simultaneously

**Steps**:
1. Move camera to Northeast corner
2. Observe both North and East boundary markers
3. Repeat for all four corners

**Expected Result**:
- Two boundary walls visible at corners
- Both walls fade in/out based on distance
- Camera cannot move beyond either boundary
- Smooth movement along corner

### Test 7: Fast Movement to Boundaries
**Objective**: Verify boundary constraints work with rapid input

**Steps**:
1. Start at center
2. Hold movement key continuously toward edge
3. Observe behavior when reaching boundary

**Expected Result**:
- Camera stops smoothly at boundary
- No overshooting or bouncing
- Boundary marker fades in smoothly
- No visual glitches

### Test 8: Navigation Mesh Integration
**Objective**: Verify enemies can still pathfind on ground

**Steps**:
1. Start game and spawn enemies
2. Wait for enemies to navigate to target
3. Verify navigation works correctly

**Expected Result**:
- Enemies navigate normally
- No pathfinding errors in console
- Navigation mesh includes ground plane
- Enemies don't fall through ground

## Test Data Recording

### Boundary Positions
- North: Z = -200
- South: Z = +200
- East: X = +200
- West: X = -200

### Expected Measurements
- Ground plane size: 5000x5000 units
- Ground plane position: Y = -2
- Boundary wall height: 10 units
- Fade distance: 50 units
- Max boundary opacity: 50%

## Troubleshooting

### Ground Not Visible
- Check `GroundWithBoundaries` node is present in Main scene
- Verify ground plane is at Y=-2 (below landscape)
- Check camera can see that far

### Boundaries Not Fading
- Check `world_boundary_markers.gd` is attached to node
- Verify camera reference is set correctly
- Check console for script errors

### Camera Moves Beyond Boundaries
- Check `enable_boundaries` is true in camera.gd
- Verify boundary values match scene positions
- Check `_apply_boundary_constraints()` is being called

### Performance Issues
- Check FPS (should be 60+)
- Boundary checks are very lightweight
- If issues persist, may be unrelated to boundaries

## Success Criteria
All test cases pass with expected results:
- [ ] Ground plane visible
- [ ] Boundaries fade in smoothly
- [ ] Camera respects boundaries
- [ ] Rotation works at boundaries
- [ ] Zoom works at boundaries
- [ ] Corners work correctly
- [ ] Fast movement handled smoothly
- [ ] Navigation mesh works correctly

## Notes
Record any observations, bugs, or unexpected behavior here during testing.
