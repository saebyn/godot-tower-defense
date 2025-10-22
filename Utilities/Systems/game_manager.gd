extends Node

enum GameState {
  MAIN_MENU,
  PLAYING,
  IN_GAME_MENU,
  GAME_OVER,
  VICTORY
}

var current_level: int = 0
var current_wave: int = 0
var current_level_id: String = ""  # Track which level is currently being played

var current_state: GameState = GameState.MAIN_MENU
var current_speed_multiplier: float = 1.0

signal game_state_changed(new_state: GameState)
signal speed_changed(new_speed: float)
signal wave_changed(level: int, new_wave: int)

func set_complete_wave(level: int, wave: int):
    current_level = level
    current_wave = wave
    wave_changed.emit(level, wave)
    Logger.info("GameManager", "Set complete wave to Level %d, Wave %d" % [level, wave])

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

func get_game_level() -> int:
    return current_level

## Set the current level ID being played (e.g., "level_1")
func set_current_level_id(level_id: String):
    current_level_id = level_id
    Logger.info("GameManager", "Current level ID set to: %s" % level_id)

## Get the current level ID being played
func get_current_level_id() -> String:
    return current_level_id

## Returns to the main menu from any game state
func return_to_main_menu():
    Logger.info("GameManager", "Returning to main menu")
    resume_game() # Ensure the game is unpaused
    set_game_state(GameState.MAIN_MENU)
    
    # Load the main menu scene
    var main_menu_path = "res://Stages/UI/main_menu/main_menu.tscn"
    var error = get_tree().change_scene_to_file(main_menu_path)
    if error != OK:
        Logger.error("GameManager", "Failed to load main menu scene: %s (Error: %d)" % [main_menu_path, error])
