extends Control

func _ready() -> void:
  _update_visibility(SettingsManager.debug_mode)
  SettingsManager.debug_mode_changed.connect(_update_visibility)

func _update_visibility(enabled: bool) -> void:
  visible = enabled and OS.has_feature("debug")

func _on_free_scrap_pressed() -> void:
  CurrencyManager.earn_scrap(9999)

func _on_unlock_all_tech_pressed() -> void:
  for tech_id in TechTreeManager.tech_nodes:
    if not TechTreeManager.is_tech_unlocked(tech_id):
      TechTreeManager.unlock_tech(tech_id)