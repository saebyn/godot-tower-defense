# Damage Numbers System

## Overview

The damage numbers system provides visual feedback when enemies take damage or when scrap is collected. Numbers float upward and fade out, with different colors indicating different damage types.

## Components

### UI_DamageNumber (`Common/UI/damage_numbers/damage_number.gd`)

A Node3D-based component that displays a single damage number.

**Features:**
- 3D billboarded Label3D that faces the camera
- Color-coded by damage type:
  - White: Normal damage
  - Red: Critical damage (larger font)
  - Orange: Fire damage
  - Cyan: Ice damage
  - Purple: Poison damage
  - Gold: Scrap gain (with "+" prefix)
- Floating animation (moves upward)
- Fade-out animation (becomes transparent)
- Self-deactivates after animation completes

**Key Methods:**
- `display_damage(amount, world_position, damage_type)`: Show a damage number
- `deactivate()`: Stop animation and return to pool
- `is_available()`: Check if ready for reuse

**Configuration:**
- `float_speed`: Speed of upward movement (default: 1.0)
- `fade_duration`: Duration of fade animation (default: 1.5 seconds)
- `float_distance`: Distance traveled upward (default: 2.0)

### UI_DamageNumberManager (`Common/UI/damage_numbers/damage_number_manager.gd`)

Manages the pooling and display of damage numbers for performance.

**Features:**
- Object pooling system (reuses instances)
- Automatic connection to enemies
- Settings integration for accessibility
- Audio feedback for scrap collection
- Performance optimization (max 30 simultaneous numbers)

**Key Methods:**
- `show_damage(amount, world_position, damage_type)`: Display a damage number
- `show_scrap_gain(amount, world_position)`: Display a scrap gain number
- `connect_to_enemy(enemy)`: Connect to an enemy's health and death signals
- `connect_to_health_component(health)`: Connect to a health component directly

**Configuration:**
- `initial_pool_size`: Starting pool size (default: 10)
- `max_pool_size`: Maximum pool size (default: 30)
- `damage_numbers_enabled`: Toggle damage numbers on/off
- `scrap_numbers_enabled`: Toggle scrap numbers on/off
- `number_size_multiplier`: Adjust number size (default: 1.0)

## Integration

### Automatic Setup

The damage number manager is automatically created in scenarios:

```gdscript
# In Stage_Scenario._ready()
if not damage_number_manager:
  _create_damage_number_manager()
```

### Enemy Connection

When enemies spawn, the manager automatically connects to them:

```gdscript
# In Stage_Scenario._on_enemy_spawned()
if damage_number_manager:
  damage_number_manager.connect_to_enemy(enemy)
```

This connection:
1. Finds the enemy's health component (via metadata or child search)
2. Connects to the `damaged` signal to show damage numbers
3. Connects to the `died` signal to show scrap gain

### Manual Setup

You can also manually add the damage number manager to a scene:

1. Instance `Common/UI/damage_numbers/damage_number_manager.tscn`
2. Add it as a child of your scene
3. Export reference in Stage_Scenario

## Settings Integration

The system integrates with SettingsManager for accessibility:

```gdscript
# In SettingsManager
settings = {
  "damage_numbers_enabled": true,
  "scrap_numbers_enabled": true,
  "number_size_multiplier": 1.0
}
```

Users can:
- Toggle damage numbers on/off
- Toggle scrap numbers on/off
- Adjust number size (0.5 to 2.0)

## Performance

### Object Pooling

Instead of creating/destroying nodes constantly:
1. Pool starts with 10 pre-created instances
2. Inactive instances are reused
3. Pool expands up to 30 instances if needed
4. When full, oldest active instance is recycled

### Optimization Tips

- Keep `max_pool_size` reasonable (20-30)
- Use settings to disable if performance issues occur
- Numbers automatically cull when outside view (future improvement)

## Testing

Unit tests are available in `tests/unit/test_damage_number_manager.gd`:

```bash
./godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_damage_number_manager.gd
```

Tests cover:
- Pool initialization and expansion
- Settings respect (enabled/disabled)
- Deactivation timing
- Enemy connection
- Pool size limits

## Future Enhancements

Potential improvements for future development:

1. **Visual Improvements:**
   - Add particle effects on critical hits
   - Implement arc animation toward currency UI for scrap
   - Add shake effect for large damage numbers
   - Support for custom fonts per damage type

2. **Performance:**
   - Cull numbers outside camera view
   - Use shader for fade instead of modulate
   - Batch nearby damage into single larger number
   - LOD system (reduce detail at distance)

3. **Accessibility:**
   - Reduce animation mode (no float/fade, just pop)
   - High contrast mode
   - Sound cues for damage types
   - Screen reader support

4. **Gameplay:**
   - Combo counter (rapid hits)
   - Damage type icons
   - Critical hit animations
   - Damage over time indicators

## Troubleshooting

### Numbers not appearing

1. Check that damage_numbers_enabled is true in settings
2. Verify the damage number manager exists in the scene
3. Ensure enemies are being connected properly
4. Check that health component is emitting `damaged` signal

### Performance issues

1. Reduce max_pool_size
2. Disable damage numbers in settings
3. Check for memory leaks (numbers not deactivating)
4. Profile with Godot profiler

### Numbers appearing at wrong position

1. Verify enemy.global_position is correct
2. Check Camera3D is in correct position
3. Adjust vertical offset (Vector3.UP * 2.0)
4. Ensure billboard is enabled on Label3D

## Architecture Notes

The system follows Godot best practices:
- Uses signals for loose coupling
- Implements object pooling for performance
- Integrates with existing autoload systems (CurrencyManager, AudioManager, SettingsManager)
- Minimal changes to existing code (only scenario.gd modified)
- Fully tested with unit tests
