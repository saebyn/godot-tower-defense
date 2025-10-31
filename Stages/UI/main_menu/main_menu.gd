extends Control

class_name UI_MainMenu

## Main menu scene that handles navigation between different game states
## Sets the initial game state to MAIN_MENU and provides buttons for starting the game

const SettingsMenuScene = preload("res://Common/UI/settings_menu/settings_menu.tscn")
const TechTreeScene = preload("res://Stages/UI/tech_tree/tech_tree.tscn")
const AchievementListScene = preload("res://Stages/UI/achievement_list/achievement_list.tscn")

var settings_menu = null
var tech_tree_ui = null
var achievement_list_ui = null

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

func _on_scenario_select_button_pressed():
  Logger.info("MainMenu", "Scenario Select button pressed - transitioning to scenario selection")
  _show_scenario_select()

func _on_tech_tree_button_pressed():
  Logger.info("MainMenu", "Tech Tree button pressed")
  _show_tech_tree()

func _show_tech_tree():
  # Create tech tree UI if not already open
  if tech_tree_ui == null:
    tech_tree_ui = TechTreeScene.instantiate()
    add_child(tech_tree_ui)
    tech_tree_ui.closed.connect(_on_tech_tree_closed)
  else:
    tech_tree_ui.visible = true

func _on_tech_tree_closed():
  Logger.debug("MainMenu", "Tech tree closed")
  tech_tree_ui = null

func _on_achievements_button_pressed():
  Logger.info("MainMenu", "Achievements button pressed")
  _show_achievements()

func _show_achievements():
  # Create achievement list UI if not already open
  if achievement_list_ui == null:
    achievement_list_ui = AchievementListScene.instantiate()
    add_child(achievement_list_ui)
    achievement_list_ui.closed.connect(_on_achievement_list_closed)
  else:
    achievement_list_ui.visible = true

func _on_achievement_list_closed():
  Logger.debug("MainMenu", "Achievement list closed")
  achievement_list_ui = null

func _on_exit_button_pressed():
  Logger.info("MainMenu", "Exit button pressed - quitting game")
  get_tree().quit()

## Starts the main game by loading the game scene
func _start_game():
  # Ensure a save slot is loaded (default to slot 1)
  SaveManager.initialize_default_slot()
  
  ScenarioManager.set_current_scenario_id("scenario_1")
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Load the main game scene
  var game_scene_path = "res://Stages/Game/main/main.tscn"
  Logger.info("MainMenu", "Loading game scene: %s" % game_scene_path)
  
  # Change to the game scene
  var error = get_tree().change_scene_to_file(game_scene_path)
  if error != OK:
    Logger.error("MainMenu", "Failed to load game scene: %s (Error: %d)" % [game_scene_path, error])

## Show scenario selection screen
func _show_scenario_select():
  var scenario_select_path = "res://Stages/UI/scenario_select/scenario_select.tscn"
  Logger.info("MainMenu", "Loading scenario select scene: %s" % scenario_select_path)
  
  var error = get_tree().change_scene_to_file(scenario_select_path)
  if error != OK:
    Logger.error("MainMenu", "Failed to load scenario select scene: %s (Error: %d)" % [scenario_select_path, error])