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
- **use_multiple_conditions**: Whether to use multiple conditions for complex achievements (bool, default: false)

**For single condition achievements (use_multiple_conditions = false):**
- **unlock_condition_type**: Type of condition to track (ConditionType enum)
- **threshold**: Numerical threshold that must be reached to unlock (int)
- **condition_target**: Optional target for typed conditions, e.g., enemy type name (String)

**For multiple condition achievements (use_multiple_conditions = true):**
- **condition_logic**: How to combine conditions - AND (all must be met) or OR (any must be met) (ConditionLogic enum)
- **conditions**: Array of AchievementCondition objects defining each requirement (Array[AchievementCondition])

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
  - For single conditions: checks id, name, threshold, and type-specific requirements
  - For multiple conditions: validates each condition in the array
- **get_condition_description()**: Returns a human-readable description of the unlock condition(s)
  - For single conditions: returns simple description like "Defeat 10 enemies"
  - For multiple conditions: joins conditions with AND/OR, e.g., "Defeat 50 enemies AND Place 10 obstacles"

### Nested Class: AchievementCondition

When using multiple conditions, each condition is represented by an `AchievementCondition` object with:
- **condition_type**: The type of stat to track (ConditionType enum)
- **threshold**: The numerical value that must be reached (int)
- **condition_target**: Optional target for type-specific conditions (String)

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

### Example: Multiple Conditions with AND Logic

```gdscript
# Create an achievement requiring multiple conditions (all must be met)
var achievement = AchievementResource.new()
achievement.id = "multi_tasker"
achievement.name = "Multi-Tasker"
achievement.description = "Defeat enemies while building defenses"
achievement.use_multiple_conditions = true
achievement.condition_logic = AchievementResource.ConditionLogic.AND

# Add first condition: defeat 50 enemies
var cond1 = AchievementResource.AchievementCondition.new()
cond1.condition_type = AchievementResource.ConditionType.ENEMIES_DEFEATED_TOTAL
cond1.threshold = 50

# Add second condition: place 10 obstacles
var cond2 = AchievementResource.AchievementCondition.new()
cond2.condition_type = AchievementResource.ConditionType.OBSTACLES_PLACED
cond2.threshold = 10

achievement.conditions = [cond1, cond2]
# Result: "Defeat 50 enemies AND Place 10 obstacles"
```

### Example: Multiple Conditions with OR Logic

```gdscript
# Create an achievement where any condition can be met
var achievement = AchievementResource.new()
achievement.id = "flexible_path"
achievement.name = "Flexible Path"
achievement.description = "Reach success through different means"
achievement.use_multiple_conditions = true
achievement.condition_logic = AchievementResource.ConditionLogic.OR

# First path: earn lots of scrap
var cond1 = AchievementResource.AchievementCondition.new()
cond1.condition_type = AchievementResource.ConditionType.SCRAP_EARNED
cond1.threshold = 1000

# Second path: reach high player level
var cond2 = AchievementResource.AchievementCondition.new()
cond2.condition_type = AchievementResource.ConditionType.PLAYER_LEVEL_REACHED
cond2.threshold = 15

achievement.conditions = [cond1, cond2]
# Result: "Earn 1000 scrap OR Reach player level 15"
```

### Example: Complex Multi-Condition Achievement

```gdscript
# Create a complex achievement with multiple typed conditions
var achievement = AchievementResource.new()
achievement.id = "zombie_master"
achievement.name = "Zombie Master"
achievement.description = "Master all aspects of zombie defense"
achievement.use_multiple_conditions = true
achievement.condition_logic = AchievementResource.ConditionLogic.AND

# Condition 1: Defeat specific enemy type
var cond1 = AchievementResource.AchievementCondition.new()
cond1.condition_type = AchievementResource.ConditionType.ENEMIES_DEFEATED_BY_TYPE
cond1.threshold = 100
cond1.condition_target = "BasicZombie"

# Condition 2: Place obstacles
var cond2 = AchievementResource.AchievementCondition.new()
cond2.condition_type = AchievementResource.ConditionType.OBSTACLES_PLACED
cond2.threshold = 25

# Condition 3: Earn scrap
var cond3 = AchievementResource.AchievementCondition.new()
cond3.condition_type = AchievementResource.ConditionType.SCRAP_EARNED
cond3.threshold = 500

achievement.conditions = [cond1, cond2, cond3]
achievement.reward = "unlock_advanced_tech"
# Result: "Defeat 100 BasicZombie enemies AND Place 25 obstacles AND Earn 500 scrap"
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
