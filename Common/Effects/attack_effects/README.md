# Attack Effects System

## Overview

The attack effects system provides visual feedback when attacks are performed in the game. It uses a simple child component architecture where attack effects are added as child nodes to Attack components.

## Architecture

### Child Component Design

The system uses a child component approach:

- **BaseAttackEffect**: Base class that all attack effects extend
- **Attack Component**: Automatically detects and uses child attack effect components
- **Effect Scenes**: Pre-built effect scenes that can be added as children

### Key Benefits

1. **Simple setup**: Add effect as child node to Attack component
2. **Per-entity customization**: Each Attack can have different effect parameters
3. **No hardcoded references**: Effects are discovered at runtime
4. **Fully extensible**: Create new effects by extending BaseAttackEffect
5. **Designer-friendly**: Visual scene composition in Godot editor

## Available Effect Types

### 1. Bullet Attack Effect
- **Description**: A fast-moving yellow projectile that travels from attacker to target
- **Visual**: Glowing yellow sphere with emission
- **Parameters**: `bullet_speed` (default: 20.0), `bullet_color` (default: yellow)
- **Best for**: Ranged weapon attacks, gun turrets

### 2. Fireball Attack Effect  
- **Description**: Orange fireball with particle trail and explosion on impact
- **Visual**: Orange glowing sphere with trailing particles and explosive impact
- **Parameters**: `projectile_speed` (default: 15.0), `fireball_color` (default: orange)
- **Best for**: Magical attacks, fire-based weapons

### 3. Magic Sparkles Attack Effect
- **Description**: Cyan magical projectile with sparkle trail and arcing movement
- **Visual**: Shimmering cyan core with particle trail, follows an arc path
- **Parameters**: `projectile_speed` (default: 25.0), `sparkle_color` (default: cyan)
- **Best for**: Spell casting, magical abilities

### 4. Laser Beam Attack Effect
- **Description**: Instant red laser beam with impact particles
- **Visual**: Red glowing cylinder beam that appears instantly
- **Parameters**: `beam_duration` (default: 0.3), `laser_color` (default: red)
- **Best for**: High-tech weapons, instant-hit attacks

### Creating Custom Effects

To create a new attack effect:

1. **Create a new scene**:
   - Create a new 3D scene
   - Change the root node type to extend `BaseAttackEffect`
   - Add visual elements (MeshInstance3D, particles, etc.)
   - Save as `.tscn` file

2. **Create the script**:
   ```gdscript
   extends BaseAttackEffect
   
   @export var my_speed: float = 20.0
   @export var my_color: Color = Color.MAGENTA
   
   func _animate_effect(from_pos: Vector3, to_pos: Vector3) -> void:
       # Implement your custom animation here
       # Example: move from from_pos to to_pos over time
       effect_tween = create_tween()
       effect_tween.tween_property(self, "global_position", to_pos, 1.0)
       effect_tween.finished.connect(_finish_effect)
   ```

3. **Use the effect**:
   - Add your custom effect scene as a child to any Attack component
   - It will be automatically detected and used

## Technical Details

### Component Structure

```
Common/Effects/attack_effects/
├── base_attack_effect.gd           # Base class for all effects
├── base_attack_effect.tscn         # Base scene template
├── bullet_attack_effect.gd         # Bullet effect implementation
├── bullet_attack_effect.tscn       # Bullet effect scene
├── fireball_attack_effect.gd       # Fireball effect implementation
├── fireball_attack_effect.tscn     # Fireball effect scene
├── magic_sparkles_attack_effect.gd # Magic effect implementation
├── magic_sparkles_attack_effect.tscn # Magic effect scene
├── laser_beam_attack_effect.gd     # Laser effect implementation
└── laser_beam_attack_effect.tscn   # Laser effect scene
```

### How It Works

1. Attack components scan their children for nodes extending `BaseAttackEffect`
2. When `attack.perform_attack()` is called, it triggers the child effect
3. Effects are persistent child components (no instantiation overhead)
4. Effects reset their state for each attack

### Performance Considerations

- Effects are persistent child components (no instantiation per attack)
- Effects use `auto_cleanup = false` to remain available for reuse
- Tween cleanup is handled automatically
- Only one effect per Attack component is supported (first found child is used)
