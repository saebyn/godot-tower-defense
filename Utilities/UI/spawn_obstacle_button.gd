extends Button

@export var spawnable: Resource_ObstacleType
@onready var ui: Node = $"../.."

func _on_pressed() -> void:
  ui.request_obstacle_spawn(spawnable)
