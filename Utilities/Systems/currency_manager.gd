extends Node

## Manages the player's resource system (scrap and XP)
## Handles earning and spending scrap, and tracking experience points throughout the game

@export var starting_scrap: int = 100 # TODO change back to 0 before release
var current_scrap: int = 0
var current_xp: int = 0
var current_level: int = 1

signal scrap_changed(new_amount: int)
signal scrap_earned(amount: int)
signal xp_changed(new_amount: int)
signal xp_earned(amount: int)
signal level_up(new_level: int)

func _ready():
  current_scrap = starting_scrap
  current_xp = 0
  current_level = 1
  scrap_changed.emit(current_scrap)
  xp_changed.emit(current_xp)
  GameManager.game_state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
  if new_state == GameManager.GameState.MAIN_MENU:
    current_scrap = starting_scrap
    current_xp = 0
    current_level = 1
    scrap_changed.emit(current_scrap)
    xp_changed.emit(current_xp)

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