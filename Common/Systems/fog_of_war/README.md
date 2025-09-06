# Fog of War System

This document describes the fog of war implementation for the tower defense game.

## Overview

The fog of war system provides strategic visibility mechanics where:
- Initially, all areas are hidden in fog
- Placed obstacles act as vision sources that reveal surrounding areas
- Enemies are only visible when in revealed areas
- Areas remain explored (dimmed) after vision sources are removed

## Architecture

### Core Components

1. **FogOfWar** (`Common/Systems/fog_of_war/`)
   - Main system managing the fog grid and visual overlay
   - Handles vision calculations and fog state updates
   - Provides grid-based approach for performance

2. **VisionSource** (`Common/Components/vision/`)
   - Component that can be attached to any entity to provide vision
   - Configurable vision range
   - Automatically registers/unregisters with the fog system

3. **FogOfWarConfig** (`Config/FogOfWar/`)
   - Resource for storing fog configuration
   - Allows data-driven setup of fog parameters

## Integration

### Adding Vision to Entities

To make an entity provide vision:

1. Add VisionSource as a child node
2. Configure the vision_range property
3. The component automatically handles registration

Example in scene:
```
[node name="VisionSource" parent="." instance=ExtResource("path/to/vision_source.tscn")]
vision_range = 15.0
```

### Checking Visibility

Entities can check if they're visible:

```gdscript
var fog_of_war = get_tree().get_first_node_in_group("fog_of_war")
if fog_of_war and fog_of_war.has_method("is_cell_visible"):
    var is_visible = fog_of_war.is_cell_visible(global_position)
```

## Configuration

The fog system can be configured through exported properties:

- `grid_size`: Size of each fog cell in world units
- `map_width/height`: Dimensions of the fog grid
- `map_center`: Center point of the map for positioning
- `fog_color`: Color and opacity of unexplored areas
- `explored_color`: Color of previously explored areas

## Performance

- Grid-based approach scales well with map size
- Vision calculations use simple circular areas
- Visual updates are optimized to only run when needed
- Debug mode available for development

## Future Enhancements

Possible improvements:
- Line-of-sight calculations for realistic vision blocking
- Shader-based rendering for better visual effects
- Dynamic fog colors based on game state
- Integration with minimap systems