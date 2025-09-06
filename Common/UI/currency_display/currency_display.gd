extends Control
class_name CurrencyDisplay

## UI component to display the player's current currency

@onready var currency_label: Label = $CurrencyLabel

func _ready():
  # Connect to the currency manager signals
  if CurrencyManager:
    CurrencyManager.currency_changed.connect(_on_currency_changed)
    CurrencyManager.currency_earned.connect(_on_currency_earned)
    # Initialize the display with current currency
    _on_currency_changed(CurrencyManager.get_currency())
  else:
    push_error("CurrencyManager not found! Make sure it's loaded as an autoload.")

func _on_currency_changed(new_amount: int):
  if currency_label:
    currency_label.text = "Currency: " + str(new_amount)

func _on_currency_earned(amount: int):
  # Could add visual effects here like floating text or color flash
  # For now, just update the display (handled by currency_changed signal)
  pass