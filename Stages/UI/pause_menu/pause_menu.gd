extends Control
class_name PauseMenu

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready():
  # Connect button signals
  resume_button.pressed.connect(_on_resume_pressed)
  restart_button.pressed.connect(_on_restart_pressed)
  main_menu_button.pressed.connect(_on_main_menu_pressed)
  quit_button.pressed.connect(_on_quit_pressed)
  
  # Initially hide the pause menu
  visible = false
  
  # Connect to GameManager state changes
  GameManager.game_state_changed.connect(_on_game_state_changed)

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
  GameManager.resume_game()

func _on_restart_pressed():
  GameManager.resume_game() # Unpause first
  # Reload the current scene
  get_tree().reload_current_scene()

func _on_main_menu_pressed():
  GameManager.return_to_main_menu()

func _on_quit_pressed():
  # Quit the game
  get_tree().quit()
