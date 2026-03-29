extends Control

func _ready() -> void:
  visible = ProjectSettings.get_setting("zom_nom_defense/debug/show_debug_panel", false) \
    and OS.has_feature("debug")

func _on_free_scrap_pressed() -> void:
  CurrencyManager.earn_scrap(9999)

func _on_unlock_all_tech_pressed() -> void:
  var tech_ids := TechTreeManager.tech_nodes.keys()
  tech_ids.sort()
  for tech_id in tech_ids:
    var tech := TechTreeManager.get_tech_node(tech_id)
    if tech.mutually_exclusive_with.is_empty() and TechTreeManager.can_unlock_tech(tech_id):
      TechTreeManager.unlock_tech(tech_id, true)

func _on_kill_all_enemies_pressed() -> void:
  var enemies := get_tree().get_nodes_in_group("enemies")
  for enemy in enemies:
    if not is_instance_valid(enemy):
      continue
    if "health" in enemy and enemy.health and is_instance_valid(enemy.health):
      enemy.health.take_damage(INF, "debug")
    else:
      enemy.queue_free()