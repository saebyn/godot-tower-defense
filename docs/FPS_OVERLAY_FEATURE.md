# FPS/Stats Overlay Feature

## Overview
A toggleable FPS and performance statistics overlay has been added to the game, allowing players and developers to monitor real-time performance metrics.

## Usage

### Toggling the Overlay
- Press **F3** to toggle the FPS overlay on/off
- The overlay appears in the **top-right corner** of the screen
- Starts **hidden by default**

### Displayed Information
The overlay shows the following performance metrics:
- **FPS**: Current frames per second
- **Frame Time**: Time taken to process each frame (in milliseconds)
- **Memory**: Total memory usage (in megabytes)
- **Objects**: Total number of objects in the scene
- **Nodes**: Total number of nodes in the scene tree

### Separate from Game Stats
The FPS overlay (F3) is separate from the game statistics display (T key):
- **F3**: Toggle FPS/performance overlay (compact, top-right corner)
- **T**: Toggle game statistics (enemies defeated, obstacles placed, resources, etc.)

Both overlays can be shown simultaneously if desired.

## Implementation Details

### Files Added/Modified
- **Added**: `Common/UI/fps_overlay/fps_overlay.gd` - FPS overlay script
- **Added**: `Common/UI/fps_overlay/fps_overlay.tscn` - FPS overlay scene
- **Modified**: `Stages/UI/main_ui/ui.gd` - Main UI controller (handles toggle input)
- **Modified**: `Stages/UI/main_ui/ui.tscn` - Main UI scene (includes FPS overlay)
- **Modified**: `project.godot` - Added toggle_fps input action

### Input Action
- **Action name**: `toggle_fps`
- **Default key**: F3 (key code 4194332)
- **Configured in**: `project.godot`

### Technical Notes
- The overlay uses Godot's `Performance` class to gather metrics
- Updates every frame when visible for real-time monitoring
- Has high z-index (100) to ensure it's always on top of other UI elements
- Background has semi-transparent black (0, 0, 0, 0.7) for readability
- Minimal performance impact - only processes when visible
- Compatible with Godot 4.4

## Key Benefits
1. **Performance Monitoring**: Quickly check game performance without external tools
2. **Debugging**: Identify performance issues during development
3. **Optimization**: Monitor impact of changes on FPS and memory
4. **Non-intrusive**: Compact overlay in corner, easily toggleable
5. **Real-time Updates**: Shows current metrics every frame
