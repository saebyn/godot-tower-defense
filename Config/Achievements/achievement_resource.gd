class_name AchievementResource
extends Resource

## Resource class defining individual achievements
## Used to configure achievement tracking, unlock conditions, and rewards
## 
## Usage:
##   var achievement = AchievementResource.new()
##   achievement.id = "first_kill"
##   achievement.name = "First Blood"
##   achievement.unlock_condition_type = ConditionType.ENEMIES_DEFEATED_TOTAL
##   achievement.threshold = 1

enum ConditionType {
  ENEMIES_DEFEATED_TOTAL,      ## Track total enemies defeated across all types
  ENEMIES_DEFEATED_BY_TYPE,    ## Track enemies defeated of a specific type
  CLICKS_PERFORMED,            ## Track total clicks performed (hand defeats)
  SCRAP_EARNED,                ## Track total scrap earned over all time
  OBSTACLES_PLACED,            ## Track total obstacles placed
  WAVE_COMPLETED,              ## Track waves completed in a single game
  GAME_LEVEL_REACHED,          ## Track highest game level reached
  PLAYER_LEVEL_REACHED         ## Track player XP level reached
}

@export_category("Basic Properties")
@export var id: String = "" ## Unique identifier for the achievement
@export var name: String = "New Achievement" ## Display name of the achievement
@export var description: String = "Achievement description." ## Description shown to the player
@export var icon: Texture2D ## Icon representing the achievement

@export_category("Unlock Conditions")
@export var unlock_condition_type: ConditionType = ConditionType.ENEMIES_DEFEATED_TOTAL ## Type of condition to track
@export var threshold: int = 1 ## Numerical threshold that must be reached to unlock
@export var condition_target: String = "" ## Optional target for typed conditions (e.g., enemy type name)

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
  if threshold < 1:
    return false
  
  # For type-specific conditions, require a target
  if unlock_condition_type == ConditionType.ENEMIES_DEFEATED_BY_TYPE:
    if condition_target.is_empty():
      return false
  
  return true


## Get a human-readable description of the unlock condition
func get_condition_description() -> String:
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
