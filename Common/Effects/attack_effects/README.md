# Attack Effects System

## Overview

The attack effects system provides visual feedback when attacks are performed in the game. It includes multiple effect types that can be configured per attack component.

## Available Effect Types

### 1. Bullet Attack Effect
- **Description**: A fast-moving yellow projectile that travels from attacker to target
- **Visual**: Glowing yellow sphere with emission
- **Speed**: Configurable (default: 20.0 units/second)
- **Best for**: Ranged weapon attacks, gun turrets

### 2. Fireball Attack Effect  
- **Description**: Orange fireball with particle trail and explosion on impact
- **Visual**: Orange glowing sphere with trailing particles and explosive impact
- **Speed**: Configurable (default: 15.0 units/second)
- **Best for**: Magical attacks, fire-based weapons

### 3. Magic Sparkles Attack Effect
- **Description**: Cyan magical projectile with sparkle trail and arcing movement
- **Visual**: Shimmering cyan core with particle trail, follows an arc path
- **Speed**: Configurable (default: 25.0 units/second)
- **Best for**: Spell casting, magical abilities

### 4. Laser Beam Attack Effect
- **Description**: Instant red laser beam with impact particles
- **Visual**: Red glowing cylinder beam that appears instantly
- **Duration**: Configurable (default: 0.3 seconds)
- **Best for**: High-tech weapons, instant-hit attacks

## Usage

### Configuring Attack Effects

In any Attack component, you can configure the effect type using the exported parameters:

1. **show_attack_effects**: Boolean to enable/disable visual effects
2. **attack_effect_type**: Choose from the available effect types:
   - `NONE` - No visual effect
   - `BULLET` - Bullet projectile
   - `FIREBALL` - Fireball with explosion
   - `MAGIC_SPARKLES` - Magical sparkles
   - `LASER_BEAM` - Instant laser beam

### In the Godot Editor

1. Select any node with an Attack component
2. In the Inspector, find the Attack section
3. Check "Show Attack Effects" to enable effects
4. Set "Attack Effect Type" to your desired effect

### In Code

```gdscript
# Enable effects and set type
@onready var attack: Attack = $Attack
attack.show_attack_effects = true
attack.attack_effect_type = Attack.AttackEffectType.FIREBALL
```

## Technical Details

### Component Structure

```
Common/Effects/attack_effects/
├── base_attack_effect.gd          # Base class for all effects
├── base_attack_effect.tscn        # Base scene template
├── bullet_attack_effect.gd        # Bullet effect implementation
├── bullet_attack_effect.tscn      # Bullet effect scene
├── fireball_attack_effect.gd      # Fireball effect implementation
├── fireball_attack_effect.tscn    # Fireball effect scene
├── magic_sparkles_attack_effect.gd # Magic effect implementation
├── magic_sparkles_attack_effect.tscn # Magic effect scene
├── laser_beam_attack_effect.gd    # Laser effect implementation
└── laser_beam_attack_effect.tscn  # Laser effect scene
```

### How It Works

1. When `attack.perform_attack()` is called, it checks if effects are enabled
2. If enabled, it instantiates the selected effect scene
3. The effect is added to the scene root to avoid cleanup issues
4. The effect animates from the attacker position to the target position
5. Effects automatically clean themselves up when finished

### Creating Custom Effects

To create a new attack effect:

1. Extend `BaseAttackEffect` class
2. Override `_animate_effect(from_pos: Vector3, to_pos: Vector3)` method
3. Create your visual animation using tweens, particles, etc.
4. Call `_finish_effect()` when the animation is complete
5. Add your effect to the `attack_effect_scenes` dictionary in `attack.gd`

### Performance Considerations

- Effects are automatically cleaned up when finished
- Particle systems are properly configured to avoid memory leaks
- Only one effect instance is created per attack
- Effects use efficient Godot built-in systems (Tween, GPUParticles3D)

## Integration

The attack effects system is fully integrated with the existing attack system:

- **Enemies**: Automatically use effects when attacking targets
- **Player attacks**: Work with click-to-attack system
- **All attack components**: Can be configured independently

No existing code needs to be modified - effects are opt-in via the export parameters.