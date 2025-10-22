extends Node

## Comprehensive stats tracking system for Tower Defense game
## Tracks enemy defeats, obstacle placements, currency metrics, and player actions
## Features persistent storage across game sessions
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

# Persistence
const STATS_SAVE_PATH = "user://stats.save"

# Signals for real-time updates
signal enemy_defeated(enemy_type: String, by_hand: bool)
signal obstacle_placed(obstacle_type: String)
signal max_scrap_held_updated(new_max: int)
signal stats_updated()
signal stats_loaded()
signal stats_saved()

func _ready():
  Logger.info("StatsManager", "Stats tracking system initialized")
  
  # Load persistent stats first
  _load_stats()
  
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

func _notification(what):
  # Auto-save when the game is closing
  if what == NOTIFICATION_WM_CLOSE_REQUEST:
    _save_stats()

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
  
  # Auto-save after significant events
  _save_stats()

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
  
  # Auto-save after significant events
  _save_stats()

## Scrap earned callback
func _on_scrap_earned(amount: int) -> void:
  total_scrap_earned += amount
  Logger.debug("Stats", "Scrap earned: %d. Total earned: %d" % [amount, total_scrap_earned])
  # Save periodically for scrap changes
  _save_stats()

## Scrap changed callback - track maximum held
func _on_scrap_changed(new_amount: int) -> void:
  if new_amount > max_scrap_held:
    max_scrap_held = new_amount
    Logger.debug("Stats", "New max scrap held: %d" % max_scrap_held)
    max_scrap_held_updated.emit(max_scrap_held)
    stats_updated.emit()
    # Save when we hit a new max
    _save_stats()

## XP earned callback
func _on_xp_earned(amount: int) -> void:
  total_xp_earned += amount
  Logger.debug("Stats", "XP earned: %d. Total earned: %d" % [amount, total_xp_earned])
  # Save periodically for XP changes
  _save_stats()

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
    "total_xp_earned": total_xp_earned
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
  
  Logger.info("StatsManager", "All stats reset")
  stats_updated.emit()
  
  # Save the reset state
  _save_stats()

## Persistence Methods

## Save stats to disk
func _save_stats() -> void:
  var save_file = FileAccess.open(STATS_SAVE_PATH, FileAccess.WRITE)
  if not save_file:
    Logger.error("StatsManager", "Could not open save file for writing: %s" % STATS_SAVE_PATH)
    return
  
  var save_data = {
    "version": 1,
    "enemies_defeated_total": enemies_defeated_total,
    "enemies_defeated_by_type": enemies_defeated_by_type,
    "enemies_defeated_by_hand": enemies_defeated_by_hand,
    "obstacles_placed_total": obstacles_placed_total,
    "obstacles_placed_by_type": obstacles_placed_by_type,
    "total_scrap_earned": total_scrap_earned,
    "max_scrap_held": max_scrap_held,
    "total_xp_earned": total_xp_earned
  }
  
  save_file.store_string(JSON.stringify(save_data))
  save_file.close()
  
  Logger.debug("StatsManager", "Stats saved to: %s" % STATS_SAVE_PATH)
  stats_saved.emit()

## Load stats from disk
func _load_stats() -> void:
  if not FileAccess.file_exists(STATS_SAVE_PATH):
    Logger.info("StatsManager", "No save file found, starting with fresh stats")
    return
  
  var save_file = FileAccess.open(STATS_SAVE_PATH, FileAccess.READ)
  if not save_file:
    Logger.error("StatsManager", "Could not open save file for reading: %s" % STATS_SAVE_PATH)
    return
  
  var json_string = save_file.get_as_text()
  save_file.close()
  
  var json = JSON.new()
  var parse_result = json.parse(json_string)
  
  if parse_result != OK:
    Logger.error("StatsManager", "Error parsing save file: %s" % json.get_error_message())
    return
  
  var save_data = json.get_data()
  
  if not save_data is Dictionary:
    Logger.error("StatsManager", "Save file contains invalid data")
    return
  
  # Load the data with fallbacks for missing keys
  enemies_defeated_total = save_data.get("enemies_defeated_total", 0)
  enemies_defeated_by_type = save_data.get("enemies_defeated_by_type", {})
  enemies_defeated_by_hand = save_data.get("enemies_defeated_by_hand", 0)
  obstacles_placed_total = save_data.get("obstacles_placed_total", 0)
  obstacles_placed_by_type = save_data.get("obstacles_placed_by_type", {})
  total_scrap_earned = save_data.get("total_scrap_earned", save_data.get("total_currency_earned", 0))
  max_scrap_held = save_data.get("max_scrap_held", save_data.get("max_currency_held", 0))
  total_xp_earned = save_data.get("total_xp_earned", 0)
  
  Logger.info("StatsManager", "Stats loaded from save file - Enemies defeated: %d, Obstacles placed: %d, Scrap earned: %d, XP earned: %d" % [enemies_defeated_total, obstacles_placed_total, total_scrap_earned, total_xp_earned])
  stats_loaded.emit()

## Manual save method for external use
func save_stats_now() -> void:
  _save_stats()

## Check if save file exists
func has_saved_stats() -> bool:
  return FileAccess.file_exists(STATS_SAVE_PATH)

## Delete save file (for complete reset)
func delete_saved_stats() -> bool:
  if FileAccess.file_exists(STATS_SAVE_PATH):
    var dir = DirAccess.open("user://")
    if dir:
      dir.remove("stats.save")
      Logger.info("StatsManager", "Save file deleted")
      return true
    else:
      Logger.error("StatsManager", "Could not access user directory to delete save file")
      return false
  return true