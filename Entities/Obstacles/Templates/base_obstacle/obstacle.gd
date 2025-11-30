@tool
extends StaticBody3D
class_name Entity_PlaceableObstacle

@export var obstacle_group: String = "navigation_mesh_source_group" ## Group to indicate the obstacle should affect navigation

@export var mesh_instances: Array[MeshInstance3D] = []:
  set(values):
    mesh_instances = values
    update_configuration_warnings()

var health: Component_Health
var obstacle_type: Resource_ObstacleType
var navigation_obstacle: NavigationObstacle3D
var placement_preview_node: Node3D

var _saved_collision_layers: int

func _get_configuration_warnings():
  var warnings = []
  if mesh_instances.size() == 0:
    warnings.append("MeshInstance3D is not assigned.")
  return warnings

func _ready():
  # Find Health component via metadata
  if has_meta("health_component"):
    health = get_meta("health_component")
  
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

  _enter_placement_mode()

## Create a visual preview of the obstacle for placement mode
func _enter_placement_mode() -> void:
  if not mesh_instances or mesh_instances.is_empty():
    MyLogger.error("Obstacle", "Could not find MeshInstance3D in obstacle scene")
    return
  
  # Create our own mesh instances based on the temporary obstacle's meshes
  placement_preview_node = Node3D.new()
  for mesh_instance in mesh_instances:
    mesh_instance.hide()
    var preview_mesh = MeshInstance3D.new()
    preview_mesh.mesh = mesh_instance.mesh
    preview_mesh.transform = mesh_instance.transform
    preview_mesh.scale = mesh_instance.scale

    placement_preview_node.add_child(preview_mesh)
  
  add_child(placement_preview_node)
  _saved_collision_layers = collision_layer
  collision_layer = 0 # Disable collisions in preview mode
  MyLogger.debug("Obstacle", "Created preview for obstacle: %s" % obstacle_type)

  if health:
    health.disabled = true

func _exit_placement_mode() -> void:
  if placement_preview_node:
    placement_preview_node.queue_free()
    placement_preview_node = null
  
  for mesh_instance in mesh_instances:
    mesh_instance.show()

  collision_layer = _saved_collision_layers

  if health:
    health.disabled = false

func _on_died(damage_source: String = "unknown") -> void:
  MyLogger.info("Obstacle", "Obstacle destroyed by: %s" % damage_source)
  queue_free()

func _on_health_damaged(amount: int, hitpoints: int, _source: String) -> void:
  MyLogger.debug("Obstacle.Combat", "Obstacle took %d damage. Remaining HP: %d" % [amount, hitpoints])


## Remove this obstacle and return currency based on remaining health
func remove() -> int:
  MyLogger.info("Obstacle", "Attempting to remove obstacle. obstacle_type: %s" % ("null" if not obstacle_type else obstacle_type.name))
  
  # If obstacle_type is null, try to find it by matching the scene
  if not obstacle_type and ObstacleRegistry:
    MyLogger.info("Obstacle", "obstacle_type is null, attempting to find it in registry...")
    var scene_path = scene_file_path
    for obstacle_resource in ObstacleRegistry.available_obstacle_types:
      if obstacle_resource.scene and obstacle_resource.scene.resource_path == scene_path:
        obstacle_type = obstacle_resource
        MyLogger.info("Obstacle", "Found matching obstacle_type: %s" % obstacle_type.name)
        break
  
  if not obstacle_type:
    MyLogger.warn("Obstacle", "Cannot remove obstacle: No obstacle type data")
    return 0
  
  # Calculate refund based on remaining health percentage
  var health_percentage = 1.0
  if health:
    health_percentage = float(health.hitpoints) / float(health.max_hitpoints)
  
  # Refund is based on remaining health (damaged obstacles give less refund)
  var refund_amount = int(obstacle_type.cost * health_percentage)
  
  MyLogger.info("Obstacle", "Removing obstacle. Health: %d%%, Refund: %d/%d" % [
    health_percentage * 100, refund_amount, obstacle_type.cost
  ])
  
  # Clean up navigation obstacle
  if navigation_obstacle and is_instance_valid(navigation_obstacle):
    navigation_obstacle.queue_free()
  
  # Return currency
  CurrencyManager.earn_scrap(refund_amount)
  
  # Remove from scene
  queue_free()
  
  return refund_amount


func get_aabb() -> AABB:
  var combined_aabb = AABB()
  for mesh_instance in mesh_instances:
    combined_aabb = combined_aabb.merge(mesh_instance.get_aabb())
  return combined_aabb

func set_preview_material(material: Material) -> void:
  if not placement_preview_node:
    MyLogger.warn("Obstacle", "set_preview_material() called but not in placement mode.")
    return

  for mesh_instance in placement_preview_node.get_children():
    if mesh_instance is MeshInstance3D and mesh_instance.mesh != null:
      var surface_count = mesh_instance.mesh.get_surface_count()
      for i in range(surface_count):
        mesh_instance.set_surface_override_material(i, material)


func place(navigation_region: NavigationRegion3D) -> void:
  MyLogger.info("Obstacle", "place() called. obstacle_type: %s" % ("null" if not obstacle_type else obstacle_type.name))
  if not is_inside_tree():
    MyLogger.error("Obstacle", "PlaceableObstacle must be added to the scene tree before placing.")
    return

  # Reparent to the right place in the scene tree
  var parent_node = get_parent()
  parent_node.remove_child(self)
  parent_node.get_parent().add_child(self)

  _exit_placement_mode()

  # Create NavigationObstacle3D to affect navigation mesh
  var nav_obstacle := NavigationObstacle3D.new()

  nav_obstacle.affect_navigation_mesh = true
  nav_obstacle.global_transform = global_transform

  # set the vertices based on the mesh size
  var size: Vector3 = Vector3.ONE
  for mesh_instance in mesh_instances:
      var aabb = mesh_instance.get_aabb()
      size.x = max(size.x, aabb.size.x * 0.5)
      size.y = max(size.y, aabb.size.y * 0.5)
      size.z = max(size.z, aabb.size.z * 0.5)

  nav_obstacle.vertices.append_array([
    Vector3(-size.x, 0, -size.z),
    Vector3(size.x, 0, -size.z),
    Vector3(size.x, 0, size.z),
    Vector3(-size.x, 0, size.z)
  ])

  navigation_region.add_child(nav_obstacle)
  navigation_obstacle = nav_obstacle

  # Ensure the obstacle is in the correct group for navigation
  add_to_group(obstacle_group)
