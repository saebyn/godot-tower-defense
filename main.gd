extends Node3D

@export var camera_move_speed: float = 5.0
@export var camera_zoom_speed: float = 50.0
@export var camera_zoom_step: float = 2.0  # Fixed zoom amount per wheel tick
@export var camera_min_size: float = 5.0   # Minimum zoom (closest)
@export var camera_max_size: float = 100.0 # Maximum zoom (farthest)
@onready var camera: Camera3D = $Camera3D

func _process(delta: float) -> void:
  # Update camera position based on player input
  var input_vector := Input.get_vector("camera_move_down", "camera_move_up", "camera_move_left", "camera_move_right")

  if input_vector != Vector2.ZERO:
    var move_direction := Vector3(input_vector.x, 0, input_vector.y)
    camera.global_position += move_direction * camera_move_speed * delta

  if Input.is_action_just_pressed("camera_rotate_left"):
    rotate_y(-PI / 2) # Rotate left by 90 degrees

  if Input.is_action_just_pressed("camera_rotate_right"):
    rotate_y(PI / 2) # Rotate right by 90 degrees

  # Handle discrete zoom events from mouse wheel
  if Input.is_action_just_pressed("camera_zoom_in"):
    camera.size = max(camera.size - camera_zoom_step, camera_min_size)
  elif Input.is_action_just_pressed("camera_zoom_out"):
    camera.size = min(camera.size + camera_zoom_step, camera_max_size)