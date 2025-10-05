extends Node3D
class_name PlaceableObstacle

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var health: Health

var obstacle_type: ObstacleTypeResource
var navigation_obstacle: NavigationObstacle3D

func _ready():
  # Find Health component via metadata
  if has_meta("health_component"):
    health = get_meta("health_component")
  
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

func _on_died():
  Logger.info("Obstacle", "Obstacle destroyed")
  queue_free()

func _on_health_damaged(amount: int, hitpoints: int, _source: String) -> void:
  Logger.debug("Obstacle.Combat", "Obstacle took %d damage. Remaining HP: %d" % [amount, hitpoints])

func place(navigation_region: NavigationRegion3D) -> void:
    Logger.info("Obstacle", "place() called. obstacle_type: %s" % ("null" if not obstacle_type else obstacle_type.name))
    if not is_inside_tree():
        Logger.error("Obstacle", "PlaceableObstacle must be added to the scene tree before placing.")
        return

    Logger.info("Obstacle", "Placing obstacle at: %s" % global_position)
    # Here you would implement the logic to finalize the placement of the obstacle
    var obstacle := NavigationObstacle3D.new()

    obstacle.affect_navigation_mesh = true
    obstacle.global_transform = global_transform

    # set the vertices based on the mesh size
    var aabb = mesh_instance.get_aabb()
    var size = aabb.size / 2.0
    obstacle.vertices = PackedVector3Array([
        Vector3(-size.x, 0, -size.z),
        Vector3(size.x, 0, -size.z),
        Vector3(size.x, 0, size.z),
        Vector3(-size.x, 0, size.z)
    ])

    navigation_region.add_child(obstacle)
    navigation_obstacle = obstacle

## Remove this obstacle and return currency based on remaining health
func remove() -> int:
  Logger.info("Obstacle", "Attempting to remove obstacle. obstacle_type: %s" % ("null" if not obstacle_type else obstacle_type.name))
  
  # If obstacle_type is null, try to find it by matching the scene
  if not obstacle_type and ObstacleRegistry:
    Logger.info("Obstacle", "obstacle_type is null, attempting to find it in registry...")
    var scene_path = scene_file_path
    for obstacle_resource in ObstacleRegistry.available_obstacle_types:
      if obstacle_resource.scene and obstacle_resource.scene.resource_path == scene_path:
        obstacle_type = obstacle_resource
        Logger.info("Obstacle", "Found matching obstacle_type: %s" % obstacle_type.name)
        break
  
  if not obstacle_type:
    Logger.warn("Obstacle", "Cannot remove obstacle: No obstacle type data")
    return 0
  
  # Calculate refund based on remaining health percentage
  var health_percentage = 1.0
  if health:
    health_percentage = float(health.hitpoints) / float(health.max_hitpoints)
  
  # Refund is based on remaining health (damaged obstacles give less refund)
  var refund_amount = int(obstacle_type.cost * health_percentage)
  
  Logger.info("Obstacle", "Removing obstacle. Health: %d%%, Refund: %d/%d" % [
    health_percentage * 100, refund_amount, obstacle_type.cost
  ])
  
  # Clean up navigation obstacle
  if navigation_obstacle and is_instance_valid(navigation_obstacle):
    navigation_obstacle.queue_free()
  
  # Return currency
  CurrencyManager.earn_currency(refund_amount)
  
  # Remove from scene
  queue_free()
  
  return refund_amount