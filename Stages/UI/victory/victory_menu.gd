extends Control

func _ready():
  # Initially hide the victory menu
  visible = false
  
  # Connect to GameManager state changes
  GameManager.game_state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(new_state: GameManager.GameState):
  match new_state:
    GameManager.GameState.VICTORY:
      visible = true
      # Mark current level as complete when victory is achieved
      var level_id = GameManager.get_current_level_id()
      if not level_id.is_empty():
        LevelProgressManager.mark_level_complete(level_id)
      else:
        Logger.warn("VictoryMenu", "Victory achieved but no current level ID set")
    _:
      visible = false


func _on_button_pressed() -> void:
  GameManager.return_to_main_menu()