# Survivor Panic Behavior - Testing Guide

## Overview
This document describes how to test the new survivor panic behavior feature that makes survivors run around when enemies are nearby.

## What Was Implemented

### PanicBehavior Component
A new component (`Common/Components/panic_behavior/panic_behavior.gd`) that:
- Detects enemies within a 10-unit radius
- Makes survivors move erratically within a 3-unit radius of their spawn point
- Switches between Run and Idle animations based on movement
- Changes direction every 1.5 seconds when panicking
- Automatically stops panicking when enemies move away

### Integration
The panic behavior is automatically added to all survivors via `target.gd`, requiring no manual scene modification.

## How to Test

### Automated Tests
Run the unit tests to verify the logic:
```bash
./run_tests.sh test_panic_behavior
```

All tests should pass, verifying:
- Initialization and setup
- Enemy detection at various distances
- Panic state transitions
- Movement constraints (stays within radius)
- Multiple enemy scenarios

### Manual Testing

1. **Start the Game**
   ```bash
   ./godot --path . "res://Stages/Game/main/main.tscn"
   ```

2. **Observe Survivor Behavior**
   - At the start, survivors should be idle (playing Idle animation)
   - When first zombie wave spawns and gets close (within 10 units):
     - Survivors should start running around erratically
     - They should use the "Run" animation
     - They should never move more than 3 units from their starting position
   
3. **Test Panic Radius**
   - Observe that panic only triggers when enemies are nearby
   - Survivors should stop panicking when enemies are eliminated or move far away
   - Multiple survivors should each panic independently based on nearby threats

4. **Verify Movement Constraints**
   - Watch that survivors never leave their designated area
   - They should return to idle animation when they reach a panic destination and wait
   - Movement should look random and comedic, not systematic

## Configuration

You can adjust panic behavior parameters in the PanicBehavior class:
- `panic_detection_radius`: Distance at which enemies trigger panic (default: 10.0)
- `panic_move_radius`: Max distance survivor can move from spawn (default: 3.0)
- `panic_move_speed`: Movement speed when panicking (default: 3.0)
- `panic_move_interval`: Time between direction changes (default: 1.5)

## Expected Visual Behavior

### When Calm (No Enemies Nearby)
- Survivor stands still at spawn position
- Plays "Idle" animation
- No movement

### When Panicking (Enemies Nearby)
- Survivor runs to random nearby points
- Plays "Run" animation while moving
- Briefly plays "Idle" when reaching destination
- Chooses new random destination every 1.5 seconds
- Stays within 3 units of spawn point
- Faces direction of movement

### Transition
- Smooth transition from Idle to Run when panic starts
- Returns to spawn position and Idle animation when enemies leave

## Troubleshooting

### Survivors Not Panicking
- Check that enemies are in the "enemies" group (they should be by default)
- Verify enemies are within 10 units of survivor
- Check console logs for "Survivor started panicking!" messages

### Survivors Moving Too Far
- Verify `panic_move_radius` is set correctly (default: 3.0)
- Check that `spawn_position` is being set properly in `_ready()`

### Animation Not Playing
- Ensure AnimationPlayer has "Run" and "Idle" animations
- Check that `animation_player_path` is correct (default: "../AnimationPlayer")
- Look for warnings about AnimationPlayer not found

## Performance Notes
- Panic behavior uses `_process()` for smooth movement
- Enemy detection checks all enemies in "enemies" group each frame
- Performance impact should be minimal for reasonable numbers of survivors and enemies

## Future Enhancements
Potential improvements for the future:
- Add panic voice/sound effects
- Add visual indicators (sweat drops, exclamation marks)
- Vary panic behavior based on survivor personality
- Make survivors look toward nearest enemy while panicking
- Add stumbling/wobbling animations for more comedy
