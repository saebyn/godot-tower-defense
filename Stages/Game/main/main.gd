extends Node3D

@export_group("Camera Settings")
@export var camera_move_speed: float = 5.0
@export var camera_zoom_speed: float = 50.0
@export var camera_zoom_step: float = 2.0 # Fixed zoom amount per wheel tick
@export var camera_zoom_fast_multiplier: float = 3.0 # Fast zoom multiplier when Shift is held
@export var camera_min_size: float = 5.0 # Minimum zoom (closest)
@export var camera_max_size: float = 100.0 # Maximum zoom (farthest)
@export var camera_zoom_duration: float = 0.2 # Duration for smooth zoom transitions

@export_group("Attack Settings")
@export var raycast_length: float = 1000.0

@onready var camera: Camera3D = $Camera3D
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D
@onready var enemy_raycast: RayCast3D = $EnemyRayCast3D
@onready var attack: Attack = $Attack
@onready var ui: Control = $UI
@onready var enemy_spawner: EnemySpawner = $EnemySpawner

@onready var obstacle_placement: ObstaclePlacement = $ObstaclePlacement

var zoom_tween: Tween

func _ready() -> void:
  # Connect enemy spawner signal to UI immediately (not deferred)
  _connect_signals()

func _connect_signals() -> void:
  if enemy_spawner and ui:
    enemy_spawner.enemy_spawned.connect(ui._on_enemy_spawned)
    enemy_spawner.wave_started.connect(_on_wave_started)
    enemy_spawner.wave_completed.connect(_on_wave_completed)
    print("Connected enemy_spawned and wave signals to UI")
  else:
    print("Warning: enemy_spawner or ui not available for signal connection")

func _on_wave_started(wave: Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  ui._on_wave_started(wave, wave_number)

func _on_wave_completed(wave: Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  ui._on_wave_completed(wave, wave_number)


func _process(delta: float) -> void:
  # Don't process camera controls when paused
  if GameManager.current_state == GameManager.GameState.PAUSED:
    return
    
  # Update camera position based on player input
  var input_vector := Input.get_vector("camera_move_down", "camera_move_up", "camera_move_left", "camera_move_right")

  if input_vector != Vector2.ZERO:
    var move_direction := Vector3(input_vector.x, 0, input_vector.y)
    camera.global_position += move_direction * camera_move_speed * delta

  # Handle camera rotation
  if Input.is_action_just_pressed("camera_rotate_left"):
    camera.rotate_y(-PI / 2) # Rotate left by 90 degrees

  if Input.is_action_just_pressed("camera_rotate_right"):
    camera.rotate_y(PI / 2) # Rotate right by 90 degrees

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


func rebake_navigation_mesh():
  Logger.info("Navigation", "Rebaking navigation mesh...")
  if navigation_region and navigation_region.navigation_mesh:
    if navigation_region.is_baking():
      # Wait and retry if already baking
      Logger.debug("Navigation", "Navigation mesh is already baking, waiting...")
      await navigation_region.bake_finished

    navigation_region.bake_navigation_mesh()
    Logger.info("Navigation", "Navigation mesh rebaked!")


func _input(event: InputEvent) -> void:
  # Handle pause toggle (ESC key)
  if Input.is_action_just_pressed("toggle_pause"):
    _toggle_pause()
    return
  
  # Only handle other inputs when not paused
  if GameManager.current_state == GameManager.GameState.PAUSED:
    return
  
  if event is InputEventMouseButton and not obstacle_placement.busy and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    _handle_enemy_click(event.position)


func _spawn_test_enemy():
  # Load and spawn a test enemy
  var enemy_scene = preload("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  var enemy = enemy_scene.instantiate()
  
  # Spawn enemy at a fixed position in front of the camera
  enemy.global_position = camera.global_position + Vector3(0, 0, 10)
  
  # Add to the scene
  add_child(enemy)
  Logger.debug("Test", "Test enemy spawned! Press T to spawn more, click on enemies to damage them.")


func _handle_enemy_click(click_position: Vector2):
  # Create a raycast from the camera to detect what was clicked
  var ray_origin = camera.project_ray_origin(click_position)
  var ray_direction = camera.project_ray_normal(click_position)
  
  # Use the dedicated enemy raycast
  enemy_raycast.enabled = true
  enemy_raycast.position = ray_origin
  enemy_raycast.target_position = ray_direction * raycast_length
  
  # Force the raycast to update
  enemy_raycast.force_raycast_update()
  
  if enemy_raycast.is_colliding():
    var collider = enemy_raycast.get_collider()
    Logger.debug("Player", "Clicked on: %s" % collider.name)
    # If the collider is an enemy, perform an attack
    attack.perform_attack(collider)
  
  # Disable the enemy raycast after use
  enemy_raycast.enabled = false


func _toggle_pause():
  if GameManager.current_state == GameManager.GameState.PLAYING:
    GameManager.pause_game()
  elif GameManager.current_state == GameManager.GameState.PAUSED:
    GameManager.resume_game()


func _on_obstacle_spawn_requested(obstacle: ObstacleTypeResource) -> void:
  # Forward the signal to the obstacle placement system
  obstacle_placement._on_obstacle_spawn_requested(obstacle)