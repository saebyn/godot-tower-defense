extends Button

@export var spawnable: Resource_BuildingType
@onready var ui: Node = $"../.."

func _on_pressed() -> void:
  ui.request_building_spawn(spawnable)
