extends Node

## Comprehensive stats tracking system for Tower Defense game
## Tracks enemy defeats, obstacle placements, currency metrics, and player actions
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

# Currency tracking
var total_currency_earned: int = 0
var max_currency_held: int = 0

# Signals for real-time updates
signal enemy_defeated(enemy_type: String, by_hand: bool)
signal obstacle_placed(obstacle_type: String)
signal stats_updated()

func _ready():
  Logger.info("StatsManager", "Stats tracking system initialized")
  
  # Connect to existing systems
  if CurrencyManager:
    CurrencyManager.currency_earned.connect(_on_currency_earned)
    CurrencyManager.currency_changed.connect(_on_currency_changed)
    # Initialize max currency with current amount
    max_currency_held = CurrencyManager.get_currency()
  else:
    Logger.error("StatsManager", "CurrencyManager not found!")

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

## Currency earned callback
func _on_currency_earned(amount: int) -> void:
  total_currency_earned += amount
  Logger.debug("Stats", "Currency earned: %d. Total earned: %d" % [amount, total_currency_earned])

## Currency changed callback - track maximum held
func _on_currency_changed(new_amount: int) -> void:
  if new_amount > max_currency_held:
    max_currency_held = new_amount
    Logger.debug("Stats", "New max currency held: %d" % max_currency_held)

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

func get_total_currency_earned() -> int:
  return total_currency_earned

func get_max_currency_held() -> int:
  return max_currency_held

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
    "total_currency_earned": total_currency_earned,
    "max_currency_held": max_currency_held
  }

## Reset all stats (for new game, testing, etc.)
func reset_stats() -> void:
  enemies_defeated_total = 0
  enemies_defeated_by_type.clear()
  enemies_defeated_by_hand = 0
  obstacles_placed_total = 0
  obstacles_placed_by_type.clear()
  total_currency_earned = 0
  max_currency_held = CurrencyManager.get_currency() if CurrencyManager else 0
  
  Logger.info("StatsManager", "All stats reset")
  stats_updated.emit()