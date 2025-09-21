extends Node

enum GameState {
  MAIN_MENU,
  PLAYING,
  IN_GAME_MENU,
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
    Logger.debug("GameManager", "Pausing game...")
    get_tree().paused = true
    speed_changed.emit(0.0)

func resume_game():
    Logger.debug("GameManager", "Resuming game...")
    get_tree().paused = false
    speed_changed.emit(current_speed_multiplier)

func toggle_pause():
    Logger.debug("GameManager", "Toggling pause state...")
    var tree = get_tree()
    tree.paused = not tree.paused
    speed_changed.emit(0.0 if tree.paused else current_speed_multiplier)

func is_paused() -> bool:
    return get_tree().paused

func set_game_speed(speed_multiplier: float):
    if speed_multiplier <= 0:
        Logger.error("GameManager", "Speed multiplier must be greater than 0.")
        return

    if speed_multiplier != current_speed_multiplier:
        current_speed_multiplier = speed_multiplier
        speed_changed.emit(speed_multiplier)
        Engine.time_scale = speed_multiplier
        Logger.info("GameManager", "Game speed changed to: %.1fx" % speed_multiplier)

func get_game_speed() -> float:
    return current_speed_multiplier


func toggle_in_game_menu():
    if current_state == GameState.IN_GAME_MENU:
        set_game_state(GameState.PLAYING)
    elif current_state == GameState.PLAYING:
        pause_game()
        set_game_state(GameState.IN_GAME_MENU)
