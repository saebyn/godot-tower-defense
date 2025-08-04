extends Node3D

@export var camera_move_speed: float = 5.0
@export var camera_zoom_speed: float = 50.0
@export var camera_zoom_step: float = 2.0  # Fixed zoom amount per wheel tick
@export var camera_zoom_fast_multiplier: float = 3.0  # Fast zoom multiplier when Shift is held
@export var camera_min_size: float = 5.0   # Minimum zoom (closest)
@export var camera_max_size: float = 100.0 # Maximum zoom (farthest)
@export var camera_zoom_duration: float = 0.2  # Duration for smooth zoom transitions
@onready var camera: Camera3D = $Camera3D

var zoom_tween: Tween

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
    
    var target_size: float
    if zoom_in_pressed:
      target_size = max(camera.size - actual_zoom_step, camera_min_size)
    elif zoom_out_pressed:
      target_size = min(camera.size + actual_zoom_step, camera_max_size)
    
    # Create smooth zoom transition
    if target_size != camera.size:
      # Kill any existing zoom tween
      if zoom_tween:
        zoom_tween.kill()
      
      # Create new tween for smooth zoom
      zoom_tween = create_tween()
      zoom_tween.set_ease(Tween.EASE_OUT)
      zoom_tween.set_trans(Tween.TRANS_QUART)
      zoom_tween.tween_property(camera, "size", target_size, camera_zoom_duration)