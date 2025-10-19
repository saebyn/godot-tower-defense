extends Control
class_name CurrencyDisplay

## UI component to display the player's current resources (scrap and XP)

@onready var xp_label: Label = $XPLabel
@onready var scrap_label: Label = $ScrapLabel
@onready var level_label: Label = $LevelLabel

func _ready():
  # Connect to the currency manager signals
  if CurrencyManager:
    CurrencyManager.scrap_changed.connect(_on_scrap_changed)
    CurrencyManager.scrap_earned.connect(_on_scrap_earned)
    CurrencyManager.xp_changed.connect(_on_xp_changed)
    CurrencyManager.xp_earned.connect(_on_xp_earned)
    CurrencyManager.level_up.connect(_on_level_up)
    # Initialize the display with current resources
    _update_display()
  else:
    push_error("CurrencyManager not found! Make sure it's loaded as an autoload.")


func _update_display():
  var scrap = CurrencyManager.get_scrap()
  var xp = CurrencyManager.get_xp()
  var level = CurrencyManager.get_level()
  scrap_label.text = "Scrap: %d" % scrap
  xp_label.text = "XP: %d" % xp
  level_label.text = "Level: %d" % level


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

func _on_level_up(_new_level: int):
  _update_display()
  # Could add level-up animation or sound effect here