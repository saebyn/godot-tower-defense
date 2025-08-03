extends Node3D

@export var camera_move_speed: float = 5.0
@export var camera_zoom_speed: float = 50.0
@onready var camera: Camera3D = $Camera3D

func _process(delta: float) -> void:
  # Update camera position based on player input
  var input_vector := Input.get_vector("camera_move_down", "camera_move_up", "camera_move_left", "camera_move_right")
  var zoom_amount := Input.get_axis("camera_zoom_in", "camera_zoom_out")

  if input_vector != Vector2.ZERO:
    var move_direction := Vector3(input_vector.x, 0, input_vector.y)
    camera.global_position += move_direction * camera_move_speed * delta

  if Input.is_action_just_pressed("camera_rotate_left"):
    rotate_y(-PI / 2) # Rotate left by 90 degrees

  if Input.is_action_just_pressed("camera_rotate_right"):
    rotate_y(PI / 2) # Rotate right by 90 degrees

  if zoom_amount != 0:
    camera.size += zoom_amount * camera_zoom_speed * delta