# Damage Numbers System

## Overview

The damage numbers system provides visual feedback when entities take damage. Numbers float upward and fade out, with different colors indicating different damage types.

## Component Integration

The damage number functionality is built directly into the `Component_Health` component for simplicity and maintainability.

### Component_Health (`Common/Components/health/health.gd`)

The health component now includes damage number display:

**Features:**
- Automatic damage number spawning when `take_damage()` is called
- Color-coded by damage source (fire=orange, ice=cyan, poison=purple, etc.)
- Object pooling for performance (max 10 instances per health component)
- Configurable via `show_damage_numbers` export variable

**Configuration:**
- `show_damage_numbers: bool = true` - Toggle damage numbers on/off per entity

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
- `deactivate()`: Stop animation and mark as available for reuse
- `is_available()`: Check if ready for reuse

**Configuration:**
- `float_speed`: Speed of upward movement (default: 1.0)
- `fade_duration`: Duration of fade animation (default: 1.5 seconds)
- `float_distance`: Distance traveled upward (default: 2.0)

## How It Works

1. **Entity Takes Damage**: When `Component_Health.take_damage()` is called
2. **Check Setting**: If `show_damage_numbers` is true, proceed
3. **Get/Create Number**: Get available number from pool or create new (up to 10)
4. **Display**: Position above entity, set color based on damage source
5. **Animate**: Float upward and fade out over 1.5 seconds
6. **Recycle**: Mark as available for reuse

## Damage Source Color Mapping

The health component maps damage source strings to colors:

| Damage Source | Color |
|---------------|-------|
| `"fire"`, `"flame"` | Orange |
| `"ice"`, `"frost"`, `"cold"` | Cyan |
| `"poison"`, `"toxic"` | Purple |
| `"critical"`, `"crit"` | Red |
| All others | White |

## Performance

### Object Pooling

Each health component maintains its own pool of damage numbers:
- Max pool size: 10 instances per entity
- Inactive instances are reused
- When pool is full, oldest is recycled

### Memory Budget

- ~2KB per damage number instance
- Max ~20KB per entity (10 instances)
- Numbers are added to scene root to avoid parent movement

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

## Usage Example

```gdscript
# Damage numbers are automatic when using the health component
health_component.take_damage(25, "fire")  # Shows orange "25"
health_component.take_damage(10, "player") # Shows white "10"
health_component.take_damage(50, "critical") # Shows red "50"

# Disable damage numbers for an entity
health_component.show_damage_numbers = false
```

## Troubleshooting

### Numbers not appearing

1. Check that `show_damage_numbers` is true on the health component
2. Verify the damage number scene exists at the expected path
3. Check that the entity has a valid parent with `global_position`

### Performance issues

1. Each entity has its own pool (max 10)
2. For many entities, consider reducing pool size
3. Damage numbers are added to root to avoid transform updates

## Architecture Notes

The damage number functionality is integrated directly into the health component rather than using a separate manager. This provides:
- **Simplicity**: No external wiring needed
- **Encapsulation**: Feature is self-contained in health component
- **Per-entity pooling**: Each entity manages its own damage numbers
- **Easy configuration**: Toggle per entity via export variable
