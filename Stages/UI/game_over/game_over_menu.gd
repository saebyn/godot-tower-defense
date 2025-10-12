extends Control

func _ready():
  # Initially hide the pause menu
  visible = false
  
  # Connect to GameManager state changes
  GameManager.game_state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(new_state: GameManager.GameState):
  match new_state:
    GameManager.GameState.GAME_OVER:
      visible = true
    _:
      visible = false

func _on_button_pressed() -> void:
  GameManager.return_to_main_menu()
