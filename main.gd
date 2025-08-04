extends Node3D

@export var camera_move_speed: float = 5.0
@export var camera_zoom_speed: float = 50.0
@export var camera_zoom_step: float = 2.0  # Fixed zoom amount per wheel tick
@export var camera_zoom_fast_multiplier: float = 3.0  # Fast zoom multiplier when Shift is held
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

  # Handle discrete zoom events from mouse wheel and keyboard
  var zoom_in_pressed = Input.is_action_just_pressed("camera_zoom_in") or Input.is_action_just_pressed("camera_zoom_in_key")
  var zoom_out_pressed = Input.is_action_just_pressed("camera_zoom_out") or Input.is_action_just_pressed("camera_zoom_out_key")
  
  if zoom_in_pressed or zoom_out_pressed:
    # Check if Shift is held for fast zoom
    var zoom_multiplier = camera_zoom_fast_multiplier if Input.is_action_pressed("zoom_fast") else 1.0
    var actual_zoom_step = camera_zoom_step * zoom_multiplier
    
    if zoom_in_pressed:
      camera.size = max(camera.size - actual_zoom_step, camera_min_size)
    elif zoom_out_pressed:
      camera.size = min(camera.size + actual_zoom_step, camera_max_size)