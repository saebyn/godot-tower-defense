# Obstacle Placement Hotkeys

This document describes the newly implemented hotkey system for obstacle placement in the Tower Defense game.

## Overview

Players can now use configurable hotkeys (keys 1-5) to quickly place obstacles without clicking UI buttons. This feature integrates seamlessly with the existing obstacle placement system.

## Features

### Available Hotkeys
- **Key 1**: Place first obstacle type (Turret - Cost: 20)
- **Key 2**: Place second obstacle type (Wall - Cost: 10)
- **Keys 3-5**: Available for additional obstacle types (currently none)

### Configuration
The hotkey system is configurable via project settings:

```ini
[obstacle_hotkeys]
max_hotkeys=5      # Maximum number of hotkeys (1-5)
enabled=true       # Enable/disable the hotkey system
```

### Input Actions
The following input actions are defined in `project.godot`:
- `place_obstacle_hotkey_1` (Key: 1)
- `place_obstacle_hotkey_2` (Key: 2)  
- `place_obstacle_hotkey_3` (Key: 3)
- `place_obstacle_hotkey_4` (Key: 4)
- `place_obstacle_hotkey_5` (Key: 5)

## Implementation Details

### Code Changes

1. **project.godot**: Added input actions and configuration settings
2. **main.gd**: Added `_handle_obstacle_hotkeys()` function that:
   - Checks if hotkeys are enabled
   - Maps hotkey numbers to available obstacles from ObstacleRegistry
   - Triggers existing obstacle placement system
   - Includes logging for debugging

### Integration

The hotkey system integrates with existing systems:
- **ObstacleRegistry**: Dynamically loads available obstacles
- **Obstacle Placement**: Uses existing `_on_obstacle_spawn_requested()` method
- **Currency System**: Respects obstacle costs and player currency
- **UI System**: Works alongside existing UI buttons

## Usage

1. **Start the game** - Hotkeys are automatically available
2. **Press number keys 1-2** to select and place obstacles:
   - Press `1` to start placing a Turret (costs 20 currency)
   - Press `2` to start placing a Wall (costs 10 currency)
3. **Place the obstacle** using existing controls:
   - Move mouse to position the obstacle
   - Left click to place
   - Right click or ESC to cancel
   - Q/F to rotate (if applicable)

## Validation

The system has been thoroughly tested:
- ✅ All 18 automated tests pass
- ✅ Project settings properly configured
- ✅ Input actions correctly mapped to keys 1-5
- ✅ ObstacleRegistry integration working
- ✅ Main game scene integration verified
- ✅ Compatible with existing obstacle placement system

## Future Enhancements

- **Customizable key bindings**: Allow players to remap hotkeys
- **Visual hotkey indicators**: Show hotkey numbers on UI buttons
- **More obstacle types**: Support for additional obstacles beyond current 2
- **Hotkey feedback**: Visual/audio confirmation when hotkeys are pressed

## Configuration Examples

### Disable hotkeys completely:
```ini
[obstacle_hotkeys]
enabled=false
```

### Limit to 3 hotkeys:
```ini
[obstacle_hotkeys]
max_hotkeys=3
enabled=true
```

The hotkey system is designed to be minimal, configurable, and seamlessly integrated with the existing game systems.