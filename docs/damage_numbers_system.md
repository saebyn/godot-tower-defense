# Damage Numbers System

## Overview

The damage numbers system provides visual feedback when entities take damage or when scrap is earned. Numbers float upward and fade out, with different colors indicating different types of feedback.

## Component Architecture

The system uses `Component_DamageNumbers`, a standalone component that can be added to any entity that needs visual damage/currency feedback. It creates Label3D nodes dynamically - no scene file required.

### Component_DamageNumbers (`Common/Components/damage_numbers/damage_numbers.gd`)

A Node-based component that displays floating damage numbers and scrap gain feedback.

**Features:**
- Creates Label3D nodes dynamically in `_ready()` (no scene file needed)
- Registers itself in parent's metadata for discovery
- Color-coded by damage type (fire=orange, ice=cyan, poison=purple, etc.)
- Object pooling for performance (configurable max pool size)
- Uses `fixed_size` on Label3D for visibility at any zoom level
- Separate toggles for damage numbers and scrap gain

**Configuration:**
- `max_pool_size: int = 10` - Maximum number of labels in the pool
- `float_speed: float = 1.0` - Speed of upward movement
- `fade_duration: float = 1.5` - Duration of fade animation
- `float_distance: float = 2.0` - Distance traveled upward
- `vertical_offset: float = 2.0` - Height offset above entity
- `show_damage_numbers: bool = true` - Toggle damage numbers
- `show_scrap_gain: bool = true` - Toggle scrap gain numbers
- `font_size: int = 32` - Base font size
- `fixed_size_pixels: float = 48.0` - Fixed size for visibility at any zoom

**Key Methods:**
- `show_damage(amount, damage_source)` - Display a damage number
- `show_scrap(amount)` - Display a scrap gain number

## Integration with Health Component

The `Component_Health` component checks for a damage numbers component via the parent's metadata:

```gdscript
# In health.gd take_damage():
var parent = get_parent()
if parent and parent.has_meta("damage_numbers_component"):
  var damage_numbers = parent.get_meta("damage_numbers_component")
  if damage_numbers and damage_numbers.has_method("show_damage"):
    damage_numbers.show_damage(amount, damage_source)
```

## Integration with Enemy

The enemy script checks for the damage numbers component on death:

```gdscript
# In enemy.gd _on_died():
if has_meta("damage_numbers_component"):
  var damage_numbers = get_meta("damage_numbers_component")
  if damage_numbers and damage_numbers.has_method("show_scrap"):
    damage_numbers.show_scrap(scrap_reward)
```

## How to Use

### Adding to an Entity

Add `Component_DamageNumbers` as a child of any entity that needs damage feedback:

1. **For enemies**: Add as a child node, it will auto-register in metadata
2. **For targets**: Add as a child node
3. **For obstacles**: Add as a child node  
4. **For scrap boxes**: Add as a child node

The component will automatically register itself in the parent's metadata as `damage_numbers_component`.

### Manual Usage

```gdscript
# Get the component from metadata
if has_meta("damage_numbers_component"):
  var damage_numbers = get_meta("damage_numbers_component")
  
  # Show damage
  damage_numbers.show_damage(25, "fire")  # Orange number
  damage_numbers.show_damage(10, "normal")  # White number
  
  # Show scrap gain
  damage_numbers.show_scrap(50)  # Gold "+50" number
```

## Color Mapping

| Type | Color | Trigger |
|------|-------|---------|
| Normal damage | White | Default damage |
| Fire damage | Orange | `"fire"`, `"flame"` |
| Ice damage | Cyan | `"ice"`, `"frost"`, `"cold"` |
| Poison damage | Purple | `"poison"`, `"toxic"` |
| Critical damage | Red | `"critical"`, `"crit"` |
| Scrap gain | Gold | Via `show_scrap()` method |

## Performance

### Object Pooling

Each component maintains its own pool of Label3D nodes:
- Default max pool size: 10 instances per entity
- Inactive instances are reused
- When pool is full, oldest active is recycled
- Labels cleaned up when component exits tree

### Fixed Size Labels

Labels use `fixed_size = true` with a configured pixel size, ensuring:
- Consistent visibility at any camera zoom level
- No scaling issues with entity transform
- Readable text regardless of distance

## Testing

Unit tests are available in `tests/unit/test_damage_number_manager.gd`:

```bash
./godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_damage_number_manager.gd
```

Tests cover:
- Component registration in metadata
- Label creation and pooling
- Color coding for damage types
- Scrap gain formatting
- Toggle settings
- Pool size limits
- Integration with health component

## Troubleshooting

### Numbers not appearing

1. Check that the entity has `Component_DamageNumbers` as a child
2. Check that `show_damage_numbers` or `show_scrap_gain` is enabled
3. Verify the entity is a Node3D (required for positioning)
4. Check that the component registered in metadata

### Performance issues

1. Reduce `max_pool_size` if too many entities
2. Check that labels are being recycled (not accumulating)
3. Verify `_exit_tree()` is cleaning up properly

## Architecture Benefits

- **No scene file needed**: Component creates nodes programmatically
- **Flexible**: Can be added to any entity type
- **Discoverable**: Uses metadata for component lookup
- **Zoom-independent**: Fixed size labels visible at any distance
- **Easy configuration**: All settings exposed as exports
