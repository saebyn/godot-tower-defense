extends Node

## Manages the player's resource system (scrap and XP)
## Handles earning and spending scrap, and tracking experience points throughout the game
## Implements SaveableSystem interface for centralized save management

@export var starting_scrap: int = 100 # TODO change back to 0 before release
var current_scrap: int = 0
var current_xp: int = 0
var current_level: int = 1

signal scrap_changed(new_amount: int)
signal scrap_earned(amount: int)
signal xp_changed(new_amount: int)
signal xp_earned(amount: int)
signal level_up(new_level: int)
signal progression_saved()
signal progression_loaded()

func _ready():
  # Register with SaveManager
  SaveManager.register_system(self)
  
  # Initialize with defaults (will be overridden if save is loaded)
  reset_data()
  
  scrap_changed.emit(current_scrap)
  xp_changed.emit(current_xp)
  GameManager.game_state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
  # Save progression only on victory (not on death/game over)
  if new_state == GameManager.GameState.VICTORY:
    # Only save if a slot is loaded
    if SaveManager.current_save_slot != -1:
      SaveManager.save_current_slot()
    else:
      Logger.warn("CurrencyManager", "Cannot save - no save slot loaded")
  
  # Note: We no longer reset progression on MAIN_MENU - progression persists across sessions
  # Starting scrap for each level is handled by game logic, not here

## Add scrap to the player's total
func earn_scrap(amount: int) -> void:
  if amount <= 0:
    return
  
  current_scrap += amount
  scrap_earned.emit(amount)
  scrap_changed.emit(current_scrap)
  Logger.info("Economy", "Earned %d scrap. Total: %d" % [amount, current_scrap])

## Add XP to the player's total
func earn_xp(amount: int) -> void:
  if amount <= 0:
    return
  
  current_xp += amount
  xp_earned.emit(amount)
  xp_changed.emit(current_xp)
  Logger.info("Economy", "Earned %d XP. Total: %d" % [amount, current_xp])
  _check_level_up()

## Calculates the XP required for the next level.
## Scaling approach: Linear (XP required increases by a fixed amount per level).
## Formula: XP required = current_level * xp_per_level_base
## Currently, xp_per_level_base is set to 100, so each level requires 100 more XP than the previous.
## TODO To make this configurable in the future, adjust xp_per_level_base or implement an exponential formula.
@export var xp_per_level_base: int = 100 # Base XP required per level (configurable)
func _get_xp_for_next_level() -> int:
  return current_level * xp_per_level_base

## Check if player has enough XP to level up
func _check_level_up() -> void:
  var xp_for_next_level = _get_xp_for_next_level()
  while current_xp >= xp_for_next_level:
    current_xp -= xp_for_next_level
    current_level += 1
    level_up.emit(current_level)
    Logger.info("Economy", "Leveled up to level %d!" % current_level)
    xp_changed.emit(current_xp)
    xp_for_next_level = _get_xp_for_next_level()

## Spend scrap if player has enough
func spend_scrap(amount: int) -> bool:
  if amount <= 0:
    return false
  
  if current_scrap >= amount:
    current_scrap -= amount
    scrap_changed.emit(current_scrap)
    Logger.info("Economy", "Spent %d scrap. Remaining: %d" % [amount, current_scrap])
    return true
  else:
    Logger.warn("Economy", "Not enough scrap. Need %d but only have %d" % [amount, current_scrap])
    return false

## Get current scrap amount
func get_scrap() -> int:
  return current_scrap

## Get current XP amount
func get_xp() -> int:
  return current_xp

## Get current player level
func get_level() -> int:
  return current_level

## SaveableSystem Interface Implementation

## Get unique save key for this system
func get_save_key() -> String:
  return "player_progression"

## Get saveable state as dictionary
func get_save_data() -> Dictionary:
  return {
    "current_level": current_level,
    "current_xp": current_xp,
    "current_scrap": current_scrap
  }

## Load data from saved state
func load_data(data: Dictionary) -> void:
  current_level = data.get("current_level", 1)
  current_xp = data.get("current_xp", 0)
  current_scrap = data.get("current_scrap", starting_scrap)
  
  # Emit signals to update UI
  scrap_changed.emit(current_scrap)
  xp_changed.emit(current_xp)
  
  Logger.info("CurrencyManager", "Progression loaded - Level: %d, XP: %d, Scrap: %d" % [current_level, current_xp, current_scrap])
  progression_loaded.emit()

## Reset to default state (for new game)
func reset_data() -> void:
  current_level = 1
  current_xp = 0
  current_scrap = starting_scrap
  
  Logger.info("CurrencyManager", "Progression reset to defaults")

## Legacy Methods (deprecated, kept for backward compatibility)

## Manual save method for external use (now delegates to SaveManager)
func save_progression_now() -> void:
  SaveManager.save_current_slot()

## Check if save file exists (checks SaveManager instead)
func has_saved_progression() -> bool:
  return SaveManager.current_save_slot > 0

## Delete save file (delegates to SaveManager)
func delete_saved_progression() -> bool:
  if SaveManager.current_save_slot > 0:
    return SaveManager.delete_save_slot(SaveManager.current_save_slot)
  return true