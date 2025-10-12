extends Camera3D

@export var camera_move_speed: float = 5.0
@export var camera_zoom_speed: float = 50.0
@export var camera_zoom_step: float = 2.0 # Fixed zoom amount per wheel tick
@export var camera_zoom_fast_multiplier: float = 3.0 # Fast zoom multiplier when Shift is held
@export var camera_min_size: float = 5.0 # Minimum zoom (closest)
@export var camera_max_size: float = 100.0 # Maximum zoom (farthest)
@export var camera_zoom_duration: float = 0.2 # Duration for smooth zoom transitions

var zoom_tween: Tween
var orbit_center: Vector3 # The point on the ground the camera orbits around

const CAMERA_VIEW_ALIGNMENT_OFFSET := PI / 2 ## 90 degrees in radians rotation to align movement with camera view


func _ready():
  # Initialize the orbit center to the current ground projection
  _update_orbit_center()


func _process(delta: float) -> void:
  # Update camera position based on player input
  var input_vector := Input.get_vector("camera_move_down", "camera_move_up", "camera_move_left", "camera_move_right")

  if input_vector != Vector2.ZERO:
    # Create movement direction in world space (as original code did)
    var move_direction := Vector3(input_vector.x, 0, input_vector.y)

    # Rotate the movement direction by the camera's Y-axis rotation
    move_direction = move_direction.rotated(Vector3.UP, rotation.y + CAMERA_VIEW_ALIGNMENT_OFFSET).normalized()
    
    global_position += move_direction * camera_move_speed * delta
    
    # Update orbit center after movement
    _update_orbit_center()

  # Handle camera rotation
  if Input.is_action_just_pressed("camera_rotate_left"):
    _orbit_around_center(-PI / 2) # Rotate left by 90 degrees

  if Input.is_action_just_pressed("camera_rotate_right"):
    _orbit_around_center(PI / 2) # Rotate right by 90 degrees

  # Handle discrete zoom events from mouse wheel and keyboard
  var zoom_in_pressed = Input.is_action_just_pressed("camera_zoom_in") or Input.is_action_just_pressed("camera_zoom_in_key")
  var zoom_out_pressed = Input.is_action_just_pressed("camera_zoom_out") or Input.is_action_just_pressed("camera_zoom_out_key")
  
  if zoom_in_pressed or zoom_out_pressed:
    # Check if Shift is held for fast zoom
    var zoom_multiplier = camera_zoom_fast_multiplier if not Input.is_action_pressed("zoom_slow") else 1.0
    var actual_zoom_step = camera_zoom_step * zoom_multiplier
    
    var target_size: float
    if zoom_in_pressed:
      target_size = max(size - actual_zoom_step, camera_min_size)
    elif zoom_out_pressed:
      target_size = min(size + actual_zoom_step, camera_max_size)
    
    # Create smooth zoom transition
    if target_size != size:
      # Kill any existing zoom tween
      if zoom_tween:
        zoom_tween.kill()
      
      # Create new tween for smooth zoom
      zoom_tween = create_tween()
      zoom_tween.set_ease(Tween.EASE_OUT)
      zoom_tween.set_trans(Tween.TRANS_QUART)
      zoom_tween.tween_property(self, "size", target_size, camera_zoom_duration)


func _update_orbit_center():
  # Calculate the point on the ground that the camera is looking at
  # TODO: Incomplete for uneven terrain. Consider using a raycast to find exact ground intersection. See https://github.com/saebyn/godot-tower-defense/issues/92
  var camera_forward = - transform.basis.z.normalized()
  var ground_plane = Plane(Vector3.UP, 0) # Ground plane at Y=0
  
  # Find intersection of camera ray with ground plane
  var ray_origin = global_position
  var ray_direction = camera_forward
  
  var intersection = ground_plane.intersects_ray(ray_origin, ray_direction)
  if intersection:
    orbit_center = intersection
  else:
    # Fallback: use current position projected to ground
    orbit_center = Vector3(global_position.x, 0, global_position.z)


func _orbit_around_center(angle: float):
  # Update orbit center before rotation
  _update_orbit_center()
  
  # Get the vector from orbit center to camera
  var offset = global_position - orbit_center
  
  # Rotate the offset around the Y-axis (up vector)
  offset = offset.rotated(Vector3.UP, angle)
  
  # Set new camera position
  global_position = orbit_center + offset
  
  # Rotate the camera itself to maintain the same viewing angle
  rotate_y(angle)
