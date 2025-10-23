extends Node

## Comprehensive stats tracking system for Tower Defense game
## Tracks enemy defeats, obstacle placements, currency metrics, and player actions
## Features persistent storage via SaveManager
## 
## Usage:
##   StatsManager.track_enemy_defeated("basic_enemy", false)
##   StatsManager.track_obstacle_placed("turret")
##   StatsManager.get_enemies_defeated_by_type("basic_enemy")

# Enemy defeat tracking
var enemies_defeated_total: int = 0
var enemies_defeated_by_type: Dictionary = {} # String -> int
var enemies_defeated_by_hand: int = 0

# Obstacle placement tracking
var obstacles_placed_total: int = 0
var obstacles_placed_by_type: Dictionary = {} # String -> int

# Resource tracking (scrap and XP)
var total_scrap_earned: int = 0
var max_scrap_held: int = 0
var total_xp_earned: int = 0

# Level tracking
var waves_completed: int = 0
var max_waves_completed: int = 0

# Signals for real-time updates
signal enemy_defeated(enemy_type: String, by_hand: bool)
signal obstacle_placed(obstacle_type: String)
signal max_scrap_held_updated(new_max: int)
signal stats_updated()
signal stats_loaded()
signal stats_saved()

func _ready():
  Logger.info("StatsManager", "Stats tracking system initialized")
  
  # Register with SaveManager
  SaveManager.register_system(self)
  
  # Connect to existing systems
  if CurrencyManager:
    CurrencyManager.scrap_earned.connect(_on_scrap_earned)
    CurrencyManager.scrap_changed.connect(_on_scrap_changed)
    CurrencyManager.xp_earned.connect(_on_xp_earned)
    # Update max scrap with current amount if it's higher
    var current_scrap = CurrencyManager.get_scrap()
    if current_scrap > max_scrap_held:
      max_scrap_held = current_scrap
  else:
    Logger.error("StatsManager", "CurrencyManager not found!")

  if GameManager:
    GameManager.game_state_changed.connect(_on_game_state_changed)
  else:
    Logger.error("StatsManager", "GameManager not found!")

  if LevelManager:
    LevelManager.wave_changed.connect(_on_wave_changed)
  else:
    Logger.error("StatsManager", "LevelManager not found!")

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
  # Reset wave completion count on new game start
  if new_state == GameManager.GameState.MAIN_MENU:
    waves_completed = 0

## Track an enemy defeat
func track_enemy_defeated(enemy_type: String, defeated_by_hand: bool = false) -> void:
  enemies_defeated_total += 1
  
  # Track by type
  if enemy_type in enemies_defeated_by_type:
    enemies_defeated_by_type[enemy_type] += 1
  else:
    enemies_defeated_by_type[enemy_type] = 1
  
  # Track defeats by hand vs by obstacles
  if defeated_by_hand:
    enemies_defeated_by_hand += 1
  
  Logger.debug("Stats", "Enemy defeated: %s (by hand: %s). Total: %d" % [enemy_type, defeated_by_hand, enemies_defeated_total])
  
  enemy_defeated.emit(enemy_type, defeated_by_hand)
  stats_updated.emit()

## Track an obstacle placement
func track_obstacle_placed(obstacle_type: String) -> void:
  obstacles_placed_total += 1
  
  # Track by type
  if obstacle_type in obstacles_placed_by_type:
    obstacles_placed_by_type[obstacle_type] += 1
  else:
    obstacles_placed_by_type[obstacle_type] = 1
  
  Logger.debug("Stats", "Obstacle placed: %s. Total: %d" % [obstacle_type, obstacles_placed_total])
  
  obstacle_placed.emit(obstacle_type)
  stats_updated.emit()

## Scrap earned callback
func _on_scrap_earned(amount: int) -> void:
  total_scrap_earned += amount
  Logger.debug("Stats", "Scrap earned: %d. Total earned: %d" % [amount, total_scrap_earned])

## Scrap changed callback - track maximum held
func _on_scrap_changed(new_amount: int) -> void:
  if new_amount > max_scrap_held:
    max_scrap_held = new_amount
    Logger.debug("Stats", "New max scrap held: %d" % max_scrap_held)
    max_scrap_held_updated.emit(max_scrap_held)
    stats_updated.emit()

## XP earned callback
func _on_xp_earned(amount: int) -> void:
  total_xp_earned += amount
  Logger.debug("Stats", "XP earned: %d. Total earned: %d" % [amount, total_xp_earned])

## Max waves completed callback
func _on_wave_changed(_level_id: String, _wave: int) -> void:
  waves_completed += 1
  if waves_completed > max_waves_completed:
    max_waves_completed = waves_completed
    Logger.debug("Stats", "New max waves completed: %d" % max_waves_completed)
    stats_updated.emit()

## Get stats data

func get_enemies_defeated_total() -> int:
  return enemies_defeated_total

func get_enemies_defeated_by_type(enemy_type: String) -> int:
  return enemies_defeated_by_type.get(enemy_type, 0)

func get_enemies_defeated_by_hand() -> int:
  return enemies_defeated_by_hand

func get_obstacles_placed_total() -> int:
  return obstacles_placed_total

func get_obstacles_placed_by_type(obstacle_type: String) -> int:
  return obstacles_placed_by_type.get(obstacle_type, 0)

func get_total_scrap_earned() -> int:
  return total_scrap_earned

func get_max_scrap_held() -> int:
  return max_scrap_held

func get_total_xp_earned() -> int:
  return total_xp_earned

func get_all_enemy_types() -> Array[String]:
  return enemies_defeated_by_type.keys()

func get_all_obstacle_types() -> Array[String]:
  return obstacles_placed_by_type.keys()

func get_max_waves_completed() -> int:
  return max_waves_completed

## Get comprehensive stats summary
func get_stats_summary() -> Dictionary:
  return {
    "enemies_defeated_total": enemies_defeated_total,
    "enemies_defeated_by_type": enemies_defeated_by_type.duplicate(),
    "enemies_defeated_by_hand": enemies_defeated_by_hand,
    "obstacles_placed_total": obstacles_placed_total,
    "obstacles_placed_by_type": obstacles_placed_by_type.duplicate(),
    "total_scrap_earned": total_scrap_earned,
    "max_scrap_held": max_scrap_held,
    "total_xp_earned": total_xp_earned,
    "max_waves_completed": max_waves_completed
  }

## Reset all stats (for new game, testing, etc.)
func reset_stats() -> void:
  enemies_defeated_total = 0
  enemies_defeated_by_type.clear()
  enemies_defeated_by_hand = 0
  obstacles_placed_total = 0
  obstacles_placed_by_type.clear()
  total_scrap_earned = 0
  max_scrap_held = CurrencyManager.get_scrap() if CurrencyManager else 0
  total_xp_earned = 0
  max_waves_completed = 0
  
  Logger.info("StatsManager", "All stats reset")
  stats_updated.emit()

## SaveableSystem Interface Implementation

## Get unique save key for this system
func get_save_key() -> String:
  return "stats"

## Get saveable state as dictionary
func get_save_data() -> Dictionary:
  return {
    "enemies_defeated_total": enemies_defeated_total,
    "enemies_defeated_by_type": enemies_defeated_by_type,
    "enemies_defeated_by_hand": enemies_defeated_by_hand,
    "obstacles_placed_total": obstacles_placed_total,
    "obstacles_placed_by_type": obstacles_placed_by_type,
    "total_scrap_earned": total_scrap_earned,
    "max_scrap_held": max_scrap_held,
    "total_xp_earned": total_xp_earned,
    "max_waves_completed": max_waves_completed
  }

## Load data from saved state
func load_data(data: Dictionary) -> void:
  enemies_defeated_total = data.get("enemies_defeated_total", 0)
  enemies_defeated_by_type = data.get("enemies_defeated_by_type", {})
  enemies_defeated_by_hand = data.get("enemies_defeated_by_hand", 0)
  obstacles_placed_total = data.get("obstacles_placed_total", 0)
  obstacles_placed_by_type = data.get("obstacles_placed_by_type", {})
  total_scrap_earned = data.get("total_scrap_earned", data.get("total_currency_earned", 0))
  max_scrap_held = data.get("max_scrap_held", data.get("max_currency_held", 0))
  total_xp_earned = data.get("total_xp_earned", 0)
  max_waves_completed = data.get("max_waves_completed", 0)
  
  Logger.info("StatsManager", "Stats loaded - Enemies defeated: %d, Obstacles placed: %d, Scrap earned: %d, XP earned: %d" % [enemies_defeated_total, obstacles_placed_total, total_scrap_earned, total_xp_earned])
  stats_loaded.emit()

## Reset to default state (for new game)
func reset_data() -> void:
  reset_stats()

## Legacy Methods (deprecated, kept for backward compatibility)

## Manual save method for external use (now delegates to SaveManager)
func save_stats_now() -> void:
  SaveManager.save_current_slot()

## Check if save file exists (checks SaveManager instead)
func has_saved_stats() -> bool:
  return SaveManager.current_save_slot > 0

## Delete save file (delegates to SaveManager)
func delete_saved_stats() -> bool:
  if SaveManager.current_save_slot > 0:
    return SaveManager.delete_save_slot(SaveManager.current_save_slot)
  return true
