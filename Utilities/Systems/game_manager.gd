extends Node

enum GameState {
  MAIN_MENU,
  PLAYING,
  PAUSED,
  GAME_OVER,
  VICTORY
}

var current_state: GameState = GameState.PLAYING
var current_speed_multiplier: float = 1.0

signal game_state_changed(new_state: GameState)
signal speed_changed(new_speed: float)

func set_game_state(new_state: GameState):
    if current_state != new_state:
        current_state = new_state
        game_state_changed.emit(new_state)
        Logger.info("GameManager", "Game state changed to: %s" % GameState.keys()[new_state])

func pause_game():
    set_game_state(GameState.PAUSED)
    get_tree().paused = true
    # Store current speed and set time_scale to 0 for pause
    Engine.time_scale = 0.0

func resume_game():
    set_game_state(GameState.PLAYING)
    get_tree().paused = false
    # Restore the current speed when resuming
    Engine.time_scale = current_speed_multiplier

func set_game_speed(speed_multiplier: float):
    if speed_multiplier != current_speed_multiplier:
        current_speed_multiplier = speed_multiplier
        # Only apply speed change if not paused
        if current_state != GameState.PAUSED:
            Engine.time_scale = speed_multiplier
        speed_changed.emit(speed_multiplier)
        Logger.info("GameManager", "Game speed changed to: %.1fx" % speed_multiplier)

func get_game_speed() -> float:
    return current_speed_multiplier