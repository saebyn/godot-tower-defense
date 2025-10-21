class_name AchievementResource
extends Resource

## Resource class defining individual achievements
## Used to configure achievement tracking, unlock conditions, and rewards
## 
## Usage:
##   # Simple single condition achievement
##   var achievement = AchievementResource.new()
##   achievement.id = "first_kill"
##   achievement.name = "First Blood"
##   achievement.unlock_condition_type = ConditionType.ENEMIES_DEFEATED_TOTAL
##   achievement.threshold = 1
##
##   # Multiple conditions achievement
##   var complex_achievement = AchievementResource.new()
##   complex_achievement.id = "multi_task"
##   complex_achievement.name = "Multi-Tasker"
##   complex_achievement.use_multiple_conditions = true
##   complex_achievement.condition_logic = ConditionLogic.AND
##   var cond1 = AchievementCondition.new()
##   cond1.condition_type = ConditionType.ENEMIES_DEFEATED_TOTAL
##   cond1.threshold = 50
##   var cond2 = AchievementCondition.new()
##   cond2.condition_type = ConditionType.OBSTACLES_PLACED
##   cond2.threshold = 10
##   complex_achievement.conditions = [cond1, cond2]

enum ConditionType {
  ENEMIES_DEFEATED_TOTAL, ## Track total enemies defeated across all types
  ENEMIES_DEFEATED_BY_TYPE, ## Track enemies defeated of a specific type
  CLICKS_PERFORMED, ## Track total clicks performed (hand defeats)
  SCRAP_EARNED, ## Track total scrap earned over all time
  OBSTACLES_PLACED, ## Track total obstacles placed
  WAVE_COMPLETED, ## Track waves completed in a single game
  GAME_LEVEL_REACHED, ## Track highest game level reached
  PLAYER_LEVEL_REACHED ## Track player XP level reached
}

enum ConditionLogic {
  AND, ## All conditions must be met
  OR ## Any condition must be met
}


## Nested resource class representing an individual achievement condition.
## Used as an element within the `conditions` array of AchievementResource when `use_multiple_conditions` is true.
class AchievementCondition extends Resource:
  @export var condition_type: ConditionType = ConditionType.ENEMIES_DEFEATED_TOTAL ## Type of condition to track
  @export var threshold: int = 1 ## Numerical threshold that must be reached
  @export var condition_target: String = "" ## Optional target for typed conditions (e.g., enemy type name)
  
  func is_valid() -> bool:
    if threshold < 1:
      return false
    # For type-specific conditions, require a target
    if condition_type == ConditionType.ENEMIES_DEFEATED_BY_TYPE:
      if condition_target.is_empty():
        return false
    return true
  
  func get_description() -> String:
    var desc = ""
    match condition_type:
      ConditionType.ENEMIES_DEFEATED_TOTAL:
        desc = "Defeat %d enemies" % threshold
      ConditionType.ENEMIES_DEFEATED_BY_TYPE:
        desc = "Defeat %d %s enemies" % [threshold, condition_target]
      ConditionType.CLICKS_PERFORMED:
        desc = "Perform %d clicks" % threshold
      ConditionType.SCRAP_EARNED:
        desc = "Earn %d scrap" % threshold
      ConditionType.OBSTACLES_PLACED:
        desc = "Place %d obstacles" % threshold
      ConditionType.WAVE_COMPLETED:
        desc = "Complete wave %d" % threshold
      ConditionType.GAME_LEVEL_REACHED:
        desc = "Reach game level %d" % threshold
      ConditionType.PLAYER_LEVEL_REACHED:
        desc = "Reach player level %d" % threshold
    return desc

@export_category("Basic Properties")
@export var id: String = "" ## Unique identifier for the achievement
@export var name: String = "New Achievement" ## Display name of the achievement
@export var description: String = "Achievement description." ## Description shown to the player
@export var icon: Texture2D ## Icon representing the achievement

@export_category("Unlock Conditions")
@export var use_multiple_conditions: bool = false ## Whether to use multiple conditions (complex achievements)

## Single condition fields (used when use_multiple_conditions is false)
@export var unlock_condition_type: ConditionType = ConditionType.ENEMIES_DEFEATED_TOTAL ## Type of condition to track
@export var threshold: int = 1 ## Numerical threshold that must be reached to unlock
@export var condition_target: String = "" ## Optional target for typed conditions (e.g., enemy type name)

## Multiple conditions fields (used when use_multiple_conditions is true)
@export var condition_logic: ConditionLogic = ConditionLogic.AND ## Logic to combine multiple conditions (AND/OR)
@export var conditions: Array[AchievementCondition] = [] ## Array of conditions for complex achievements

@export_category("Display")
@export var hidden: bool = false ## Whether the achievement is hidden until unlocked

@export_category("Rewards")
@export var reward: String = "" ## Reward identifier (could unlock tech tree items, obstacles, etc.)


## Validate the achievement resource has required fields
func is_valid() -> bool:
  if id.is_empty():
    return false
  if name.is_empty():
    return false
  
  # Validate based on whether using single or multiple conditions
  if use_multiple_conditions:
    # Multiple conditions mode
    if conditions.is_empty():
      return false
    # Validate each condition
    for condition in conditions:
      if not condition.is_valid():
        return false
  else:
    # Single condition mode
    if threshold < 1:
      return false
    # For type-specific conditions, require a target
    if unlock_condition_type == ConditionType.ENEMIES_DEFEATED_BY_TYPE:
      if condition_target.is_empty():
        return false
  
  return true


## Get a human-readable description of the unlock condition(s)
func get_condition_description() -> String:
  if use_multiple_conditions:
    # Multiple conditions mode
    if conditions.is_empty():
      return "No conditions defined"
    
    var descriptions: Array[String] = []
    for condition in conditions:
      descriptions.append(condition.get_description())
    
    # Join conditions with AND/OR logic
    var logic_word := ""
    match condition_logic:
      ConditionLogic.AND:
        logic_word = " AND "
      ConditionLogic.OR:
        logic_word = " OR "
      _:
        logic_word = " AND " # Default/fallback
    return logic_word.join(descriptions)
  else:
    # Single condition mode (backward compatible)
    var condition_desc = ""
    
    match unlock_condition_type:
      ConditionType.ENEMIES_DEFEATED_TOTAL:
        condition_desc = "Defeat %d enemies" % threshold
      ConditionType.ENEMIES_DEFEATED_BY_TYPE:
        condition_desc = "Defeat %d %s enemies" % [threshold, condition_target]
      ConditionType.CLICKS_PERFORMED:
        condition_desc = "Perform %d clicks" % threshold
      ConditionType.SCRAP_EARNED:
        condition_desc = "Earn %d scrap" % threshold
      ConditionType.OBSTACLES_PLACED:
        condition_desc = "Place %d obstacles" % threshold
      ConditionType.WAVE_COMPLETED:
        condition_desc = "Complete wave %d" % threshold
      ConditionType.GAME_LEVEL_REACHED:
        condition_desc = "Reach game level %d" % threshold
      ConditionType.PLAYER_LEVEL_REACHED:
        condition_desc = "Reach player level %d" % threshold
    
    return condition_desc
