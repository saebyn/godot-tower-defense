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
  Logger.info("MainMenu", "Start button pressed")
  
  # Check how many scenarios are unlocked
  var unlocked_scenarios: Array[String] = []
  var scenario_ids = ScenarioManager.get_all_scenario_ids()
  for scenario_id in scenario_ids:
    if ScenarioManager.is_scenario_unlocked(scenario_id):
      unlocked_scenarios.append(scenario_id)
  
  # If only one scenario is unlocked, go directly to it
  # Otherwise show scenario selection screen
  if unlocked_scenarios.size() == 1:
    var scenario_id = unlocked_scenarios[0]
    Logger.info("MainMenu", "Only one scenario unlocked (%s) - starting directly" % scenario_id)
    # Ensure a save slot is loaded before starting game
    SaveManager.initialize_default_slot()
    _start_specific_scenario(scenario_id)
  elif unlocked_scenarios.size() > 1:
    Logger.info("MainMenu", "Multiple scenarios unlocked - showing scenario select")
    # Scenario select screen will initialize save slot in its _ready() method
    _show_scenario_select()
  else:
    # Fallback: This should never happen as scenario_1 is always unlocked,
    # but handle gracefully just in case
    Logger.warn("MainMenu", "No scenarios unlocked - starting scenario_1 as fallback")
    SaveManager.initialize_default_slot()
    _start_specific_scenario("scenario_1")

func _on_settings_button_pressed():
  Logger.info("MainMenu", "Settings button pressed")
  if settings_menu:
    settings_menu.show_menu()

func _on_settings_menu_closed():
  Logger.debug("MainMenu", "Settings menu closed")

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

func _on_load_game_button_pressed():
  Logger.info("MainMenu", "Load Game button pressed - transitioning to save slot selection")
  _show_save_slot_selection()

func _on_exit_button_pressed():
  Logger.info("MainMenu", "Exit button pressed - quitting game")
  get_tree().quit()

## Starts a specific scenario by loading the game scene
func _start_specific_scenario(scenario_id: String):
  ScenarioManager.set_current_scenario_id(scenario_id)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Load the main game scene
  var game_scene_path = "res://Stages/Game/main/main.tscn"
  Logger.info("MainMenu", "Starting scenario %s - loading game scene: %s" % [scenario_id, game_scene_path])
  
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

## Show save slot selection screen
func _show_save_slot_selection():
  var save_slot_path = "res://Stages/UI/save_slot_selection/save_slot_selection.tscn"
  Logger.info("MainMenu", "Loading save slot selection scene: %s" % save_slot_path)
  
  var error = get_tree().change_scene_to_file(save_slot_path)
  if error != OK:
    Logger.error("MainMenu", "Failed to load save slot selection scene: %s (Error: %d)" % [save_slot_path, error])