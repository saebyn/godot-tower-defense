extends Node3D

@export var skin_material: StandardMaterial3D
@export var hitpoints_override: int = -1 ## If set to a positive value, overrides the default health component's hitpoints
@export_range(0.5, 2.0) var voice_pitch: float = 1.0 ## Pitch override for this survivor's voice sounds

var health: Component_Health
var survivor_name: String = "" ## Name assigned to this survivor from the name pool

@onready var mesh: MeshInstance3D = $characterMedium
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready():
  # Assign a unique name from the pool
  survivor_name = SurvivorNameManager.assign_name()
  if survivor_name.is_empty():
    MyLogger.warn("Target", "Could not assign a name - pool may be exhausted")
  else:
    MyLogger.info("Target", "Survivor '%s' created" % survivor_name)

  # Find Health component via metadata
  if has_meta("health_component"):
    health = get_meta("health_component")
  
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

    # Override health if specified
    if hitpoints_override > 0:
      health.hitpoints = hitpoints_override

  # Add texture to mesh
  if skin_material and mesh:
    mesh.set_surface_override_material(0, skin_material)

  # Refresh health display now that survivor_name is set.
  # health._ready() runs before target._ready() (children initialise first),
  # so the name label would otherwise remain blank until the first hover event.
  if health:
    health.refresh_display()


func _on_died(damage_source: String = "unknown") -> void:
  MyLogger.info("Target", "Survivor '%s' has died. Source: %s" % [survivor_name, damage_source])
  # Return the name to the pool so it can be reused
  SurvivorNameManager.release_name(survivor_name)
  var parent := get_parent()
  if parent and parent.has_method("on_target_died"):
    parent.on_target_died(self, damage_source)
  queue_free() # Remove the target from the scene when it dies.


func _on_health_damaged(amount: int, hitpoints: int, damage_source: String = "unknown") -> void:
  MyLogger.debug("Target.Combat", "Survivor '%s' took %d damage from %s. Remaining HP: %d" % [survivor_name, amount, damage_source, hitpoints])
