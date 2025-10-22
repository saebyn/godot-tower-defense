extends Resource
class_name ObstacleTypeResource

enum ObstacleCategory {
    BASIC
}

@export_category("Basic Properties")
@export var id: String = "" ## Unique identifier for the obstacle type
@export var name: String = "New Obstacle Type" ## Name of the obstacle type
@export var description: String = "Description of the obstacle type." ## Description of the obstacle type
@export var icon: Texture2D ## Icon representing the obstacle type
@export var color: Color = Color(1, 1, 1) ## Color associated with the obstacle type
@export var category: ObstacleCategory = ObstacleCategory.BASIC ## Category of the obstacle type

@export_category("Gameplay Properties")
@export var is_offensive: bool = false ## Whether the obstacle type is offensive
@export var cost: int = 0 ## Cost associated with the obstacle type
@export var scene: PackedScene ## Scene representing the obstacle type. Should be a PlaceableObstacle.

@export_category("Tech Tree Integration")
@export var required_tech_ids: Array[String] = [] ## Technology IDs that must be unlocked to use this obstacle. If empty, obstacle is available from the start.

func is_valid() -> bool:
    return not id.is_empty() and scene != null