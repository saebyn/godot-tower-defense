extends Control

class_name MainMenu

## Main menu scene that handles navigation between different game states
## Sets the initial game state to MAIN_MENU and provides buttons for starting the game

const SettingsMenuScene = preload("res://Common/UI/settings_menu/settings_menu.tscn")

var settings_menu = null

func _ready():
  # Set the initial game state when the main menu loads
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  Logger.info("MainMenu", "Main menu loaded")
  
  # Make sure the game is not paused
  get_tree().paused = false
  
  # Create and add settings menu
  _setup_settings_menu()

func _setup_settings_menu():
  settings_menu = SettingsMenuScene.instantiate()
  add_child(settings_menu)
  settings_menu.closed.connect(_on_settings_menu_closed)

func _on_start_button_pressed():
  Logger.info("MainMenu", "Start button pressed - transitioning to game")
  _start_game()

func _on_settings_button_pressed():
  Logger.info("MainMenu", "Settings button pressed")
  if settings_menu:
    settings_menu.show_menu()

func _on_settings_menu_closed():
  Logger.debug("MainMenu", "Settings menu closed")

func _on_level_select_button_pressed():
  Logger.info("MainMenu", "Level Select button pressed - transitioning to level selection")
  _show_level_select()

func _on_exit_button_pressed():
  Logger.info("MainMenu", "Exit button pressed - quitting game")
  get_tree().quit()

## Starts the main game by loading the game scene
func _start_game():
  GameManager.set_current_level_id("level_1")
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Load the main game scene
  var game_scene_path = "res://Stages/Game/main/main.tscn"
  Logger.info("MainMenu", "Loading game scene: %s" % game_scene_path)
  
  # Change to the game scene
  var error = get_tree().change_scene_to_file(game_scene_path)
  if error != OK:
    Logger.error("MainMenu", "Failed to load game scene: %s (Error: %d)" % [game_scene_path, error])

## Show level selection screen
func _show_level_select():
  var level_select_path = "res://Stages/UI/level_select/level_select.tscn"
  Logger.info("MainMenu", "Loading level select scene: %s" % level_select_path)
  
  var error = get_tree().change_scene_to_file(level_select_path)
  if error != OK:
    Logger.error("MainMenu", "Failed to load level select scene: %s (Error: %d)" % [level_select_path, error])