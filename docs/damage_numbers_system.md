# Damage Numbers System

## Overview

The damage numbers system provides visual feedback when entities take damage or when scrap is earned. Numbers float upward and fade out, with different colors indicating different types of feedback.

## Component Integration

### Damage Numbers (Component_Health)

The damage number functionality is built directly into the `Component_Health` component for simplicity and maintainability.

**Features:**
- Automatic damage number spawning when `take_damage()` is called
- Color-coded by damage source (fire=orange, ice=cyan, poison=purple, etc.)
- Object pooling for performance (max 10 instances per health component)
- Configurable via `show_damage_numbers` export variable

**Configuration:**
- `show_damage_numbers: bool = true` - Toggle damage numbers on/off per entity

### Scrap Gain Feedback (Enemy)

The scrap gain feedback is integrated into the enemy death handler.

**Features:**
- Gold-colored "+X" text appears above defeated enemies
- Shows the scrap reward value when enemy dies
- Configurable via `show_scrap_gain` export variable
- Reuses the same `UI_DamageNumber` infrastructure

**Configuration:**
- `show_scrap_gain: bool = true` - Toggle scrap gain display per enemy

### UI_DamageNumber (`Common/UI/damage_numbers/damage_number.gd`)

A Node3D-based component that displays a single floating number.

**Features:**
- 3D billboarded Label3D that faces the camera
- Color-coded by type:
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
- `display_damage(amount, world_position, damage_type)`: Show a number
- `deactivate()`: Stop animation and mark as available for reuse
- `is_available()`: Check if ready for reuse

**Configuration:**
- `float_speed`: Speed of upward movement (default: 1.0)
- `fade_duration`: Duration of fade animation (default: 1.5 seconds)
- `float_distance`: Distance traveled upward (default: 2.0)

## How It Works

### Damage Numbers
1. **Entity Takes Damage**: When `Component_Health.take_damage()` is called
2. **Check Setting**: If `show_damage_numbers` is true, proceed
3. **Get/Create Number**: Get available number from pool or create new (up to 10)
4. **Display**: Position above entity, set color based on damage source
5. **Animate**: Float upward and fade out over 1.5 seconds
6. **Recycle**: Mark as available for reuse

### Scrap Gain
1. **Enemy Dies**: When enemy's `_on_died()` is triggered
2. **Check Scrap**: If `scrap_reward > 0` and `show_scrap_gain` is true
3. **Create Number**: Instantiate damage number scene
4. **Display**: Position above enemy, use gold color with "+" prefix
5. **Animate**: Float upward and fade out over 1.5 seconds

## Color Mapping

| Type | Color | Trigger |
|------|-------|---------|
| Normal damage | White | Default damage |
| Fire damage | Orange | `"fire"`, `"flame"` |
| Ice damage | Cyan | `"ice"`, `"frost"`, `"cold"` |
| Poison damage | Purple | `"poison"`, `"toxic"` |
| Critical damage | Red | `"critical"`, `"crit"` |
| Scrap gain | Gold | Enemy death with scrap reward |

## Performance

### Object Pooling (Damage Numbers)

Each health component maintains its own pool of damage numbers:
- Max pool size: 10 instances per entity
- Inactive instances are reused
- When pool is full, oldest is recycled

### Scrap Gain Numbers

Scrap gain numbers are instantiated on-demand since:
- Enemies die less frequently than taking damage
- Each enemy only shows one scrap number when dying
- The node is automatically cleaned up after animation

### Memory Budget

- ~2KB per damage number instance
- Max ~20KB per entity for damage numbers (10 instances)
- Numbers are added to current scene to avoid parent movement issues

## Testing

Unit tests are available in `tests/unit/test_damage_number_manager.gd`:

```bash
./godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_damage_number_manager.gd
```

Tests cover:
- Scene loading and instantiation
- Color coding for damage types
- Activation and deactivation
- Scrap gain "+" prefix
- Health component integration

## Usage Examples

### Damage Numbers
```gdscript
# Damage numbers are automatic when using the health component
health_component.take_damage(25, "fire")  # Shows orange "25"
health_component.take_damage(10, "player") # Shows white "10"
health_component.take_damage(50, "critical") # Shows red "50"

# Disable damage numbers for an entity
health_component.show_damage_numbers = false
```

### Scrap Gain
```gdscript
# Scrap gain is automatic when enemy dies with scrap_reward > 0
# To disable for a specific enemy:
enemy.show_scrap_gain = false

# Manual display (advanced usage)
var damage_number = damage_number_scene.instantiate()
damage_number.display_damage(10, world_pos, UI_DamageNumber.NumberType.SCRAP_GAIN)
```

## Troubleshooting

### Numbers not appearing

1. Check that `show_damage_numbers` is true on the health component
2. For scrap, check that `show_scrap_gain` is true and `scrap_reward > 0`
3. Verify the damage number scene exists at the expected path
4. Check that the entity has a valid parent with `global_position`

### Performance issues

1. Each entity has its own damage pool (max 10)
2. Scrap numbers are created on-demand (only one per death)
3. Numbers are added to current scene to avoid transform updates

## Architecture Notes

The system uses a simple, integrated approach:
- **Damage numbers**: Integrated into health component with per-entity pooling
- **Scrap gain**: Integrated into enemy death handler
- **Shared visuals**: Both use the same `UI_DamageNumber` scene
- **Easy configuration**: Toggle per entity via export variables
