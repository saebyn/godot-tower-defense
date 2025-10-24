extends Control
class_name PauseMenu

const SettingsMenuScene = preload("res://Common/UI/settings_menu/settings_menu.tscn")
const TechTreeScene = preload("res://Stages/UI/tech_tree/tech_tree.tscn")
const AchievementListScene = preload("res://Stages/UI/achievement_list/achievement_list.tscn")

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var tech_tree_button: Button = $VBoxContainer/TechTreeButton
@onready var achievements_button: Button = $VBoxContainer/AchievementsButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

var settings_menu = null
var tech_tree_ui = null
var achievement_list_ui = null

func _ready():
  # Initially hide the pause menu
  visible = false
  
  # Connect to GameManager state changes
  GameManager.game_state_changed.connect(_on_game_state_changed)
  
  # Create and add settings menu
  _setup_settings_menu()

func _setup_settings_menu():
  settings_menu = SettingsMenuScene.instantiate()
  add_child(settings_menu)
  settings_menu.closed.connect(_on_settings_menu_closed)

func _on_game_state_changed(new_state: GameManager.GameState):
  match new_state:
    GameManager.GameState.IN_GAME_MENU:
      show_menu()
    GameManager.GameState.PLAYING:
      hide_menu()

func show_menu():
  visible = true
  # Focus the resume button for keyboard navigation
  resume_button.grab_focus()

func hide_menu():
  visible = false

func _on_resume_pressed():
  GameManager.toggle_in_game_menu()

func _on_settings_pressed():
  Logger.info("PauseMenu", "Settings button pressed")
  if settings_menu:
    settings_menu.show_menu()

func _on_tech_tree_pressed():
  Logger.info("PauseMenu", "Tech Tree button pressed")
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
  Logger.debug("PauseMenu", "Tech tree closed")
  tech_tree_ui = null

func _on_achievements_pressed():
  Logger.info("PauseMenu", "Achievements button pressed")
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
  Logger.debug("PauseMenu", "Achievement list closed")
  achievement_list_ui = null

func _on_settings_menu_closed():
  Logger.debug("PauseMenu", "Settings menu closed")

func _on_restart_pressed():
  GameManager.resume_game() # Unpause first
  # Reload the current scene
  get_tree().reload_current_scene()

func _on_main_menu_pressed():
  GameManager.return_to_main_menu()

func _on_quit_pressed():
  # Quit the game
  get_tree().quit()
