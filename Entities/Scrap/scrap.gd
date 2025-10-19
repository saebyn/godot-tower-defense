class_name Scrap
extends Node3D

@export_group("Scrap Settings")
@export var scrap_reward: int = 10


func _on_health_died(_damage_source: String) -> void:
  queue_free()

func _on_health_damaged(_amount: int, _hitpoints: int, _damage_source: String) -> void:
  CurrencyManager.earn_scrap(scrap_reward)
