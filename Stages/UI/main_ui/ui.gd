extends Control

signal obstacle_spawn_requested(obstacle: ObstacleTypeResource)

@onready var spawn_indicator: Control = $SpawnIndicator
@onready var hotbar: Control = $Hotbar

func _on_hotbar_obstacle_selected(obstacle: ObstacleTypeResource) -> void:
  """Handle obstacle selection from hotbar"""
  Logger.info("UI", "Hotbar obstacle selected: %s" % obstacle.name)
  obstacle_spawn_requested.emit(obstacle)

func request_obstacle_spawn(obstacle: ObstacleTypeResource) -> void:
  obstacle_spawn_requested.emit(obstacle)

## Called when an enemy spawns to show the spawn indicator (legacy)
func _on_enemy_spawned(enemy: Node3D) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_spawn_notification"):
    spawn_indicator.show_spawn_notification(enemy)
  # Also update wave progress if we have a current wave
  if spawn_indicator and spawn_indicator.has_method("_update_wave_display"):
    spawn_indicator._update_wave_display()

## Called when a wave starts to show wave information
func _on_wave_started(wave: Wave, wave_number: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_wave_started"):
    spawn_indicator.show_wave_started(wave, wave_number)

## Called when a wave is completed
func _on_wave_completed(wave: Wave, wave_number: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_wave_completed"):
    spawn_indicator.show_wave_completed(wave, wave_number)