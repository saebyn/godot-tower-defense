extends Node3D

var health: Health

func _ready():
  # Find Health component via metadata
  if has_meta("health_component"):
    health = get_meta("health_component")
  
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

func _on_died(damage_source: String = "unknown") -> void:
  Logger.info("Target", "Target has died. Source: %s" % damage_source)
  var parent := get_parent()
  if parent and parent.has_method("on_target_died"):
    parent.on_target_died(self, damage_source)
  queue_free() # Remove the target from the scene when it dies.


func _on_health_damaged(amount: int, hitpoints: int, damage_source: String = "unknown") -> void:
  Logger.debug("Target.Combat", "Target took %d damage from %s. Remaining HP: %d" % [amount, damage_source, hitpoints])
