extends Control

signal obstacle_spawn_requested(obstacle: ObstacleTypeResource)

@onready var spawn_indicator: Control = $SpawnIndicator
@onready var hotbar: Control = $Hotbar


func _process(_delta: float) -> void:
  # Handle pause toggle (ESC key)
  if Input.is_action_just_pressed("toggle_pause"):
    GameManager.toggle_pause()
    return

  if Input.is_action_just_pressed("toggle_in_game_menu"):
    GameManager.toggle_in_game_menu()
    return

func request_obstacle_spawn(obstacle: ObstacleTypeResource) -> void:
  Logger.info("UI", "Requesting obstacle spawn: %s" % obstacle.name)
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

## Called when an obstacle is removed to show removal feedback
func show_obstacle_removed(refund_amount: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_obstacle_removed"):
    spawn_indicator.show_obstacle_removed(refund_amount)