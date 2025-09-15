extends Control

signal obstacle_spawn_requested(obstacle_instance: Node3D)


func request_obstacle_spawn(obstacle_instance: Node3D) -> void:
  obstacle_spawn_requested.emit(obstacle_instance)
