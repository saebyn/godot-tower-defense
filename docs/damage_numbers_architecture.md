# Damage Numbers System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Stage_Scenario                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              UI_DamageNumberManager                         │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              Damage Number Pool                       │  │ │
│  │  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐       │  │ │
│  │  │  │DN #1 │ │DN #2 │ │DN #3 │ │DN #4 │ │DN #5 │  ...  │  │ │
│  │  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘       │  │ │
│  │  │  (max 30 instances, reused for performance)          │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ connects to
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Enemy Spawner                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Enemy #1 │  │ Enemy #2 │  │ Enemy #3 │  │ Enemy #4 │  ...   │
│  │ ┌──────┐ │  │ ┌──────┐ │  │ ┌──────┐ │  │ ┌──────┐ │       │
│  │ │Health│ │  │ │Health│ │  │ │Health│ │  │ │Health│ │       │
│  │ └──────┘ │  │ └──────┘ │  │ └──────┘ │  │ └──────┘ │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

## Component Relationships

### 1. Scenario Initialization

```
Stage_Scenario._ready()
    │
    ├─> Check if damage_number_manager exists
    │   ├─> If not: _create_damage_number_manager()
    │   └─> Load and instantiate manager scene
    │
    └─> Connect to enemy_spawner.enemy_spawned signal
```

### 2. Enemy Spawning Flow

```
Enemy Spawned
    │
    ├─> Scenario receives enemy_spawned signal
    │
    └─> damage_number_manager.connect_to_enemy(enemy)
        │
        ├─> Find Component_Health (metadata or child)
        │
        ├─> Connect to health.damaged signal
        │   └─> On damage: show_damage(amount, position, type)
        │
        └─> Connect to health.died signal
            └─> On death: show_scrap_gain(scrap_reward, position)
```

### 3. Damage Display Flow

```
Enemy Takes Damage
    │
    ├─> Component_Health.damaged signal emitted
    │
    └─> Manager receives signal
        │
        ├─> Check settings (damage_numbers_enabled)
        │
        ├─> Get damage number from pool
        │   ├─> Try to find inactive instance
        │   ├─> If none, create new (up to max_pool_size)
        │   └─> If pool full, recycle oldest active
        │
        └─> damage_number.display_damage(amount, position, type)
            │
            ├─> Set text and color based on type
            ├─> Start animation (float up + fade out)
            └─> Auto-deactivate after fade_duration
                └─> Return to pool
```

### 4. Object Pooling Strategy

```
┌─────────────────────────────────────────┐
│         Damage Number Pool              │
│                                         │
│  Initial Size: 10 instances             │
│  Max Size: 30 instances                 │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │     Available (Inactive)        │   │
│  │  [DN1] [DN2] [DN3] [DN4] [DN5] │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │     In Use (Active)             │   │
│  │  [DN6] [DN7] [DN8]             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  When needed:                           │
│  1. Try to reuse inactive instance      │
│  2. Create new if pool < max_size       │
│  3. Recycle oldest if pool = max_size   │
└─────────────────────────────────────────┘
```

## Signal Flow Diagram

```
Component_Health
    │
    ├─ damaged(amount, hitpoints, damage_source)
    │      │
    │      └─> UI_DamageNumberManager
    │              │
    │              └─> show_damage() ──> UI_DamageNumber
    │                                        │
    │                                        ├─> Float animation
    │                                        ├─> Fade animation
    │                                        └─> deactivate()
    │
    └─ died(damage_source)
           │
           └─> UI_DamageNumberManager
                   │
                   ├─> show_scrap_gain() ──> UI_DamageNumber
                   │                              │
                   │                              └─> Gold colored
                   │
                   └─> AudioManager.play_sfx("scrap_collect")
```

## Integration Points

### Autoload Systems

```
┌─────────────────────────────────────────────────────────────┐
│                    Autoload Systems                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  CurrencyManager                                             │
│    └─> scrap_earned signal (optional future integration)    │
│                                                              │
│  AudioManager                                                │
│    └─> play_sfx("scrap_collect") when scrap gained         │
│                                                              │
│  SettingsManager                                             │
│    ├─> damage_numbers_enabled                               │
│    ├─> scrap_numbers_enabled                                │
│    └─> number_size_multiplier                               │
│                                                              │
│  Logger                                                      │
│    └─> Debug/trace messages for damage system               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Scene Hierarchy

```
Main
└─ Scenario (Stage_Scenario)
   ├─ EnemySpawner (System_EnemySpawner)
   │  └─ Enemies (spawned at runtime)
   │     └─ Component_Health
   │
   └─ DamageNumberManager (UI_DamageNumberManager)
      └─ DamageNumbers (pooled, Node3D)
         └─ Label3D (billboarded)
```

## Performance Characteristics

### Time Complexity

- Get damage number from pool: O(n) worst case, O(1) average
- Show damage: O(1)
- Animation update: O(n) where n = active numbers
- Pool expansion: O(1) amortized

### Space Complexity

- Memory usage: O(30) max (30 instances × ~2KB each ≈ 60KB)
- Pool overhead: Minimal (just array storage)

### Performance Budget

- Max simultaneous numbers: 30
- Animation duration: 1.5 seconds
- Max spawn rate: ~20 numbers/second (before recycling)

## Color Coding System

```
Damage Type         Color        Use Case
──────────────────────────────────────────────
DAMAGE_NORMAL       White        Player clicks, turret attacks
DAMAGE_CRITICAL     Red          Critical hits (future)
DAMAGE_FIRE         Orange       Fire DoT, flame turrets
DAMAGE_ICE          Cyan         Ice slowdown effects
DAMAGE_POISON       Purple       Poison DoT effects
SCRAP_GAIN          Gold         Enemy death rewards
```

## Animation Parameters

```
Parameter          Default    Unit        Description
─────────────────────────────────────────────────────────
float_speed        1.0        m/s         Upward movement speed
fade_duration      1.5        seconds     Total animation time
float_distance     2.0        meters      Total distance traveled
font_size          32         pixels      Base font size
font_size_crit     40         pixels      Critical hit size
```

## Settings Integration

```
SettingsManager.settings
    │
    ├─ "damage_numbers_enabled": bool
    │      Default: true
    │      Effect: Toggle all damage numbers
    │
    ├─ "scrap_numbers_enabled": bool
    │      Default: true
    │      Effect: Toggle scrap gain numbers
    │
    └─ "number_size_multiplier": float
           Default: 1.0
           Range: 0.5 - 2.0
           Effect: Scale all damage numbers
```

## Error Handling

```
Manager.connect_to_enemy(enemy)
    │
    ├─ Health component not found
    │  └─> Log warning, skip connection
    │
    ├─ Scrap reward property missing
    │  └─> Check with get(), handle null
    │
    └─ Signal already connected
       └─> Skip (Godot handles automatically)
```

## Future Architecture Considerations

### Potential Enhancements

1. **Spatial Partitioning**: Cull numbers outside camera frustum
2. **Damage Batching**: Accumulate rapid hits into single number
3. **Shader-based Fade**: Move fade logic to shader for GPU acceleration
4. **LOD System**: Reduce detail at distance
5. **Particle Integration**: Add VFX for critical hits

### Scalability

Current design supports:
- ✅ 20+ enemies with frequent damage
- ✅ Rapid clicking (player attack spam)
- ✅ Multiple turrets firing simultaneously
- ⚠️ 100+ simultaneous enemies (may need culling)

### Memory Considerations

- Pool prevents memory fragmentation
- Fixed maximum memory usage (~60KB)
- No dynamic allocations during gameplay
- Instances never freed until scene unload
