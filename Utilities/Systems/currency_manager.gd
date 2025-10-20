extends Node

## Manages the player's resource system (scrap and XP)
## Handles earning and spending scrap, and tracking experience points throughout the game

@export var starting_scrap: int = 100 # TODO change back to 0 before release
var current_scrap: int = 0
var current_xp: int = 0
var current_level: int = 1

# Persistence
const PROGRESSION_SAVE_PATH = "user://player_progression.save"
const SAVE_VERSION = 1

signal scrap_changed(new_amount: int)
signal scrap_earned(amount: int)
signal xp_changed(new_amount: int)
signal xp_earned(amount: int)
signal level_up(new_level: int)
signal progression_saved()
signal progression_loaded()

func _ready():
  # Load progression first (will set values if save file exists)
  _load_progression()
  
  # If no save file was loaded, use defaults
  if not FileAccess.file_exists(PROGRESSION_SAVE_PATH):
    current_scrap = starting_scrap
    current_xp = 0
    current_level = 1
  
  scrap_changed.emit(current_scrap)
  xp_changed.emit(current_xp)
  GameManager.game_state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
  # Save progression only on victory (not on death/game over)
  if new_state == GameManager.GameState.VICTORY:
    _save_progression()
  
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

## Persistence Methods

## Save player progression to disk
func _save_progression() -> void:
  var save_file = FileAccess.open(PROGRESSION_SAVE_PATH, FileAccess.WRITE)
  if not save_file:
    Logger.error("CurrencyManager", "Could not open save file for writing: %s" % PROGRESSION_SAVE_PATH)
    return
  
  var save_data = {
    "version": SAVE_VERSION,
    "current_level": current_level,
    "current_xp": current_xp,
    "current_scrap": current_scrap
  }
  
  save_file.store_string(JSON.stringify(save_data))
  save_file.close()
  
  Logger.info("CurrencyManager", "Progression saved - Level: %d, XP: %d, Scrap: %d" % [current_level, current_xp, current_scrap])
  progression_saved.emit()

## Load player progression from disk
func _load_progression() -> void:
  if not FileAccess.file_exists(PROGRESSION_SAVE_PATH):
    Logger.info("CurrencyManager", "No save file found, starting fresh")
    return
  
  var save_file = FileAccess.open(PROGRESSION_SAVE_PATH, FileAccess.READ)
  if not save_file:
    Logger.error("CurrencyManager", "Could not open save file for reading: %s" % PROGRESSION_SAVE_PATH)
    return
  
  var json_string = save_file.get_as_text()
  save_file.close()
  
  var json = JSON.new()
  var parse_result = json.parse(json_string)
  
  if parse_result != OK:
    Logger.error("CurrencyManager", "Error parsing save file: %s" % json.get_error_message())
    return
  
  var save_data = json.get_data()
  
  if not save_data is Dictionary:
    Logger.error("CurrencyManager", "Save file contains invalid data")
    return
  
  # Load the data with fallbacks for missing keys
  current_level = save_data.get("current_level", 1)
  current_xp = save_data.get("current_xp", 0)
  current_scrap = save_data.get("current_scrap", starting_scrap)
  
  Logger.info("CurrencyManager", "Progression loaded - Level: %d, XP: %d, Scrap: %d" % [current_level, current_xp, current_scrap])
  progression_loaded.emit()

## Manual save method for external use
func save_progression_now() -> void:
  _save_progression()

## Check if save file exists
func has_saved_progression() -> bool:
  return FileAccess.file_exists(PROGRESSION_SAVE_PATH)

## Delete save file (for complete reset)
func delete_saved_progression() -> bool:
  if FileAccess.file_exists(PROGRESSION_SAVE_PATH):
    var dir = DirAccess.open("user://")
    if dir:
      dir.remove("player_progression.save")
      Logger.info("CurrencyManager", "Progression save file deleted")
      return true
    else:
      Logger.error("CurrencyManager", "Could not access user directory to delete save file")
      return false
  return true