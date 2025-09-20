extends Button

@export var spawnable: ObstacleTypeResource
@onready var ui: Node = $"../.."

func _on_pressed() -> void:
  ui.request_obstacle_spawn(spawnable)
