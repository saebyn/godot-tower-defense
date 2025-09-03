# Attack Effects System

## Overview

The attack effects system provides visual feedback when attacks are performed in the game. It uses a flexible, resource-based architecture that allows for easy configuration and extension without modifying core components.

## Architecture

### Resource-Based Design

The system uses custom resources to define attack effects:

- **AttackEffectResource**: Defines an individual effect with its scene, parameters, and metadata
- **AttackEffectDatabase**: Contains all available attack effects in the project

### Key Benefits

1. **No hardcoded enums**: Attack types are defined in resources, not code
2. **No hardcoded paths**: Effect scenes are referenced in the database resource
3. **Configurable per entity**: Each Attack component can override effect parameters
4. **Fully extensible**: Add new effects without modifying existing components

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

## Usage

### Basic Configuration

In any Attack component, configure the effect using the exported parameters:

1. **show_attack_effects**: Boolean to enable/disable visual effects
2. **selected_effect_name**: Choose from available effects: "None", "Bullet", "Fireball", "Magic Sparkles", "Laser Beam"
3. **effect_parameter_overrides**: Dictionary to override default effect parameters
4. **attack_effects_database**: Optional custom database (uses default if not set)

### In the Godot Editor

1. Select any node with an Attack component
2. In the Inspector, find the Attack section
3. Check "Show Attack Effects" to enable effects
4. Set "Selected Effect Name" to your desired effect
5. Use "Effect Parameter Overrides" dictionary to customize parameters

### In Code

```gdscript
# Basic usage
@onready var attack: Attack = $Attack
attack.show_attack_effects = true
attack.selected_effect_name = "Fireball"

# With parameter overrides
attack.effect_parameter_overrides = {
    "projectile_speed": 10.0,  # Slower fireball
    "fireball_color": Color.BLUE  # Blue fireball instead of orange
}
```

### Creating Custom Effects

To create a new attack effect:

1. Create a new scene extending `BaseAttackEffect`
2. Override `_animate_effect(from_pos: Vector3, to_pos: Vector3)` method
3. Add configurable parameters as `@export` variables
4. Create an `AttackEffectResource` for your effect
5. Add it to your project's attack effects database

### Custom Effect Database

You can create custom effect databases for different game modes or enemy types:

```gdscript
# Create custom database
var custom_database = AttackEffectDatabase.new()

# Add custom effect
var my_effect = AttackEffectResource.new()
my_effect.effect_name = "Lightning Bolt"
my_effect.effect_scene = preload("res://effects/lightning_effect.tscn")
my_effect.effect_parameters = {"bolt_color": Color.PURPLE}
custom_database.add_effect(my_effect)

# Use in attack component
attack.attack_effects_database = custom_database
```

## Technical Details

### Component Structure

```
Common/Effects/attack_effects/
├── attack_effect_resource.gd       # Effect resource definition
├── attack_effect_database.gd       # Effect database resource
├── default_attack_effects.gd       # Default effects setup
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

1. Attack components reference an `AttackEffectDatabase` (default provided)
2. When `attack.perform_attack()` is called, it looks up the selected effect by name
3. Effect parameters are combined (defaults + overrides)
4. The effect scene is instantiated and played with the final parameters
5. Effects automatically clean themselves up when finished

### Performance Considerations

- Effects are automatically cleaned up when finished
- Particle systems are properly configured to avoid memory leaks
- Only one effect instance is created per attack
- Effects use efficient Godot built-in systems (Tween, GPUParticles3D)
- Database resources can be shared across multiple attack components

## Migration from Enum System

The new resource system is designed to be compatible with existing setups:

- Default effects are automatically available (Bullet, Fireball, Magic Sparkles, Laser Beam)
- Attack components work without configuration (defaults to Bullet effect)
- No breaking changes to existing attack functionality

## Integration

The attack effects system is fully integrated with the existing attack system:

- **Enemies**: Automatically use effects when attacking targets
- **Player attacks**: Work with click-to-attack system
- **All attack components**: Can be configured independently

No existing code needs to be modified - effects are opt-in via the export parameters.