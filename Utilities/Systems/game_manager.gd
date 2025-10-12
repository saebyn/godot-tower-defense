extends Node

enum GameState {
  MAIN_MENU,
  PLAYING,
  IN_GAME_MENU,
  GAME_OVER,
  VICTORY
}

var current_state: GameState = GameState.MAIN_MENU
var current_speed_multiplier: float = 1.0
var current_level_buildable_area: Rect2 = Rect2()

signal game_state_changed(new_state: GameState)
signal speed_changed(new_speed: float)
signal buildable_area_changed(buildable_area: Rect2)

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

## Sets the buildable area for the current level
## Called by Level when it's ready
func set_level_buildable_area(buildable_area: Rect2):
    if current_level_buildable_area != buildable_area:
        current_level_buildable_area = buildable_area
        buildable_area_changed.emit(buildable_area)
        if buildable_area != Rect2():
            Logger.info("GameManager", "Level buildable area registered: %s" % buildable_area)
        else:
            Logger.info("GameManager", "Level buildable area cleared")

## Gets the current level's buildable area
func get_level_buildable_area() -> Rect2:
    return current_level_buildable_area
