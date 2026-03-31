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
    if enemy.has_meta("health_component"):
      if enemy.get_meta("health_component") is Component_Health:
        var health_component: Component_Health = enemy.get_meta("health_component")
        var max_damage := health_component.max_damage_per_hit
        if max_damage > 0.0:
          var iterations := 0
          var max_iterations := 1024
          while iterations < max_iterations \
              and not health_component.dead \
              and is_instance_valid(enemy):
            health_component.take_damage(max_damage, "debug")
            iterations += 1
