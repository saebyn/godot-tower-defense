extends Control


signal obstacle_spawn_requested(obstacle_instance: Node3D)

@onready var spawn_indicator: Control = $SpawnIndicator

func request_obstacle_spawn(obstacle_instance: Node3D) -> void:
  obstacle_spawn_requested.emit(obstacle_instance)

func _on_enemy_spawned(enemy: Node3D) -> void:
  """Called when an enemy spawns to show the spawn indicator"""
  if spawn_indicator and spawn_indicator.has_method("show_spawn_notification"):
    spawn_indicator.show_spawn_notification(enemy)