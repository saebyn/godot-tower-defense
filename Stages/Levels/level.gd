class_name Level
extends Node3D

@export var enemy_spawner: EnemySpawner
@export var ui: Control
@export var buildable_area: Area3D ## Optional: Defines the buildable area for obstacle placement


func _ready() -> void:
  # Register buildable area with GameManager for centralized coordination
  GameManager.set_level_buildable_area(buildable_area)
  
  enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
  enemy_spawner.wave_started.connect(_on_wave_started)
  enemy_spawner.wave_completed.connect(_on_wave_completed)


func _on_enemy_spawned(enemy: Node3D) -> void:
  ui._on_enemy_spawned(enemy)

func _on_wave_started(wave: Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  ui._on_wave_started(wave, wave_number)

func _on_wave_completed(wave: Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  ui._on_wave_completed(wave, wave_number)
