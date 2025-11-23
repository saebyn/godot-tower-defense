extends Control

func _ready() -> void:
  if OS.has_feature("debug"):
    visible = true
  else:
    visible = false

func _on_free_scrap_pressed() -> void:
  CurrencyManager.earn_scrap(9999)