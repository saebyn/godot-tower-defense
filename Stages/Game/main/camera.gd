extends Camera3D

@export var camera_move_speed: float = 5.0
@export var camera_zoom_speed: float = 50.0
@export var camera_zoom_step: float = 2.0 # Fixed zoom amount per wheel tick
@export var camera_zoom_fast_multiplier: float = 3.0 # Fast zoom multiplier when Shift is held
@export var camera_min_size: float = 5.0 # Minimum zoom (closest)
@export var camera_max_size: float = 100.0 # Maximum zoom (farthest)
@export var camera_zoom_duration: float = 0.2 # Duration for smooth zoom transitions

@export_group("Mouse Controls")
@export var enable_middle_mouse_drag: bool = true # Enable middle-mouse button drag to move camera
@export var mouse_drag_speed: float = 0.5 # Speed multiplier for mouse drag movement
@export var enable_edge_scroll: bool = true # Enable camera movement when mouse is at screen edge
@export var edge_scroll_margin: float = 20.0 # Distance from screen edge to trigger scrolling (in pixels)
@export var edge_scroll_speed: float = 30.0 # Speed of edge scrolling

@export_group("Camera Boundaries")
@export var enable_boundaries: bool = true # Enable camera boundary constraints
@export var world_min_x: float = -200.0 # Minimum X boundary for camera orbit center
@export var world_max_x: float = 200.0 # Maximum X boundary for camera orbit center
@export var world_min_z: float = -200.0 # Minimum Z boundary for camera orbit center
@export var world_max_z: float = 200.0 # Maximum Z boundary for camera orbit center

var zoom_tween: Tween
var orbit_center: Vector3 # The point on the ground the camera orbits around
var input_enabled: bool = true # Track if camera input should be processed

# Mouse drag state
var _is_middle_mouse_pressed: bool = false
var _last_mouse_position: Vector2 = Vector2.ZERO

const CAMERA_VIEW_ALIGNMENT_OFFSET := PI / 2 ## 90 degrees in radians rotation to align movement with camera view


func _ready():
  # Initialize the orbit center to the current ground projection
  _update_orbit_center()
  
  # Set input_enabled based on current game state to avoid processing input in menus
  input_enabled = GameManager.current_state == GameManager.GameState.PLAYING
  
  # Connect to GameManager state changes to disable input during menus
  GameManager.game_state_changed.connect(_on_game_state_changed)


func _input(event: InputEvent) -> void:
  # Skip input processing if camera input is disabled (e.g., menus are open)
  if not input_enabled:
    return
  
  # Handle middle-mouse button press/release for drag movement
  if enable_middle_mouse_drag and event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_MIDDLE:
      if event.pressed:
        _is_middle_mouse_pressed = true
        _last_mouse_position = event.position
      else:
        _is_middle_mouse_pressed = false
  
  # Handle mouse motion for drag movement
  if enable_middle_mouse_drag and _is_middle_mouse_pressed and event is InputEventMouseMotion:
    var mouse_delta = event.position - _last_mouse_position
    _last_mouse_position = event.position
    
    # Convert mouse delta to world movement and apply it
    var move_direction = _convert_2d_to_world_movement(mouse_delta)
    global_position += move_direction * mouse_drag_speed
    
    # Update orbit center after movement
    _update_orbit_center()
    
    # Apply camera boundary constraints
    if enable_boundaries:
      _apply_boundary_constraints()

## Handle game state changes to disable camera input during menus
func _on_game_state_changed(new_state: GameManager.GameState):
  # Disable camera input when in any menu state
  match new_state:
    GameManager.GameState.PLAYING:
      input_enabled = true
    GameManager.GameState.IN_GAME_MENU, GameManager.GameState.MAIN_MENU, GameManager.GameState.GAME_OVER, GameManager.GameState.VICTORY:
      input_enabled = false
    _:
      input_enabled = false


## Convert 2D screen-space movement to 3D world-space movement
## Applies camera rotation alignment and returns the rotated direction
func _convert_2d_to_world_movement(delta_2d: Vector2) -> Vector3:
  # Create movement direction in world space
  var move_direction := Vector3(delta_2d.x, 0, delta_2d.y)
  
  # Rotate the movement direction by the camera's Y-axis rotation
  move_direction = move_direction.rotated(Vector3.UP, rotation.y + CAMERA_VIEW_ALIGNMENT_OFFSET)
  
  return move_direction


func _process(delta: float) -> void:
  # Skip input processing if camera input is disabled (e.g., menus are open)
  if not input_enabled:
    return
  
  # Handle edge scrolling
  var edge_movement := Vector2.ZERO
  if enable_edge_scroll:
    var viewport = get_viewport()
    if viewport:
      var viewport_size = viewport.get_visible_rect().size
      var mouse_pos = viewport.get_mouse_position()
      
      # Check if mouse is near screen edges
      if mouse_pos.x < edge_scroll_margin:
        edge_movement.x = -1.0
      elif mouse_pos.x > viewport_size.x - edge_scroll_margin:
        edge_movement.x = 1.0
      
      if mouse_pos.y < edge_scroll_margin:
        edge_movement.y = -1.0
      elif mouse_pos.y > viewport_size.y - edge_scroll_margin:
        edge_movement.y = 1.0
      
      # Apply edge scroll movement if detected
      if edge_movement != Vector2.ZERO:
        var move_direction = _convert_2d_to_world_movement(edge_movement)
        global_position += move_direction * edge_scroll_speed * delta
        
        # Update orbit center after movement
        _update_orbit_center()
        
        # Apply camera boundary constraints
        if enable_boundaries:
          _apply_boundary_constraints()
    
  # Update camera position based on player input (keyboard)
  var input_vector := Input.get_vector("camera_move_down", "camera_move_up", "camera_move_left", "camera_move_right")

  if input_vector != Vector2.ZERO:
    # Create movement direction in world space (as original code did)
    var move_direction := Vector3(input_vector.x, 0, input_vector.y)

    # Rotate the movement direction by the camera's Y-axis rotation
    move_direction = move_direction.rotated(Vector3.UP, rotation.y + CAMERA_VIEW_ALIGNMENT_OFFSET).normalized()
    
    global_position += move_direction * camera_move_speed * delta
    
    # Update orbit center after movement
    _update_orbit_center()
    
    # Apply camera boundary constraints
    if enable_boundaries:
      _apply_boundary_constraints()

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
  # TODO: Incomplete for uneven terrain. Consider using a raycast to find exact ground intersection. See https://github.com/saebyn/zom-nom-defense/issues/92
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
  
  # Apply boundary constraints after rotation
  if enable_boundaries:
    _apply_boundary_constraints()


func _apply_boundary_constraints():
  # Constrain the orbit center (where the camera is looking) to stay within world bounds
  var constrained_center = orbit_center
  constrained_center.x = clamp(constrained_center.x, world_min_x, world_max_x)
  constrained_center.z = clamp(constrained_center.z, world_min_z, world_max_z)
  
  # If the orbit center was constrained, adjust the camera position to maintain the same offset
  if constrained_center != orbit_center:
    var offset = global_position - orbit_center
    global_position = constrained_center + offset
    orbit_center = constrained_center
