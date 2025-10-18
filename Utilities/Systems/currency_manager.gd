extends Node

## Manages the player's resource system (scrap and XP)
## Handles earning and spending scrap, and tracking experience points throughout the game

@export var starting_scrap: int = 100 # TODO change back to 0 before release
var current_scrap: int = 0
var current_xp: int = 0

signal scrap_changed(new_amount: int)
signal scrap_earned(amount: int)
signal xp_changed(new_amount: int)
signal xp_earned(amount: int)

func _ready():
  current_scrap = starting_scrap
  current_xp = 0
  scrap_changed.emit(current_scrap)
  xp_changed.emit(current_xp)
  GameManager.game_state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
  if new_state == GameManager.GameState.MAIN_MENU:
    current_scrap = starting_scrap
    current_xp = 0
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

## Set scrap to a specific amount (for testing/debugging)
func set_scrap(amount: int) -> void:
  current_scrap = max(0, amount)
  scrap_changed.emit(current_scrap)

## Set XP to a specific amount (for testing/debugging)
func set_xp(amount: int) -> void:
  current_xp = max(0, amount)
  xp_changed.emit(current_xp)

## Backward compatibility methods (redirect to scrap)
func earn_currency(amount: int) -> void:
  earn_scrap(amount)

func spend_currency(amount: int) -> bool:
  return spend_scrap(amount)

func get_currency() -> int:
  return get_scrap()

func set_currency(amount: int) -> void:
  set_scrap(amount)