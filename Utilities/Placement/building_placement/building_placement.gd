extends Node3D
class_name Utility_BuildingPlacement

signal rebake_navigation_mesh
signal placement_mode_entered ## Emitted when entering building placement mode
signal placement_mode_exited ## Emitted when exiting building placement mode
signal building_placed ## Emitted when a building is successfully placed

@export_group("Placement Settings")
@export var placement_clearance: float = 3.0 ## Minimum distance from other buildings
@export var world_min_x: float = -200.0 # Minimum X boundary
@export var world_max_x: float = 200.0 # Maximum X boundary
@export var world_min_z: float = -200.0 # Minimum Z boundary
@export var world_max_z: float = 200.0 # Maximum Z boundary

@export_group("Sound Effects")
@export var audio_player: AudioStreamPlayer

@export_group("Raycast Settings")
@export var raycast_length: float = 1000.0 ## Length of the raycast for building placement
@export var raycast_start: Vector3 = Vector3(0, 10, 0) ## Start position offset for the raycast
@export var raycast_down: Vector3 = Vector3(0, -20, 0) ## Direction and length to cast downwards

@export_group("Node References")
@export var camera: Camera3D

@onready var raycast: RayCast3D = $RayCast3D
@onready var building_detection_raycast: RayCast3D = RayCast3D.new()

var busy: bool:
  get:
    return _preview != null

var _place_building_type: Resource_BuildingType = null
var _preview: Entity_PlaceableBuilding = null
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D

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
  
  # Set up building detection raycast
  add_child(building_detection_raycast)
  building_detection_raycast.enabled = false
  building_detection_raycast.collision_mask = 2 # Check for buildings (layer 2)

func _process(_delta: float) -> void:
  if _preview:
    if Input.is_action_just_pressed("place_cancel"):
      # Handle building placement cancellation
      _cancel_building_placement()
    elif Input.is_action_just_pressed("place_building"):
      # Handle building placement confirmation
      _place_building()
    elif Input.is_action_just_pressed("place_rotate_left"):
      # Rotate the building left
      _preview.rotate_y(-PI / 2) # Rotate left by 90 degrees
    elif Input.is_action_just_pressed("place_rotate_right"):
      # Rotate the building right
      _preview.rotate_y(PI / 2) # Rotate right by 90 degrees


func _physics_process(_delta: float) -> void:
  if _preview and raycast.is_colliding():
    var collision_point = raycast.get_collision_point()
    
    # Position preview at collision point
    # This assumes that all buildings' models are centered such that their base is at y=0
    _preview.global_position = collision_point
    
    # Update visual feedback based on placement validity
    _update_visual_feedback(collision_point)

func _input(event: InputEvent) -> void:
  if event is InputEventMouseMotion and busy:
    _project_placed_building(event.position)


func _validate_placement(target_position: Vector3) -> Utility_PlacementResult:
  if not _preview:
    return Utility_PlacementResult.new(false, Utility_PlacementResult.ValidationError.NO_PLACEABLE_BUILDING, "No building selected for placement")

  if not _is_within_border(target_position):
    return Utility_PlacementResult.new(false, Utility_PlacementResult.ValidationError.OUTSIDE_BORDER, "Outside world boundaries")
  
  if _has_building_collision(target_position):
    return Utility_PlacementResult.new(false, Utility_PlacementResult.ValidationError.BUILDING_COLLISION, "Collision with existing building")
  
  if not _has_terrain_support(target_position):
    return Utility_PlacementResult.new(false, Utility_PlacementResult.ValidationError.NO_TERRAIN_SUPPORT, "No valid terrain support")
  
  if not _has_sufficient_clearance(target_position):
    return Utility_PlacementResult.new(false, Utility_PlacementResult.ValidationError.INSUFFICIENT_CLEARANCE, "Insufficient clearance from other buildings")

  if CurrencyManager.get_scrap() < _place_building_type.cost:
    return Utility_PlacementResult.new(false, Utility_PlacementResult.ValidationError.INSUFFICIENT_FUNDS, "Insufficient funds to place building")
  
  return Utility_PlacementResult.new(true)

func _is_placement_valid(target_position: Vector3) -> bool:
  var result = _validate_placement(target_position)
  # TODO enhance feedback to user
  if not result.is_valid:
    MyLogger.debug("Placement", "Invalid placement: %s" % result.error_message)
    # Debug information about why placement failed
    match result.error:
      Utility_PlacementResult.ValidationError.NO_PLACEABLE_BUILDING:
        MyLogger.debug("Placement", "  - No placeable building selected")
      Utility_PlacementResult.ValidationError.OUTSIDE_BORDER:
        MyLogger.debug("Placement", "  - Outside world boundaries")
      Utility_PlacementResult.ValidationError.BUILDING_COLLISION:
        MyLogger.debug("Placement", "  - Collision with existing building")
      Utility_PlacementResult.ValidationError.NO_TERRAIN_SUPPORT:
        MyLogger.debug("Placement", "  - Invalid terrain support")
      Utility_PlacementResult.ValidationError.INSUFFICIENT_CLEARANCE:
        MyLogger.debug("Placement", "  - Insufficient clearance")
      Utility_PlacementResult.ValidationError.INSUFFICIENT_FUNDS:
        MyLogger.debug("Placement", "  - Insufficient funds")

  return result.is_valid

func _is_within_border(target_position: Vector3) -> bool:
  return target_position.x >= world_min_x and target_position.x <= world_max_x and target_position.z >= world_min_z and target_position.z <= world_max_z

func _has_building_collision(target_position: Vector3) -> bool:
  if not _preview:
    return false
  
  # Set up raycast to check for existing buildings
  building_detection_raycast.enabled = true
  building_detection_raycast.global_position = target_position + raycast_start # Start from above
  building_detection_raycast.target_position = raycast_down # Cast downward
  
  # Force raycast update
  building_detection_raycast.force_raycast_update()
  
  var has_collision = building_detection_raycast.is_colliding()
  if has_collision:
    var collider = building_detection_raycast.get_collider()
    if collider:
      building_detection_raycast.enabled = false
      return true
  
  building_detection_raycast.enabled = false
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
  # Check for clearance around the building position
  var space_state = get_world_3d().direct_space_state
  var query = PhysicsShapeQueryParameters3D.new()
  
  # Create a sphere to check clearance
  var sphere = SphereShape3D.new()
  sphere.radius = placement_clearance
  query.shape = sphere
  query.transform.origin = target_position
  query.collision_mask = 2 # Check for buildings

  return space_state.intersect_shape(query).size() == 0

func _on_building_spawn_requested(building_type: Resource_BuildingType) -> void:
  MyLogger.info("Placement", "Spawn building button pressed for: %s" % building_type.name)

  if busy:
    MyLogger.info("Placement", "Already placing a building, cancelling previous placement")
    _cancel_building_placement()

  _place_building_type = building_type
  _preview = building_type.scene.instantiate()
  _preview.building_type = building_type
  _preview.is_preview = true
  MyLogger.info("Placement", "Created preview for building: %s" % building_type.name)
  raycast.enabled = true
  add_child(_preview)
  placement_mode_entered.emit()

func _place_building() -> void:
  if not _preview:
    return
  
  # Check if placement is valid
  if not _is_placement_valid(_preview.global_position):
    return

  # Deduct cost
  if not CurrencyManager.spend_scrap(_place_building_type.cost):
    # This should not happen due to prior validation, but just in case
    MyLogger.error("Placement", "Cannot place building: Insufficient funds")
    return
  
  _preview.place()

  rebake_navigation_mesh.emit()
  building_placed.emit()
  
  # Track building placement in stats system
  if StatsManager and _place_building_type:
    StatsManager.track_building_placed(_place_building_type.id)
  
  _clear_building_placement()

  AudioManager.play_sound(audio_player, Resource_SoundEffect.SoundEffect.BUILDING_COMPLETE)

func _cancel_building_placement() -> void:
  if _preview:
    _preview.queue_free()
    _preview = null
  _clear_building_placement()
  AudioManager.play_sound(audio_player, Resource_SoundEffect.SoundEffect.UI_CANCEL)

func _clear_building_placement() -> void:
  if _preview:
    _preview = null
  _place_building_type = null
  raycast.enabled = false
  placement_mode_exited.emit()

func _update_visual_feedback(target_position: Vector3) -> void:
  if not _preview:
    return

  # Only update if we have valid materials
  if not _valid_material or not _invalid_material:
    return

  var is_valid = _is_placement_valid(target_position)
  var material = _valid_material if is_valid else _invalid_material
  
  _preview.set_preview_material(material)

func _project_placed_building(mouse_position: Vector2) -> void:
  var ray_origin = camera.project_ray_origin(mouse_position)
  var ray_direction = camera.project_ray_normal(mouse_position)
  raycast.target_position = ray_direction * raycast_length
  raycast.position = ray_origin
