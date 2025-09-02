extends Node
class_name ObstaclePlacement

signal rebake_navigation_mesh

@export var raycast_length: float = 1000.0 # Length of the raycast for obstacle placement
@export var navigation_region: NavigationRegion3D
@export var camera: Camera3D
@export var placement_clearance: float = 3.0 # Minimum distance from other obstacles

@onready var raycast: RayCast3D = $RayCast3D
@onready var obstacle_detection_raycast: RayCast3D = RayCast3D.new()

var busy: bool:
  get:
    return _placeable_obstacle != null

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
  obstacle_detection_raycast.collision_mask = 2  # Check for obstacles (layer 2)

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

# Placement validation functions
func _is_placement_valid(position: Vector3) -> bool:
  if not _placeable_obstacle:
    return false
    
  return (_is_within_navigation_region(position) and
          not _has_obstacle_collision(position) and
          _has_terrain_support(position) and
          _has_sufficient_clearance(position))

func _is_within_navigation_region(position: Vector3) -> bool:
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
  var local_pos = nav_region_transform.affine_inverse() * position
  
  # Check if within bounds (with some margin)
  var margin = 2.0
  return (local_pos.x >= min_bounds.x + margin and
          local_pos.x <= max_bounds.x - margin and
          local_pos.z >= min_bounds.z + margin and
          local_pos.z <= max_bounds.z - margin)

func _has_obstacle_collision(position: Vector3) -> bool:
  if not _placeable_obstacle:
    return false
  
  # Set up raycast to check for existing obstacles
  obstacle_detection_raycast.enabled = true
  obstacle_detection_raycast.global_position = position + Vector3(0, 10, 0)  # Start from above
  obstacle_detection_raycast.target_position = Vector3(0, -20, 0)  # Cast downward
  
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

func _has_terrain_support(position: Vector3) -> bool:
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

func _has_sufficient_clearance(position: Vector3) -> bool:
  # Check for clearance around the obstacle position
  var space_state = get_world_3d().direct_space_state
  var query = PhysicsShapeQueryParameters3D.new()
  
  # Create a sphere to check clearance
  var sphere = SphereShape3D.new()
  sphere.radius = placement_clearance
  query.shape = sphere
  query.transform.origin = position
  query.collision_mask = 2  # Check for obstacles
  
  var results = space_state.intersect_shape(query)
  
  # Filter out self from results
  for result in results:
    if result.collider != _placeable_obstacle:
      return false
  
  return true

func _on_obstacle_spawn_requested(obstacle_instance: Node3D) -> void:
  print("Spawn obstacle button pressed")
  _placeable_obstacle = obstacle_instance
  raycast.enabled = true
  add_child(_placeable_obstacle)
  
  # Store original material for restoration
  if _placeable_obstacle.mesh_instance:
    _original_material = _placeable_obstacle.mesh_instance.get_surface_override_material(0)
    # If no override material exists, get the mesh material
    if not _original_material and _placeable_obstacle.mesh_instance.mesh:
      _original_material = _placeable_obstacle.mesh_instance.mesh.surface_get_material(0)

func _place_obstacle() -> void:
  if not _placeable_obstacle:
    return
  
  var position = _placeable_obstacle.global_position
  
  # Check if placement is valid
  if not _is_placement_valid(position):
    print("Cannot place obstacle: Invalid placement location")
    return
  
  # Restore original material before placing
  if _placeable_obstacle.mesh_instance:
    if _original_material:
      _placeable_obstacle.mesh_instance.set_surface_override_material(0, _original_material)
    else:
      # Clear any override material to use the default mesh material
      _placeable_obstacle.mesh_instance.set_surface_override_material(0, null)
  
  _placeable_obstacle.place(navigation_region)
  rebake_navigation_mesh.emit()
  _placeable_obstacle = null
  raycast.enabled = false

func _cancel_obstacle_placement() -> void:
  # Restore original material before freeing if possible
  if _placeable_obstacle and _placeable_obstacle.mesh_instance:
    if _original_material:
      _placeable_obstacle.mesh_instance.set_surface_override_material(0, _original_material)
    else:
      _placeable_obstacle.mesh_instance.set_surface_override_material(0, null)
  
  _placeable_obstacle.queue_free()
  _placeable_obstacle = null
  raycast.enabled = false

func _update_visual_feedback(position: Vector3) -> void:
  if not _placeable_obstacle or not _placeable_obstacle.mesh_instance:
    return
  
  # Only update if we have valid materials
  if not _valid_material or not _invalid_material:
    return
  
  var is_valid = _is_placement_valid(position)
  var material = _valid_material if is_valid else _invalid_material
  
  _placeable_obstacle.mesh_instance.set_surface_override_material(0, material)

func _project_placed_obstacle(mouse_position: Vector2) -> void:
  var ray_origin = camera.project_ray_origin(mouse_position)
  var ray_direction = camera.project_ray_normal(mouse_position)
  raycast.target_position = ray_direction * raycast_length
  raycast.position = ray_origin
