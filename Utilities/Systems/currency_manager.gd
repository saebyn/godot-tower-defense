extends Node

## Manages the player's currency system
## Handles earning and spending currency throughout the game

@export var starting_currency: int = 0
var current_currency: int = 0

signal currency_changed(new_amount: int)
signal currency_earned(amount: int)

func _ready():
  current_currency = starting_currency
  currency_changed.emit(current_currency)

## Add currency to the player's total
func earn_currency(amount: int) -> void:
  if amount <= 0:
    return
  
  current_currency += amount
  currency_earned.emit(amount)
  currency_changed.emit(current_currency)
  Logger.info("Economy", "Earned %d currency. Total: %d" % [amount, current_currency])

## Spend currency if player has enough
func spend_currency(amount: int) -> bool:
  if amount <= 0:
    return false
  
  if current_currency >= amount:
    current_currency -= amount
    currency_changed.emit(current_currency)
    Logger.info("Economy", "Spent %d currency. Remaining: %d" % [amount, current_currency])
    return true
  else:
    Logger.warn("Economy", "Not enough currency. Need %d but only have %d" % [amount, current_currency])
    return false

## Get current currency amount
func get_currency() -> int:
  return current_currency

## Set currency to a specific amount (for testing/debugging)
func set_currency(amount: int) -> void:
  current_currency = max(0, amount)
  currency_changed.emit(current_currency)