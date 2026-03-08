extends Control

func _ready() -> void:
  _update_visibility(SettingsManager.debug_mode)
  SettingsManager.debug_mode_changed.connect(_update_visibility)

func _update_visibility(enabled: bool) -> void:
  visible = enabled

func _on_free_scrap_pressed() -> void:
  CurrencyManager.earn_scrap(9999)