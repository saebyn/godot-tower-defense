extends Control

class_name LevelSelect

## Level selection UI that displays available levels and handles level loading
## Shows completion status, best scores, and enforces unlock progression

@onready var level_container = $MarginContainer/VBoxContainer/ScrollContainer/LevelContainer
@onready var back_button = $MarginContainer/VBoxContainer/TopBar/BackButton

# Level card scene to be instantiated for each level
const LevelCardScene = preload("res://Stages/UI/level_select/level_card.tscn")

func _ready():
  # Set the game state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  Logger.info("LevelSelect", "Level selection screen loaded")
  
  # Make sure the game is not paused
  get_tree().paused = false
  
  # Connect signals
  back_button.pressed.connect(_on_back_button_pressed)
  
  # Populate level list
  _populate_levels()

## Populate the level container with level cards
func _populate_levels():
  # Clear existing children (if any)
  for child in level_container.get_children():
    child.queue_free()
  
  # Get all level IDs and create a card for each
  var level_ids = LevelProgressManager.get_all_level_ids()
  
  for level_id in level_ids:
    var level_card = LevelCardScene.instantiate()
    level_container.add_child(level_card)
    
    # Configure the card
    var metadata = LevelProgressManager.get_level_metadata(level_id)
    var is_unlocked = LevelProgressManager.is_level_unlocked(level_id)
    var is_completed = LevelProgressManager.is_level_completed(level_id)
    var best_time = LevelProgressManager.get_best_time(level_id)
    var best_score = LevelProgressManager.get_best_score(level_id)
    
    level_card.configure(
      level_id,
      metadata.get("name", "Unknown Level"),
      metadata.get("description", ""),
      is_unlocked,
      is_completed,
      best_time,
      best_score
    )
    
    # Connect the level selection signal
    level_card.level_selected.connect(_on_level_selected)

## Handle level selection
func _on_level_selected(level_id: String):
  var metadata = LevelProgressManager.get_level_metadata(level_id)
  var scene_path = metadata.get("scene_path", "")
  
  # Check if level is unlocked
  if not LevelProgressManager.is_level_unlocked(level_id):
    Logger.warn("LevelSelect", "Attempted to select locked level: %s" % level_id)
    return
  
  # Check if scene path exists
  if scene_path.is_empty():
    Logger.error("LevelSelect", "Level %s has no scene path configured" % level_id)
    # Show a message to the user
    _show_level_unavailable_message(metadata.get("name", level_id))
    return
  
  # Load the level
  Logger.info("LevelSelect", "Loading level: %s from %s" % [level_id, scene_path])
  GameManager.set_current_level_id(level_id)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  var error = get_tree().change_scene_to_file(scene_path)
  if error != OK:
    Logger.error("LevelSelect", "Failed to load level scene: %s (Error: %d)" % [scene_path, error])

## Show a message when level is not yet available
func _show_level_unavailable_message(level_name: String):
  # For now, just log it - could be enhanced with a popup dialog in the future
  Logger.info("LevelSelect", "Level '%s' is coming soon!" % level_name)

## Handle back button press - return to main menu
func _on_back_button_pressed():
  Logger.info("LevelSelect", "Back button pressed - returning to main menu")
  var main_menu_path = "res://Stages/UI/main_menu/main_menu.tscn"
  var error = get_tree().change_scene_to_file(main_menu_path)
  if error != OK:
    Logger.error("LevelSelect", "Failed to load main menu: %s (Error: %d)" % [main_menu_path, error])
