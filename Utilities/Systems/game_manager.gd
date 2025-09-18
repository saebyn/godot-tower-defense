extends Node

enum GameState {
  MAIN_MENU,
  PLAYING,
  PAUSED,
  GAME_OVER,
  VICTORY
}

var current_state: GameState = GameState.PLAYING

signal game_state_changed(new_state: GameState)

func set_game_state(new_state: GameState):
    if current_state != new_state:
        current_state = new_state
        game_state_changed.emit(new_state)
        Logger.info("GameManager", "Game state changed to: %s" % GameState.keys()[new_state])

func pause_game():
    set_game_state(GameState.PAUSED)
    get_tree().paused = true

func resume_game():
    set_game_state(GameState.PLAYING)
    get_tree().paused = false