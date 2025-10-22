extends Resource
class_name TechNodeResource

## Resource representing a single node in the tech tree
## Defines unlock requirements, effects, and mutually exclusive relationships

@export_category("Basic Properties")
@export var id: String = "" ## Unique identifier for this tech node
@export var display_name: String = "New Tech Node" ## Display name shown in UI
@export var description: String = "Description of this tech node." ## Description shown in UI
@export var icon: Texture2D ## Icon representing this tech node
@export var branch_name: String = "" ## Branch category (Offensive, Defensive, Economy, Support, Click, Advanced)

@export_category("Unlock Requirements")
@export var level_requirement: int = 1 ## Player level required to unlock this tech
@export var scrap_cost: int = 0 ## Scrap cost to unlock (currently unused - tech unlocking is free)
@export var prerequisite_tech_ids: Array[String] = [] ## Tech IDs that must be unlocked first
@export var achievement_ids: Array[String] = [] ## Achievement IDs required to unlock

@export_category("Mutual Exclusivity")
@export var mutually_exclusive_with: Array[String] = [] ## Tech IDs that become permanently locked when this is unlocked

@export_category("Branch Completion")
@export var requires_branch_completion: Array[String] = [] ## Branch names that must be fully completed before this unlocks

@export_category("Effects")
@export var unlocked_obstacle_ids: Array[String] = [] ## Obstacle IDs that become available when this tech is unlocked

## Validates that the tech node has required fields
func is_valid() -> bool:
  return not id.is_empty() and not display_name.is_empty()
