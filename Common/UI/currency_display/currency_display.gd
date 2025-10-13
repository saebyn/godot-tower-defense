extends Control
class_name CurrencyDisplay

## UI component to display the player's current resources (scrap and XP)

@onready var currency_label: Label = $CurrencyLabel

func _ready():
  # Connect to the currency manager signals
  if CurrencyManager:
    CurrencyManager.scrap_changed.connect(_on_scrap_changed)
    CurrencyManager.scrap_earned.connect(_on_scrap_earned)
    CurrencyManager.xp_changed.connect(_on_xp_changed)
    CurrencyManager.xp_earned.connect(_on_xp_earned)
    # Initialize the display with current resources
    _update_display()
  else:
    push_error("CurrencyManager not found! Make sure it's loaded as an autoload.")

func _update_display():
  if currency_label:
    var scrap = CurrencyManager.get_scrap()
    var xp = CurrencyManager.get_xp()
    currency_label.text = "Scrap: %d | XP: %d" % [scrap, xp]

func _on_scrap_changed(_new_amount: int):
  _update_display()

func _on_scrap_earned(_amount: int):
  # Could add visual effects here like floating text or color flash
  pass

func _on_xp_changed(_new_amount: int):
  _update_display()

func _on_xp_earned(_amount: int):
  # Could add visual effects here like floating text or color flash
  pass