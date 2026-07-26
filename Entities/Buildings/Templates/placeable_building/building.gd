## Building.gd
## Base class for placeable buildings in the game world
## Handles placement preview, health management, and removal/refund logic
##
## When instantiated, this entity will:
##  - Enter placement mode, showing a preview of the building
##  - Disable collisions and health component during placement
##  - Upon placement, re-enable collisions and health component
##  - Create a NavigationObstacle3D to affect navigation mesh
##  - Handle removal logic, refunding currency based on remaining health

extends Entity_Building
class_name Entity_PlaceableBuilding

## Group to indicate the building should affect navigation
## We add buildings to this group upon placement for navigation mesh updates.
@export var navigation_obstacle_group: String = "navigation_mesh_source_group"

@export var mesh_instances: Array[MeshInstance3D] = []:
  set(values):
    mesh_instances = values
    update_configuration_warnings()

var is_preview: bool = false
var building_type: Resource_BuildingType
var navigation_obstacle: NavigationObstacle3D
var placement_preview_node: Node3D
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _saved_collision_layers: int
var _saved_area_monitoring: Dictionary = {}

func _ready():
  super._ready()

  _enter_placement_mode()

## Create a visual preview of the building for placement mode
func _enter_placement_mode() -> void:
  if not mesh_instances or mesh_instances.is_empty():
    MyLogger.error("Building", "Could not find MeshInstance3D in building scene")
    return
  
  # Create our own mesh instances based on the temporary building's meshes
  placement_preview_node = Node3D.new()
  add_child(placement_preview_node)
  
  for mesh_instance in mesh_instances:
    if not mesh_instance or not mesh_instance.mesh:
      MyLogger.warn("Building", "Skipping invalid MeshInstance3D in placement preview")
      continue
    mesh_instance.hide()
    var preview_mesh = MeshInstance3D.new()
    preview_mesh.mesh = mesh_instance.mesh
    # Use global_transform to capture the mesh's full transformation including parent node scales/rotations
    preview_mesh.global_transform = mesh_instance.global_transform

    placement_preview_node.add_child(preview_mesh)
  _saved_collision_layers = collision_layer
  collision_layer = 0 # Disable collisions in preview mode

  # Disable Area3D monitoring so damage/effect components don't interact
  # with enemies while the building is only a placement preview.
  _saved_area_monitoring.clear()
  for area in find_children("*", "Area3D", true, false):
    _saved_area_monitoring[area] = area.monitoring
    area.monitoring = false

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

  # Restore Area3D monitoring to its state before preview mode.
  for area in _saved_area_monitoring:
    if is_instance_valid(area) and area.is_inside_tree():
      area.monitoring = _saved_area_monitoring[area]
  _saved_area_monitoring.clear()

  if health:
    health.disabled = false

## Remove this building and return currency based on remaining health
func remove() -> int:
  MyLogger.info("Building", "Attempting to remove building. building_type: %s" % ("null" if not building_type else building_type.name))
  
  # If building_type is null, try to find it by matching the scene
  if not building_type and BuildingRegistry:
    MyLogger.info("Building", "building_type is null, attempting to find it in registry...")
    var scene_path = scene_file_path
    for resource in BuildingRegistry.available_building_types:
      if resource.scene and resource.scene.resource_path == scene_path:
        building_type = resource
        MyLogger.info("Building", "Found matching building_type: %s" % building_type.name)
        break
  
  if not building_type:
    MyLogger.warn("Building", "Cannot remove building: No building type data")
    return 0
  
  # Calculate refund based on remaining health percentage
  var health_percentage = 1.0
  if health:
    health_percentage = float(health.hitpoints) / float(health.max_hitpoints)
  
  # Refund is based on remaining health (damaged buildings give less refund)
  var refund_amount = int(building_type.cost * health_percentage)
  
  MyLogger.info("Building", "Removing building. Health: %d%%, Refund: %d/%d" % [
    health_percentage * 100, refund_amount, building_type.cost
  ])
  
  # Clean up navigation obstacle
  if navigation_obstacle and is_instance_valid(navigation_obstacle):
    navigation_obstacle.queue_free()
  
  # Return currency
  CurrencyManager.earn_scrap(refund_amount)

  # Play removal sound effect
  AudioManager.play_sound(
    audio_player,
    Resource_SoundEffect.SoundEffect.BUILDING_REMOVED,
  )

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
    MyLogger.warn("Building", "set_preview_material() called but not in placement mode.")
    return

  for mesh_instance in placement_preview_node.get_children():
    if mesh_instance is MeshInstance3D and mesh_instance.mesh != null:
      var surface_count = mesh_instance.mesh.get_surface_count()
      for i in range(surface_count):
        mesh_instance.set_surface_override_material(i, material)


## Finalizes placement of the building in the game world.
##
## This method performs several critical operations:
## 1. **Reparents the building**: Moves this node from its placement utility parent to the main scene (grandparent node).
##    - **Requires**: The building must have both a parent and grandparent node in the scene tree.
##    - **Errors**: If the scene tree structure is invalid, placement will fail and log an error.
## 2. **Exits placement mode**: Enables collisions and the health component, and hides the placement preview.
## 3. **Creates a NavigationObstacle3D**: Instantiates and configures a NavigationObstacle3D to affect the navigation mesh.
##    - The obstacle's shape is determined by the combined AABB of its mesh instances.
##    - The NavigationObstacle3D is added as a child of the provided `navigation_region`.
## 4. **Adds to navigation group**: Adds this building to the group specified by `navigation_obstacle_group` for navigation mesh updates.
##
## Call this method after the building has been positioned and is ready to be placed in the world.
##
## @param navigation_region The NavigationRegion3D to which the navigation obstacle will be added.
func place(navigation_region: NavigationRegion3D) -> void:
  MyLogger.info("Building", "place() called. building_type: %s" % ("null" if not building_type else building_type.name))
  if not is_inside_tree():
    MyLogger.error("Building", "PlaceableBuilding must be added to the scene tree before placing.")
    return

  # Reparent to the right place in the scene tree
  var parent_node = get_parent()
  var grandparent_node = parent_node.get_parent() if parent_node else null
  if not grandparent_node:
    MyLogger.error("Building", "Failed to reparent building: parent or grandparent node missing. Scene tree structure may be invalid.")
    return

  is_preview = false
  parent_node.remove_child(self )
  grandparent_node.add_child(self )

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

  # Ensure the building is in the correct group for navigation
  add_to_group(navigation_obstacle_group)


## Dictionary to track active buffs on this building.
## Key: source_id (int) of the buff building applying the buff
## Value: Dictionary with keys "timeout_timer"
var buffs: Dictionary = {}

var _original_values: Dictionary[Entity_BuffBuilding.BuffType, float] = {}

func _stack_buffs(buff_type: Entity_BuffBuilding.BuffType, current_value: float, amounts: Array[float]) -> float:
  if not _original_values.has(buff_type):
    _original_values[buff_type] = current_value

  var result = _original_values[buff_type]
  for buff in amounts:
    result *= (1.0 + buff)
  return result

## Internal handler to apply the buff effects to this building.
## For this base class, we do not implement any specific buff logic.
## Subclasses should override this method to handle specific buff types.
func _handle_buffs(_buff_type: Entity_BuffBuilding.BuffType, _buff_amounts: Array[float]) -> void:
  pass


## Receive a buff from a buff building.
##
## This method is called by a buff building to apply a buff to this building.
## We should keep track of buffs applied so they can be removed after timeout, and
## so that they are not stacked multiple times from the same source.
##
## @param buff_type The type of buff being applied.
## @param buff_amount The amount of the buff.
## @param source_id The instance ID of the buff building applying the buff.
## @param timeout The duration the buff should last (in seconds).
func receive_buff(buff_type: Entity_BuffBuilding.BuffType, buff_amount: float, source_id: int, timeout: float) -> void:
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
  
func _get_buffs_of_type(buff_type: Entity_BuffBuilding.BuffType) -> Array[float]:
  var result: Array[float] = []
  for buff in buffs.values():
    if buff.buff_type == buff_type:
      result.append(buff.buff_amount)
  return result

## Get display information for the tooltip
## Subclasses should override this to add their specific stats
func get_tooltip_info() -> Dictionary:
  var info = {
    "name": building_type.name if building_type else "Unknown",
    "base_stats": {},
    "current_stats": {},
    "active_buffs": []
  }
  
  # Add health if present
  if health:
    var base_health = health.max_hitpoints
    info.base_stats["health"] = base_health
    info.current_stats["health"] = health.hitpoints
  
  return info

## Get list of active buff sources with details
func get_active_buff_sources() -> Array[Dictionary]:
  var sources: Array[Dictionary] = []
  for source_id in buffs.keys():
    var buff = buffs[source_id]
    var source_node = instance_from_id(source_id)
    if source_node and is_instance_valid(source_node):
      var source_name = "Support"
      if source_node is Entity_PlaceableBuilding and source_node.building_type:
        source_name = source_node.building_type.name
      sources.append({
        "name": source_name,
        "type": buff.buff_type,
        "amount": buff.buff_amount
      })
  return sources
