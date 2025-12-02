## Obstacle.gd
## Base class for placeable obstacles in the game world
## Handles placement preview, health management, and removal/refund logic
##
## When instantiated, this entity will:
##  - Enter placement mode, showing a preview of the obstacle
##  - Disable collisions and health component during placement
##  - Upon placement, re-enable collisions and health component
##  - Create a NavigationObstacle3D to affect navigation mesh
##  - Handle removal logic, refunding currency based on remaining health

extends StaticBody3D
class_name Entity_PlaceableObstacle

const OBSTACLE_GROUP: String = "obstacles"

@export var navigation_obstacle_group: String = "navigation_mesh_source_group" ## Group to indicate the obstacle should affect navigation

@export var mesh_instances: Array[MeshInstance3D] = []:
  set(values):
    mesh_instances = values
    update_configuration_warnings()

var health: Component_Health
var obstacle_type: Resource_ObstacleType
var navigation_obstacle: NavigationObstacle3D
var placement_preview_node: Node3D

var _saved_collision_layers: int

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

  if health:
    health.disabled = true

## Clean up after placement mode:
##  - Removes the placement preview node
##  - Restores original collision layers
##  - Re-enables the health component
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

## Sets a material override for all meshes in the placement preview node.
## Used by the placement system to visually indicate valid or invalid placement (e.g., green/red highlight).
## 
## @param material The Material to apply as an override to all preview mesh surfaces.
func set_preview_material(material: Material) -> void:
  if not placement_preview_node:
    MyLogger.warn("Obstacle", "set_preview_material() called but not in placement mode.")
    return

  for mesh_instance in placement_preview_node.get_children():
    if mesh_instance is MeshInstance3D and mesh_instance.mesh != null:
      var surface_count = mesh_instance.mesh.get_surface_count()
      for i in range(surface_count):
        mesh_instance.set_surface_override_material(i, material)


## Finalizes placement of the obstacle in the game world.
##
## This method performs several critical operations:
## 1. **Reparents the obstacle**: Moves this node from its placement utility parent to the main scene (grandparent node).
##    - **Requires**: The obstacle must have both a parent and grandparent node in the scene tree.
##    - **Errors**: If the scene tree structure is invalid, placement will fail and log an error.
## 2. **Exits placement mode**: Enables collisions and the health component, and hides the placement preview.
## 3. **Creates a NavigationObstacle3D**: Instantiates and configures a NavigationObstacle3D to affect the navigation mesh.
##    - The obstacle's shape is determined by the combined AABB of its mesh instances.
##    - The NavigationObstacle3D is added as a child of the provided `navigation_region`.
## 4. **Adds to navigation group**: Adds this obstacle to the group specified by `navigation_obstacle_group` for navigation mesh updates.
##
## Call this method after the obstacle has been positioned and is ready to be placed in the world.
##
## @param navigation_region The NavigationRegion3D to which the navigation obstacle will be added.
func place(navigation_region: NavigationRegion3D) -> void:
  MyLogger.info("Obstacle", "place() called. obstacle_type: %s" % ("null" if not obstacle_type else obstacle_type.name))
  if not is_inside_tree():
    MyLogger.error("Obstacle", "PlaceableObstacle must be added to the scene tree before placing.")
    return

  # Reparent to the right place in the scene tree
  var parent_node = get_parent()
  var grandparent_node = parent_node.get_parent() if parent_node else null
  if not grandparent_node:
    MyLogger.error("Obstacle", "Failed to reparent obstacle: parent or grandparent node missing. Scene tree structure may be invalid.")
    return

  parent_node.remove_child(self)
  grandparent_node.add_child(self)

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
  add_to_group(navigation_obstacle_group)


## Dictionary to track active buffs on this obstacle.
## Key: source_id (int) of the buff obstacle applying the buff
## Value: Dictionary with keys "timeout_timer"
var buffs: Dictionary = {}

## Internal handler to apply the buff effects to this obstacle.
## For this base class, we do not implement any specific buff logic.
## Subclasses should override this method to handle specific buff types.
func _handle_buffs(buff_type: Entity_BuffObstacle.BuffType, buff_amounts: Array[float]) -> void:
  pass


## Receive a buff from a buff obstacle.
##
## This method is called by a buff obstacle to apply a buff to this obstacle.
## We should keep track of buffs applied so they can be removed after timeout, and
## so that they are not stacked multiple times from the same source.
##
## @param buff_type The type of buff being applied.
## @param buff_amount The amount of the buff.
## @param source_id The instance ID of the buff obstacle applying the buff.
## @param timeout The duration the buff should last (in seconds).
func receive_buff(buff_type: Entity_BuffObstacle.BuffType, buff_amount: float, source_id: int, timeout: float) -> void:
  # If we already have a buff from this source, reset the timer
  # This assumes that the buff effects from `source_id` are always the same
  if buffs.has(source_id):
    var existing_buff = buffs[source_id]
    if existing_buff.timeout_timer:
      existing_buff.timeout_timer.stop()
      existing_buff.timeout_timer.wait_time = timeout
      existing_buff.timeout_timer.start()
    return

  # Set up a timer to remove the buff after timeout
  var timeout_timer = Timer.new()

  # Store the buff info
  buffs[source_id] = {
    "timeout_timer": timeout_timer,
    "buff_type": buff_type,
    "buff_amount": buff_amount
  }

  # Apply the buff effects
  _handle_buffs(buff_type, _get_buffs_of_type(buff_type))
  
  timeout_timer.wait_time = timeout
  timeout_timer.one_shot = true
  timeout_timer.autostart = true
  timeout_timer.timeout.connect(func():
    buffs.erase(source_id)
    _handle_buffs(buff_type, _get_buffs_of_type(buff_type))
    timeout_timer.queue_free()
  )
  add_child(timeout_timer)
  
func _get_buffs_of_type(buff_type: Entity_BuffObstacle.BuffType) -> Array[float]:
  var result: Array[float] = []
  for buff in buffs.values():
    if buff.buff_type == buff_type:
      result.append(buff.buff_amount)
  return result