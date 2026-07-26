extends StaticBody3D
class_name Entity_Building

## Group name for all buildings
const BUILDING_GROUP: String = "buildings"

var health: Component_Health

func _ready():
  # Find Health component via metadata
  if has_meta("health_component"):
    health = get_meta("health_component")
  
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)


func _on_died(damage_source: String = "unknown") -> void:
  MyLogger.info("Building", "Building destroyed by: %s" % damage_source)
  queue_free()

func _on_health_damaged(amount: int, hitpoints: int, _source: String) -> void:
  MyLogger.debug("Building", "Building took %d damage. Remaining HP: %d" % [amount, hitpoints])


