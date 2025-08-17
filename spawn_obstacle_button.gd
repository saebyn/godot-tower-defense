extends Button

@export var spawnable: PackedScene

signal obstacle_spawn_requested(obstacle_instance: Node3D)

func _on_pressed() -> void:
  obstacle_spawn_requested.emit(spawnable.instantiate())
