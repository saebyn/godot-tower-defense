extends Node3D

@export var skin_material: StandardMaterial3D

var health: Component_Health
var panic_behavior: Component_PanicBehavior

@onready var mesh: MeshInstance3D = $characterMedium

func _ready():
  # Find Health component via metadata
  if has_meta("health_component"):
    health = get_meta("health_component")
  
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)
  
  # Add panic behavior component
  panic_behavior = Component_PanicBehavior.new()
  panic_behavior.name = "PanicBehavior"
  panic_behavior.animation_player_path = NodePath("AnimationPlayer")
  add_child(panic_behavior)

  # Add texture to mesh
  if skin_material and mesh:
    mesh.set_surface_override_material(0, skin_material)


func _on_died(damage_source: String = "unknown") -> void:
  Logger.info("Target", "Target has died. Source: %s" % damage_source)
  var parent := get_parent()
  if parent and parent.has_method("on_target_died"):
    parent.on_target_died(self, damage_source)
  queue_free() # Remove the target from the scene when it dies.


func _on_health_damaged(amount: int, hitpoints: int, damage_source: String = "unknown") -> void:
  Logger.debug("Target.Combat", "Target took %d damage from %s. Remaining HP: %d" % [amount, damage_source, hitpoints])
