extends Node3D

@onready var health: Health = $Health

func _on_died():
  Logger.info("Target", "Target has died.")
  queue_free() # Remove the target from the scene when it dies.


func _on_health_damaged(amount: int, hitpoints: int) -> void:
  Logger.debug("Target.Combat", "Target took %d damage. Remaining HP: %d" % [amount, hitpoints])
