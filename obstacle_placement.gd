extends Node
class_name ObstaclePlacement

signal rebake_navigation_mesh

@export var raycast_length: float = 1000.0 # Length of the raycast for obstacle placement
@export var navigation_region: NavigationRegion3D
@export var camera: Camera3D

@onready var raycast: RayCast3D = $RayCast3D

var busy: bool:
  get:
    return _placeable_obstacle != null

var _placeable_obstacle: PlaceableObstacle = null

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

func _input(event: InputEvent) -> void:
  if event is InputEventMouseMotion and busy:
    _project_placed_obstacle(event.position)

# TODO implement rules for object placement
# - check for collisions with other obstacles
# - ensure the obstacle is placed within the navigation region
# - check for space availability
# - check that obstacle is not placed on terrain that does not support it (e.g., water, roads)

func _on_obstacle_spawn_requested(obstacle_instance: Node3D) -> void:
  print("Spawn obstacle button pressed")
  _placeable_obstacle = obstacle_instance
  raycast.enabled = true
  add_child(_placeable_obstacle)

func _place_obstacle() -> void:
  _placeable_obstacle.place(navigation_region)
  rebake_navigation_mesh.emit()
  _placeable_obstacle = null
  raycast.enabled = false

func _cancel_obstacle_placement() -> void:
  _placeable_obstacle.queue_free()
  _placeable_obstacle = null
  raycast.enabled = false

func _project_placed_obstacle(mouse_position: Vector2) -> void:
  var ray_origin = camera.project_ray_origin(mouse_position)
  var ray_direction = camera.project_ray_normal(mouse_position)
  raycast.target_position = ray_direction * raycast_length
  raycast.position = ray_origin
