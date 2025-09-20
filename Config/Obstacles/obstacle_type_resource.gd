extends Resource
class_name ObstacleTypeResource

@export var id: String = "" # Unique identifier for this obstacle type
@export var display_name: String = "" # Human-readable name for UI
@export var description: String = "" # Description of the obstacle
@export var scene: PackedScene # The scene to instantiate
@export var icon: Texture2D # Optional icon for UI
@export var cost: int = 0 # Cost to place this obstacle
@export var category: String = "basic" # Category for grouping (basic, defensive, offensive, etc.)
@export var unlock_level: int = 1 # Level required to unlock this obstacle type

func is_valid() -> bool:
  return not id.is_empty() and scene != null