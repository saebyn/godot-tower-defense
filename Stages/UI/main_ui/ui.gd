extends Control
class_name MainUI

signal obstacle_spawn_requested(obstacle: Resource_ObstacleType)

@onready var spawn_indicator: Control = $SpawnIndicator
@onready var hotbar: Control = $Hotbar
@onready var stats_display: Control = $StatsDisplay
@onready var fps_overlay: Control = $FpsOverlay
@onready var sound_effect_display: Control = $SoundEffectDisplay


func _process(_delta: float) -> void:
  if Input.is_action_just_pressed("toggle_in_game_menu"):
    GameManager.toggle_in_game_menu()
  elif Input.is_action_just_pressed("toggle_tech_tree"):
    _toggle_tech_tree()
  elif Input.is_action_just_pressed("toggle_stats"):
    _toggle_stats_display()
  elif Input.is_action_just_pressed("toggle_fps"):
    _toggle_fps_overlay()
  elif Input.is_action_just_pressed("toggle_sound_effects"):
    _toggle_sound_effect_display()


func request_obstacle_spawn(obstacle: Resource_ObstacleType) -> void:
  MyLogger.info("UI", "Requesting obstacle spawn: %s" % obstacle.name)
  obstacle_spawn_requested.emit(obstacle)

## Called when an enemy spawns to show the spawn indicator (legacy)
func _on_enemy_spawned(enemy: Node3D) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_spawn_notification"):
    spawn_indicator.show_spawn_notification(enemy)
  # Also update wave progress if we have a current wave
  if spawn_indicator and spawn_indicator.has_method("_update_wave_display"):
    spawn_indicator._update_wave_display()

## Called when a wave starts to show wave information
func _on_wave_started(wave: System_Wave, wave_number: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_wave_started"):
    spawn_indicator.show_wave_started(wave, wave_number)

## Called when a wave is completed
func _on_wave_completed(wave: System_Wave, wave_number: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_wave_completed"):
    spawn_indicator.show_wave_completed(wave, wave_number)

## Called when an obstacle is removed to show removal feedback
func show_obstacle_removed(refund_amount: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_obstacle_removed"):
    spawn_indicator.show_obstacle_removed(refund_amount)

## Toggle the tech tree UI visibility
func _toggle_tech_tree() -> void:
  MyLogger.info("UI", "Toggling Tech Tree UI")
  if GameManager.current_state == GameManager.GameState.IN_TECH_TREE:
    GameManager.set_game_state(GameManager.GameState.PLAYING)
  else:
    GameManager.pause_game()
    GameManager.set_game_state(GameManager.GameState.IN_TECH_TREE)

## Toggle the stats display visibility
func _toggle_stats_display() -> void:
  if stats_display:
    stats_display.toggle_visibility()
    MyLogger.info("UI", "Stats display toggled: %s" % ("visible" if stats_display.visible else "hidden"))

## Toggle the FPS overlay visibility
func _toggle_fps_overlay() -> void:
  if fps_overlay:
    fps_overlay.toggle_visibility()
    MyLogger.info("UI", "FPS overlay toggled: %s" % ("visible" if fps_overlay.visible else "hidden"))

## Toggle the sound effect display visibility
func _toggle_sound_effect_display() -> void:
  if sound_effect_display:
    sound_effect_display.toggle_display()
    MyLogger.info("UI", "Sound effect display toggled: %s" % ("visible" if sound_effect_display.visible else "hidden"))