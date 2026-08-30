extends Node

const NAVIGATION_MONITORS := {
  "Navigation/Active Zombies": Utility_NavigationMetrics.ACTIVE_ZOMBIES,
  "Navigation/Target Sets per Second": Utility_NavigationMetrics.TARGET_SETS_PER_SECOND,
  "Navigation/Duplicate Target Sets per Second": Utility_NavigationMetrics.DUPLICATE_TARGET_SETS_PER_SECOND,
  "Navigation/Duplicate Target Set Percent": Utility_NavigationMetrics.DUPLICATE_TARGET_SET_PERCENT,
  "Navigation/Explicit Path Queries per Second": Utility_NavigationMetrics.EXPLICIT_PATH_QUERIES_PER_SECOND,
  "Navigation/Explicit Path Query Time ms per Second": Utility_NavigationMetrics.EXPLICIT_PATH_QUERY_TIME_MSEC_PER_SECOND,
  "Navigation/Explicit Path Query Max ms": Utility_NavigationMetrics.EXPLICIT_PATH_QUERY_MAX_MSEC,
  "Navigation/Path Changes per Second": Utility_NavigationMetrics.PATH_CHANGES_PER_SECOND,
  "Navigation/Agent Path Update Time ms per Second": Utility_NavigationMetrics.AGENT_PATH_UPDATE_TIME_MSEC_PER_SECOND,
  "Navigation/Agent Path Update Max ms": Utility_NavigationMetrics.AGENT_PATH_UPDATE_MAX_MSEC,
  "Navigation/Reachability Checks per Second": Utility_NavigationMetrics.REACHABILITY_CHECKS_PER_SECOND,
  "Navigation/Fallback Checks per Second": Utility_NavigationMetrics.FALLBACK_CHECKS_PER_SECOND,
  "Navigation/Rebake Requests per Second": Utility_NavigationMetrics.REBAKE_REQUESTS_PER_SECOND,
  "Navigation/Rebakes Started per Second": Utility_NavigationMetrics.REBAKES_STARTED_PER_SECOND,
  "Navigation/Last Rebake ms": Utility_NavigationMetrics.LAST_REBAKE_MSEC,
}

enum GameState {
  MAIN_MENU, ## When the player is in the main menu
  PLAYING, ## When the player is actively playing a scenario
  IN_GAME_MENU, ## When the in-game menu is open (game is paused)
  IN_TECH_TREE, ## When the tech tree UI is open
  GAME_OVER, ## When the player has lost any scenario
  VICTORY, ## When the player successfully completes any scenario
  ALL_DONE ## Represents the state after the final scenario is completed
}

var current_state: GameState = GameState.MAIN_MENU
var current_speed_multiplier: float = 1.0

signal game_state_changed(new_state: GameState)
signal speed_changed(new_speed: float)


func _ready() -> void:
    Utility_NavigationMetrics.reset()
    _register_navigation_monitors()


func _process(delta: float) -> void:
    Utility_NavigationMetrics.update(delta)


func _register_navigation_monitors() -> void:
    for monitor_name in NAVIGATION_MONITORS:
        if Performance.has_custom_monitor(monitor_name):
            Performance.remove_custom_monitor(monitor_name)
        Performance.add_custom_monitor(
            monitor_name,
            _get_navigation_metric,
            [NAVIGATION_MONITORS[monitor_name]],
        )


func _get_navigation_metric(metric: StringName) -> float:
    return Utility_NavigationMetrics.get_metric(metric)


func set_game_state(new_state: GameState):
    if current_state != new_state:
        current_state = new_state
        game_state_changed.emit(new_state)
        MyLogger.info("GameManager", "Game state changed to: %s" % GameState.keys()[new_state])

func is_playing() -> bool:
    return current_state == GameState.PLAYING

func pause_game():
    MyLogger.debug("GameManager", "Pausing game...")
    get_tree().paused = true
    speed_changed.emit(0.0)

func resume_game():
    MyLogger.debug("GameManager", "Resuming game...")
    get_tree().paused = false
    speed_changed.emit(current_speed_multiplier)

func toggle_pause():
    MyLogger.debug("GameManager", "Toggling pause state...")
    var tree = get_tree()
    tree.paused = not tree.paused
    speed_changed.emit(0.0 if tree.paused else current_speed_multiplier)

func is_paused() -> bool:
    return get_tree().paused

func set_game_speed(speed_multiplier: float):
    if speed_multiplier <= 0:
        MyLogger.error("GameManager", "Speed multiplier must be greater than 0.")
        return

    if speed_multiplier != current_speed_multiplier:
        current_speed_multiplier = speed_multiplier
        speed_changed.emit(speed_multiplier)
        Engine.time_scale = speed_multiplier
        MyLogger.info("GameManager", "Game speed changed to: %.1fx" % speed_multiplier)

func get_game_speed() -> float:
    return current_speed_multiplier


func toggle_in_game_menu():
    MyLogger.debug("GameManager", "Toggling in-game menu...")
    match current_state:
        GameState.IN_GAME_MENU:
            set_game_state(GameState.PLAYING)
        GameState.IN_TECH_TREE:
            set_game_state(GameState.PLAYING)
        GameState.PLAYING:
            pause_game()
            set_game_state(GameState.IN_GAME_MENU)

## Restarts the current scenario from scratch, reloading all save state
## so that currency, tech tree, and other managed systems are fully reset
## back to what they were at the start of the session.
func restart_scenario() -> void:
  MyLogger.info("GameManager", "Restarting current scenario")
  resume_game() # Ensure the game is unpaused before reloading
  set_game_state(GameState.PLAYING)

  # Preserve the scenario the player is currently in
  var scenario_id = ScenarioManager.get_current_scenario_id()

  # Reload the save slot — this calls reset_data() or load_data() on every
  # registered SaveableSystem (CurrencyManager, TechTreeManager, etc.) so
  # the in-memory state is fully restored to what they were on disk.
  if SaveManager.current_save_slot > 0:
    SaveManager.load_save_slot(SaveManager.current_save_slot)
  else:
    # Fallback: manually reset all managed systems
    for system in SaveManager.managed_systems:
      system.reset_data()

  # Restore the scenario ID after the slot reload (load_save_slot may
  # overwrite it with the value stored in metadata).
  if not scenario_id.is_empty():
    ScenarioManager.set_current_scenario_id(scenario_id)

  # Reload the game scene so all scene-level nodes are freshly instantiated
  var game_scene_path = "res://Stages/Game/main/main.tscn"
  var error = get_tree().change_scene_to_file(game_scene_path)
  if error != OK:
    MyLogger.error("GameManager", "Failed to reload game scene: %s (Error: %d)" % [game_scene_path, error])

## Returns to the main menu from any game state
func return_to_main_menu():
  MyLogger.info("GameManager", "Returning to main menu")
  resume_game() # Ensure the game is unpaused
  set_game_state(GameState.MAIN_MENU)
  
  # Clear the current scenario in ScenarioManager
  ScenarioManager.clear_current_scenario()
  
  # Load the main menu scene
  var main_menu_path = "res://Stages/UI/main_menu/main_menu.tscn"
  var error = get_tree().change_scene_to_file(main_menu_path)
  if error != OK:
    MyLogger.error("GameManager", "Failed to load main menu scene: %s (Error: %d)" % [main_menu_path, error])
