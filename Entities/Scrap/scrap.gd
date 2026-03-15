class_name Entity_Scrap
extends Node3D

@export_group("Scrap Settings")
@export var scrap_reward: int = 10

var damage_numbers: Component_DamageNumbers


func _ready() -> void:
  if has_meta("damage_numbers_component"):
    damage_numbers = get_meta("damage_numbers_component")


func _on_health_died(_damage_source: String) -> void:
  queue_free()

func _on_health_damaged(_amount: int, _hitpoints: int, damage_source: String) -> void:
  # Only reward scrap if the damage source is a player attack. This prevents
  # rewarding scrap for environmental damage or other non-player sources.
  if damage_source != "player_attack":
    return

  CurrencyManager.earn_scrap(scrap_reward)
  if damage_numbers:
    damage_numbers.show_scrap(scrap_reward)
