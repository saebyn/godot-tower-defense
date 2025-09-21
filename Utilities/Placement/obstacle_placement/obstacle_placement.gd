extends Node3D
class_name ObstaclePlacement

signal rebake_navigation_mesh

@export_group("Placement Settings")
@export var placement_clearance: float = 3.0 # Minimum distance from other obstacles
@export var border_margin: float = 2.0 # Minimum distance from navigation region border

@export_group("Raycast Settings")
@export var raycast_length: float = 1000.0 # Length of the raycast for obstacle placement
@export var raycast_start: Vector3 = Vector3(0, 10, 0) # Start position offset for the raycast
@export var raycast_down: Vector3 = Vector3(0, -20, 0) # Direction and length to cast downwards

@export_group("Node References")
@export var navigation_region: NavigationRegion3D
@export var camera: Camera3D

@onready var raycast: RayCast3D = $RayCast3D
@onready var obstacle_detection_raycast: RayCast3D = RayCast3D.new()

var busy: bool:
  get:
    return _placeable_obstacle != null

var _place_obstacle_type: ObstacleTypeResource = null
var _placeable_obstacle: PlaceableObstacle = null
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D
var _original_material: Material

func _ready():
  # Set up materials for visual feedback
  _valid_material = StandardMaterial3D.new()
  _valid_material.albedo_color = Color.GREEN
  _valid_material.flags_transparent = true
  _valid_material.albedo_color.a = 0.8
  
  _invalid_material = StandardMaterial3D.new()
  _invalid_material.albedo_color = Color.RED
  _invalid_material.flags_transparent = true
  _invalid_material.albedo_color.a = 0.8
  
  # Set up obstacle detection raycast
  add_child(obstacle_detection_raycast)
  obstacle_detection_raycast.enabled = false
  obstacle_detection_raycast.collision_mask = 2 # Check for obstacles (layer 2)

func _process(_delta: float) -> void:
  if _placeable_obstacle:
    if Input.is_action_just_pressed("place_cancel"):
      # Handle obstacle placement cancellation
      _cancel_obstacle_placement()
    elif Input.is_action_just_pressed("place_obstacle"):
      # Handle obstacle placement confirmation
      _place_obstacle()
    elif Input.is_action_just_pressed("place_rotate_left"):
      # Rotate the obstacle left
      _placeable_obstacle.rotate_y(-PI / 2) # Rotate left by 90 degrees
    elif Input.is_action_just_pressed("place_rotate_right"):
      # Rotate the obstacle right
      _placeable_obstacle.rotate_y(PI / 2) # Rotate right by 90 degrees


func _physics_process(_delta: float) -> void:
  if _placeable_obstacle and raycast.is_colliding():
    var collision_point = raycast.get_collision_point()
    _placeable_obstacle.global_position = collision_point
    
    # Update visual feedback based on placement validity
    _update_visual_feedback(collision_point)

func _input(event: InputEvent) -> void:
  if event is InputEventMouseMotion and busy:
    _project_placed_obstacle(event.position)


func _validate_placement(target_position: Vector3) -> PlacementResult:
  if not _placeable_obstacle:
    return PlacementResult.new(false, PlacementResult.ValidationError.NO_PLACEABLE_OBSTACLE, "No obstacle selected for placement")
  
  if not _is_within_navigation_region(target_position):
    return PlacementResult.new(false, PlacementResult.ValidationError.OUTSIDE_NAVIGATION_REGION, "Position outside navigation bounds")
  
  if _has_obstacle_collision(target_position):
    return PlacementResult.new(false, PlacementResult.ValidationError.OBSTACLE_COLLISION, "Collision with existing obstacle")
  
  if not _has_terrain_support(target_position):
    return PlacementResult.new(false, PlacementResult.ValidationError.NO_TERRAIN_SUPPORT, "No valid terrain support")
  
  if not _has_sufficient_clearance(target_position):
    return PlacementResult.new(false, PlacementResult.ValidationError.INSUFFICIENT_CLEARANCE, "Insufficient clearance from other obstacles")

  if CurrencyManager.get_currency() < _place_obstacle_type.cost:
    return PlacementResult.new(false, PlacementResult.ValidationError.INSUFFICIENT_FUNDS, "Insufficient funds to place obstacle")
  
  return PlacementResult.new(true)

func _is_placement_valid(target_position: Vector3) -> bool:
  var result = _validate_placement(target_position)
  # TODO enhance feedback to user
  if not result.is_valid:
    Logger.debug("Placement", "Invalid placement: %s" % result.error_message)
  return result.is_valid

func _is_within_navigation_region(target_position: Vector3) -> bool:
  if not navigation_region or not navigation_region.navigation_mesh:
    return false
  
  # Check if position is within the navigation region bounds
  var nav_mesh = navigation_region.navigation_mesh
  var nav_region_transform = navigation_region.global_transform
  
  # Get the navigation mesh AABB
  var vertices = nav_mesh.vertices
  if vertices.size() == 0:
    return false
  
  var min_bounds = vertices[0]
  var max_bounds = vertices[0]
  
  for vertex in vertices:
    min_bounds.x = min(min_bounds.x, vertex.x)
    min_bounds.z = min(min_bounds.z, vertex.z)
    max_bounds.x = max(max_bounds.x, vertex.x)
    max_bounds.z = max(max_bounds.z, vertex.z)

  # Transform position to navigation region local space
  var local_pos = nav_region_transform.affine_inverse() * target_position

  # Check if within bounds (with some margin)
  return (local_pos.x >= min_bounds.x + border_margin and
          local_pos.x <= max_bounds.x - border_margin and
          local_pos.z >= min_bounds.z + border_margin and
          local_pos.z <= max_bounds.z - border_margin)

func _has_obstacle_collision(target_position: Vector3) -> bool:
  if not _placeable_obstacle:
    return false
  
  # Set up raycast to check for existing obstacles
  obstacle_detection_raycast.enabled = true
  obstacle_detection_raycast.global_position = target_position + raycast_start # Start from above
  obstacle_detection_raycast.target_position = raycast_down # Cast downward
  
  # Force raycast update
  obstacle_detection_raycast.force_raycast_update()
  
  var has_collision = obstacle_detection_raycast.is_colliding()
  if has_collision:
    var collider = obstacle_detection_raycast.get_collider()
    # Don't count collision with self
    if collider and collider != _placeable_obstacle:
      obstacle_detection_raycast.enabled = false
      return true
  
  obstacle_detection_raycast.enabled = false
  return false

func _has_terrain_support(_position: Vector3) -> bool:
  # Use the main raycast to check if we're hitting valid ground
  if not raycast.is_colliding():
    return false
  
  var collider = raycast.get_collider()
  if not collider:
    return false
  
  # Check if we're hitting the ground/terrain (collision layer 16/17)
  var collision_layer = 0
  if collider.has_method("get_collision_layer"):
    collision_layer = collider.get_collision_layer()
  
  # Should be hitting ground (layer 17 = 16 + 1)
  return (collision_layer & 16) != 0

func _has_sufficient_clearance(target_position: Vector3) -> bool:
  # Check for clearance around the obstacle position
  var space_state = get_world_3d().direct_space_state
  var query = PhysicsShapeQueryParameters3D.new()
  
  # Create a sphere to check clearance
  var sphere = SphereShape3D.new()
  sphere.radius = placement_clearance
  query.shape = sphere
  query.transform.origin = target_position
  query.collision_mask = 2 # Check for obstacles
  
  var results = space_state.intersect_shape(query)
  
  # Filter out self from results
  for result in results:
    if result.collider != _placeable_obstacle:
      return false
  
  return true

func _on_obstacle_spawn_requested(obstacle: ObstacleTypeResource) -> void:
  Logger.info("Placement", "Spawn obstacle button pressed for: %s" % obstacle.name)

  if busy:
    Logger.info("Placement", "Already placing an obstacle, cancelling previous placement")
    _cancel_obstacle_placement()

  _place_obstacle_type = obstacle
  _placeable_obstacle = obstacle.scene.instantiate()
  Logger.info("Placement", "Instantiated obstacle: %s" % _placeable_obstacle.name)
  raycast.enabled = true
  add_child(_placeable_obstacle)
  
  # Enable placement mode to disable collisions
  _placeable_obstacle.enter_placement_mode()
  Logger.info("Placement", "Enabled placement mode - collisions disabled")
  
  # Store original material for restoration
  if _placeable_obstacle.mesh_instance:
    _original_material = _placeable_obstacle.mesh_instance.get_surface_override_material(0)
    # If no override material exists, get the mesh material
    if not _original_material and _placeable_obstacle.mesh_instance.mesh:
      _original_material = _placeable_obstacle.mesh_instance.mesh.surface_get_material(0)

func _place_obstacle() -> void:
  if not _placeable_obstacle:
    return
  
  var target_position = _placeable_obstacle.global_position
  
  # Check if placement is valid
  if not _is_placement_valid(target_position):
    Logger.warn("Placement", "Cannot place obstacle: Invalid placement location")
    # Debug information about why placement failed
    if not _is_within_navigation_region(target_position):
      Logger.debug("Placement", "  - Outside navigation region")
    if _has_obstacle_collision(target_position):
      Logger.debug("Placement", "  - Collision with existing obstacle")
    if not _has_terrain_support(target_position):
      Logger.debug("Placement", "  - Invalid terrain support")
    if not _has_sufficient_clearance(target_position):
      Logger.debug("Placement", "  - Insufficient clearance")
    return
  
  # Restore original material before placing
  if _placeable_obstacle.mesh_instance:
    if _original_material:
      _placeable_obstacle.mesh_instance.set_surface_override_material(0, _original_material)
    else:
      # Clear any override material to use the default mesh material
      _placeable_obstacle.mesh_instance.set_surface_override_material(0, null)

  # Deduct cost
  if not CurrencyManager.spend_currency(_place_obstacle_type.cost):
    # This should not happen due to prior validation, but just in case
    Logger.error("Placement", "Cannot place obstacle: Insufficient funds")
    return
  
  # Store obstacle type reference for potential removal
  _placeable_obstacle.obstacle_type = _place_obstacle_type
  Logger.info("Placement", "Setting obstacle_type to: %s (cost: %d)" % [_place_obstacle_type.name, _place_obstacle_type.cost])
  Logger.info("Placement", "Obstacle now has obstacle_type: %s" % ("null" if not _placeable_obstacle.obstacle_type else _placeable_obstacle.obstacle_type.name))
  
  _placeable_obstacle.place(navigation_region)
  rebake_navigation_mesh.emit()
  
  _clear_obstacle_placement()

func _cancel_obstacle_placement() -> void:
  _placeable_obstacle.queue_free()
  _clear_obstacle_placement()
  
func _clear_obstacle_placement() -> void:
  _placeable_obstacle = null
  _place_obstacle_type = null
  raycast.enabled = false

func _update_visual_feedback(target_position: Vector3) -> void:
  if not _placeable_obstacle or not _placeable_obstacle.mesh_instance:
    return

  # Only update if we have valid materials
  if not _valid_material or not _invalid_material:
    return

  var is_valid = _is_placement_valid(target_position)
  var material = _valid_material if is_valid else _invalid_material
  
  _placeable_obstacle.mesh_instance.set_surface_override_material(0, material)

func _project_placed_obstacle(mouse_position: Vector2) -> void:
  var ray_origin = camera.project_ray_origin(mouse_position)
  var ray_direction = camera.project_ray_normal(mouse_position)
  raycast.target_position = ray_direction * raycast_length
  raycast.position = ray_origin
