# Manual Test: Obstacle Hover Tooltip on Removal

## Test Setup
1. Open the project in Godot Editor
2. Open scene: `res://Stages/Game/main/main.tscn`
3. Press F5 to run the game
4. Ensure you have sufficient scrap to place support towers/buff obstacles

## Background
This test verifies that when an obstacle with a hover tooltip (e.g., a support tower or any ranged obstacle) is removed while being hovered over, the tooltip and range indicator are properly cleared and don't remain on screen.

## Test Cases

### Test 1: Remove Hovered Support Tower/Buff Obstacle
**Objective**: Verify tooltip disappears when removing a hovered support tower

**Steps**:
1. Start the game
2. Place a support tower (buff obstacle) on the ground
3. Move mouse over the support tower to trigger hover state
4. Verify tooltip appears showing tower stats
5. Verify range indicator (circular disc) appears under the tower
6. While keeping mouse over the tower, right-click to remove it
7. Observe if tooltip remains visible

**Expected Result**:
- Tooltip immediately disappears when tower is removed
- Range indicator disappears when tower is removed
- No ghost tooltip or range indicator remains on screen
- Debug log shows "Cleared hover state for removed obstacle"
- Debug log shows "Hid tooltip for removed obstacle"

**Failure Criteria**:
- Tooltip remains visible after removal
- Range indicator remains visible after removal
- Game crashes or errors occur

### Test 2: Remove Hovered Shooting Obstacle
**Objective**: Verify tooltip disappears when removing a hovered shooting obstacle

**Steps**:
1. Start the game
2. Place a shooting obstacle (turret) on the ground
3. Move mouse over the shooting obstacle to trigger hover state
4. Verify tooltip appears showing obstacle stats
5. Verify range indicator appears
6. While keeping mouse over the obstacle, right-click to remove it
7. Observe if tooltip remains visible

**Expected Result**:
- Tooltip immediately disappears when obstacle is removed
- Range indicator disappears when obstacle is removed
- No ghost tooltip remains on screen

### Test 3: Remove Non-Hovered Obstacle
**Objective**: Verify normal removal works correctly when obstacle is not hovered

**Steps**:
1. Start the game
2. Place a support tower on the ground
3. Move mouse AWAY from the tower (ensure not hovering)
4. Move mouse over the tower
5. Move mouse away again (ensure tooltip closes)
6. Right-click on the tower to remove it (without hovering first)

**Expected Result**:
- Obstacle is removed successfully
- No errors occur
- Refund is properly credited

### Test 4: Remove Hovered Obstacle Then Hover Another
**Objective**: Verify tooltip system continues working after removal

**Steps**:
1. Start the game
2. Place two support towers near each other
3. Hover over tower #1, verify tooltip shows
4. While hovering tower #1, right-click to remove it
5. Move mouse to tower #2
6. Verify tooltip appears for tower #2

**Expected Result**:
- Tower #1 tooltip disappears on removal
- Tower #2 tooltip appears correctly
- No interference between the two hover events
- System continues to work normally

### Test 5: Rapid Hover and Remove
**Objective**: Verify tooltip handles rapid interactions gracefully

**Steps**:
1. Start the game
2. Place a support tower
3. Quickly move mouse over tower (hover)
4. Immediately right-click to remove (before tooltip fully renders)
5. Move mouse away

**Expected Result**:
- No crash or errors occur
- No tooltip remains visible
- System remains stable

## Notes
- Support towers (buff obstacles) extend from `Entity_RangedObstacle`, so they have range indicators
- Regular obstacles may not show range indicators but can still show tooltips
- The fix handles both `_hovered_ranged_obstacle` and `_obstacle_tooltip.current_obstacle` to ensure comprehensive cleanup
- Debug logging helps verify the cleanup code paths are executed

## Success Criteria
All test cases pass with expected results. No tooltips or range indicators remain on screen after removing hovered obstacles.
