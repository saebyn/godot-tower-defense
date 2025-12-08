class_name Stage_Scenario
extends Node3D

@export_category("References")
@export var enemy_spawner: System_EnemySpawner
@export var ui: Control

@export_category("Scenario Settings")
@export var scenario_environment: Environment ## Custom environment for this scenario (optional)

@export_category("Boundary Settings")
@export var boundary_min_x: float = -50.0 ## Minimum X boundary (west edge)
@export var boundary_max_x: float = 50.0 ## Maximum X boundary (east edge)
@export var boundary_min_z: float = -50.0 ## Minimum Z boundary
@export var boundary_max_z: float = 50.0 ## Maximum Z boundary

# Scenario timer tracking
var scenario_start_time: float = 0.0 # Time when first wave started (in seconds)
var scenario_elapsed_time: float = 0.0 # Total elapsed time (pause-aware)
var is_timing: bool = false # Whether timer is currently running
var timer_started: bool = false # Whether timer has been started at all

var survivor_count: int = 1


func _ready() -> void:
  # Apply custom environment if configured
  if scenario_environment:
    _apply_environment()
  
  enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
  enemy_spawner.wave_started.connect(_on_wave_started)
  enemy_spawner.wave_completed.connect(_on_wave_completed)
  enemy_spawner.all_waves_completed.connect(_on_all_waves_completed)
  
  # Connect to game state changes for pause handling
  GameManager.game_state_changed.connect(_on_game_state_changed)

  # Count the number of survivors at start
  survivor_count = get_tree().get_nodes_in_group("targets").size()
  MyLogger.info("Scenario", "Scenario started with %d survivors" % survivor_count)

func _process(delta: float) -> void:
  # Update timer if it's running and game is not paused
  if is_timing and not _is_paused():
    scenario_elapsed_time += delta

## Virtual method for pause check - can be overridden in tests
func _is_paused() -> bool:
  return GameManager.is_paused()


func _on_enemy_spawned(enemy: Node3D) -> void:
  if ui:
    ui._on_enemy_spawned(enemy)

func _on_wave_started(wave: System_Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  if ui:
    ui._on_wave_started(wave, wave_number)
  
  # Start timer on first wave
  if not timer_started:
    _start_timer()
    timer_started = true
    MyLogger.debug("Scenario", "Scenario timer started at wave %d" % wave_number)

func _on_wave_completed(wave: System_Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  if ui:
    ui._on_wave_completed(wave, wave_number)
  ScenarioManager.set_current_wave(wave_number)


func _on_all_waves_completed() -> void:
  MyLogger.info("Scenario", "All waves completed. Processing scenario completion...")
  
  # Stop the timer
  var completion_time = _stop_timer()
  MyLogger.info("Scenario", "Scenario completed in %.2f seconds" % completion_time)
  
  # Reclaim all placed obstacles and get refund
  var reclaim_data = _reclaim_all_obstacles()
  
  # Convert remaining scrap to XP
  var conversion_data = CurrencyManager.convert_remaining_scrap_to_xp()
  
  # Store victory statistics for UI display
  var scenario_id = ScenarioManager.get_current_scenario_id()
  
  # Check if this is a new record BEFORE updating the best time
  var previous_best_time = ScenarioManager.get_best_time(scenario_id)
  var is_new_record = previous_best_time == 0.0 or completion_time < previous_best_time
  
  ScenarioManager.last_scenario_stats = {
    "scenario_id": scenario_id,
    "completion_time": completion_time,
    "obstacles_reclaimed": reclaim_data.obstacle_count,
    "scrap_reclaimed": reclaim_data.total_refund,
    "scrap_converted": conversion_data.scrap_converted,
    "xp_gained_from_conversion": conversion_data.xp_gained,
    "is_new_record": is_new_record,
  }
  
  # Mark the scenario as complete in the progression system
  if not scenario_id.is_empty():
    ScenarioManager.mark_scenario_complete(scenario_id, completion_time)
    MyLogger.info("Scenario", "Scenario '%s' marked as complete" % scenario_id)
  else:
    MyLogger.error("Scenario", "Cannot mark scenario complete - no scenario ID set in ScenarioManager!")
  
  # Transition to victory state (UI will respond to this)
  assert(survivor_count > 0) # Shouldn't be here if all survivors are dead
  GameManager.set_game_state(GameManager.GameState.VICTORY)


func on_target_died(_target: Node3D, _damage_source: String) -> void:
  if survivor_count <= 0:
    MyLogger.warning("Scenario", "All survivors already dead, ignoring target death.")
    return

  survivor_count -= 1
  MyLogger.trace("Scenario", "A survivor has died. Remaining survivors: %d" % survivor_count)

  if survivor_count <= 0:
    MyLogger.info("Scenario", "All survivors have died. Triggering game over.")
    # Stop timer on game over (but don't save the time)
    var elapsed_time = _stop_timer()
    
    # Reclaim all placed obstacles and get refund (same as victory)
    var reclaim_data = _reclaim_all_obstacles()
    
    # Convert remaining scrap to XP (same as victory)
    var conversion_data = CurrencyManager.convert_remaining_scrap_to_xp()
    
    # Store stats for game over screen
    var scenario_id = ScenarioManager.get_current_scenario_id()
    ScenarioManager.last_scenario_stats = {
      "scenario_id": scenario_id,
      "elapsed_time": elapsed_time,
      "obstacles_reclaimed": reclaim_data.obstacle_count,
      "scrap_reclaimed": reclaim_data.total_refund,
      "scrap_converted": conversion_data.scrap_converted,
      "xp_gained_from_conversion": conversion_data.xp_gained,
    }
    
    GameManager.set_game_state(GameManager.GameState.GAME_OVER)


## Scenario Timer Methods

## Start the scenario timer
func _start_timer() -> void:
  scenario_start_time = Time.get_ticks_msec() / 1000.0
  scenario_elapsed_time = 0.0
  is_timing = true
  MyLogger.debug("Scenario", "Timer started")

## Stop the scenario timer and return elapsed time
func _stop_timer() -> float:
  if is_timing:
    is_timing = false
    MyLogger.debug("Scenario", "Timer stopped - Elapsed: %.2f seconds" % scenario_elapsed_time)
  return scenario_elapsed_time

## Get current elapsed time without stopping the timer
func get_elapsed_time() -> float:
  return scenario_elapsed_time

## Handle game state changes for pause/resume
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
  # Timer automatically pauses/resumes via is_paused() check in _process
  # This is just for logging/debugging if needed
  if new_state == GameManager.GameState.IN_GAME_MENU:
    MyLogger.trace("Scenario", "Game paused - timer paused at %.2f seconds" % scenario_elapsed_time)
  elif new_state == GameManager.GameState.PLAYING and timer_started:
    MyLogger.trace("Scenario", "Game resumed - timer continuing from %.2f seconds" % scenario_elapsed_time)


## Reclaim all placed obstacles and refund scrap based on their remaining health
## Returns a dictionary with reclaim details: {obstacle_count, total_refund}
func _reclaim_all_obstacles() -> Dictionary:
  var obstacles = get_tree().get_nodes_in_group("navigation_mesh_source_group")
  var obstacle_count = 0
  var total_refund = 0
  
  MyLogger.info("Scenario", "Reclaiming %d obstacles..." % obstacles.size())
  
  for node in obstacles:
    if node is Entity_PlaceableObstacle:
      var refund = node.remove()
      total_refund += refund
      obstacle_count += 1
      MyLogger.debug("Scenario", "Reclaimed obstacle, refunded %d scrap" % refund)
  
  MyLogger.info("Scenario", "Reclaimed %d obstacles for %d total scrap" % [obstacle_count, total_refund])
  
  return {
    "obstacle_count": obstacle_count,
    "total_refund": total_refund
  }


## Apply custom environment to the scene's WorldEnvironment
func _apply_environment() -> void:
  # Look for WorldEnvironment in the scene tree root
  var world_env = get_tree().root.get_node_or_null("Main/WorldEnvironment")
  
  if world_env and world_env is WorldEnvironment:
    world_env.environment = scenario_environment
    MyLogger.info("Scenario", "Applied custom environment to WorldEnvironment")
  else:
    MyLogger.warn("Scenario", "No WorldEnvironment found at 'Main/WorldEnvironment' - cannot apply scenario environment")
