extends Control

signal obstacle_spawn_requested(obstacle: Resource_ObstacleType)

const TechTreeScene = preload("res://Stages/UI/tech_tree/tech_tree.tscn")

@onready var spawn_indicator: Control = $SpawnIndicator
@onready var hotbar: Control = $Hotbar
@onready var stats_display: Control = $StatsDisplay
@onready var fps_overlay: Control = $FpsOverlay
@onready var tech_tree_button: Button = $TechTreeButton

var tech_tree_ui = null


func _ready() -> void:
  if tech_tree_button:
    tech_tree_button.pressed.connect(_on_tech_tree_button_pressed)


func _process(_delta: float) -> void:
  if Input.is_action_just_pressed("toggle_in_game_menu"):
    GameManager.toggle_in_game_menu()
  elif Input.is_action_just_pressed("toggle_tech_tree"):
    _toggle_tech_tree()
  elif Input.is_action_just_pressed("toggle_stats"):
    _toggle_stats_display()
  elif Input.is_action_just_pressed("toggle_fps"):
    _toggle_fps_overlay()


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


## Handle tech tree button press
func _on_tech_tree_button_pressed() -> void:
  _toggle_tech_tree()


## Toggle the tech tree UI
func _toggle_tech_tree() -> void:
  if tech_tree_ui == null:
    _show_tech_tree()
  else:
    _close_tech_tree()


## Show the tech tree UI
func _show_tech_tree() -> void:
  # Prevent opening multiple instances
  if tech_tree_ui != null:
    return
  
  MyLogger.info("UI", "Opening tech tree")
  
  # Pause the game
  GameManager.pause_game()
  
  # Create tech tree UI
  tech_tree_ui = TechTreeScene.instantiate()
  add_child(tech_tree_ui)
  tech_tree_ui.closed.connect(_close_tech_tree)


## Close the tech tree UI
func _close_tech_tree() -> void:
  if tech_tree_ui:
    MyLogger.info("UI", "Closing tech tree")
    
    # Tech tree frees itself, just null the reference
    tech_tree_ui = null
    
    # Resume the game
    GameManager.resume_game()