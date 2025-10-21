# Achievement System

This directory contains the Achievement Resource Type and achievement definitions for the Zom Nom Defense game.

## AchievementResource

The `AchievementResource` is a custom Godot Resource type that defines individual achievements in the game. It includes:

### Properties

#### Basic Properties
- **id**: Unique identifier for the achievement (String)
- **name**: Display name shown to the player (String)
- **description**: Detailed description of the achievement (String)
- **icon**: Visual icon for the achievement (Texture2D)

#### Unlock Conditions
- **unlock_condition_type**: Type of condition to track (ConditionType enum)
- **threshold**: Numerical threshold that must be reached to unlock (int)
- **condition_target**: Optional target for typed conditions, e.g., enemy type name (String)

#### Display
- **hidden**: Whether the achievement is hidden until unlocked (bool)

#### Rewards
- **reward**: Reward identifier that could unlock tech tree items, obstacles, etc. (String)

### Condition Types

The `ConditionType` enum supports the following tracking types:

1. **ENEMIES_DEFEATED_TOTAL**: Track total enemies defeated across all types
2. **ENEMIES_DEFEATED_BY_TYPE**: Track enemies defeated of a specific type (requires `condition_target`)
3. **CLICKS_PERFORMED**: Track total clicks performed (hand defeats)
4. **SCRAP_EARNED**: Track total scrap earned over all time
5. **OBSTACLES_PLACED**: Track total obstacles placed
6. **WAVE_COMPLETED**: Track waves completed in a single game
7. **GAME_LEVEL_REACHED**: Track highest game level reached
8. **PLAYER_LEVEL_REACHED**: Track player XP level reached

### Methods

- **is_valid()**: Validates that the achievement resource has all required fields
- **get_condition_description()**: Returns a human-readable description of the unlock condition

## Creating Achievement Resources

### Using the Godot Editor

1. Right-click in the FileSystem panel
2. Select "New Resource..."
3. Choose "AchievementResource"
4. Configure the properties in the Inspector
5. Save the resource as a `.tres` file

### Example: Simple Achievement

```gdscript
# Create a basic achievement for defeating the first enemy
var achievement = AchievementResource.new()
achievement.id = "first_blood"
achievement.name = "First Blood"
achievement.description = "Defeat your first enemy"
achievement.unlock_condition_type = AchievementResource.ConditionType.ENEMIES_DEFEATED_TOTAL
achievement.threshold = 1
achievement.hidden = false
```

### Example: Type-Specific Achievement

```gdscript
# Create an achievement for defeating a specific enemy type
var achievement = AchievementResource.new()
achievement.id = "zombie_slayer"
achievement.name = "Zombie Slayer"
achievement.description = "Defeat 100 BasicZombie enemies"
achievement.unlock_condition_type = AchievementResource.ConditionType.ENEMIES_DEFEATED_BY_TYPE
achievement.threshold = 100
achievement.condition_target = "BasicZombie"
achievement.reward = "unlock_advanced_turret"
achievement.hidden = false
```

### Example: Hidden Achievement with Reward

```gdscript
# Create a hidden achievement that unlocks content
var achievement = AchievementResource.new()
achievement.id = "secret_master"
achievement.name = "Secret Master"
achievement.description = "Discover the secret technique"
achievement.unlock_condition_type = AchievementResource.ConditionType.PLAYER_LEVEL_REACHED
achievement.threshold = 50
achievement.hidden = true
achievement.reward = "unlock_secret_tech_tree_branch"
```

## Integrating with StatsManager

The achievement system is designed to work with the existing `StatsManager` singleton, which tracks:

- `enemies_defeated_total` and `enemies_defeated_by_type`
- `enemies_defeated_by_hand` (for CLICKS_PERFORMED)
- `obstacles_placed_total` and `obstacles_placed_by_type`
- `total_scrap_earned`
- `total_xp_earned`

The Achievement Manager (to be implemented in a future issue) will listen to `StatsManager` signals to check achievement unlock conditions.

## Sample Achievements

This directory includes two sample achievements:

1. **first_blood.tres**: Defeat your first enemy
2. **zombie_slayer.tres**: Defeat 100 BasicZombie enemies (with reward)

## Next Steps

To complete the achievement system, the following components need to be implemented:

1. **Achievement Manager**: Singleton to track unlocked achievements and check conditions
2. **Achievement UI**: Display unlocked/locked achievements to the player
3. **Achievement Persistence**: Save/load achievement unlock state
4. **Reward System**: Process achievement rewards (unlock tech tree items, obstacles, etc.)

## Technical Notes

- The `AchievementResource` uses Godot's `@export` annotations for easy editing in the inspector
- Validation ensures achievements have all required fields before use
- The resource follows the same patterns as `EnemyTypeResource` and `ObstacleTypeResource`
- The script is registered as a global class with `class_name AchievementResource`
