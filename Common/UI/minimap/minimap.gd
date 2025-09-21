"""
Minimap.gd

A minimap UI component that shows an overhead view of the game area.
Displays enemy positions, obstacles, and the player's camera view area.

Features:
- Top-down view of the entire game area
- Real-time enemy position tracking
- Camera viewport visualization
- Obstacle and target display
- Configurable size and position
- Click-to-move camera functionality

Usage:
- Add as child to main UI scene
- Automatically finds game components
- Configurable through exported properties
"""
extends Control
class_name Minimap

@export var minimap_size: Vector2 = Vector2(150, 150) ## Size of the minimap
@export var minimap_position: Vector2 = Vector2(10, 10) ## Position from top-left corner
@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.8) ## Background color
@export var enemy_color: Color = Color.RED ## Color for enemy dots
@export var obstacle_color: Color = Color.GRAY ## Color for obstacle markers
@export var target_color: Color = Color.GREEN ## Color for target markers
@export var camera_view_color: Color = Color(1, 1, 1, 0.3) ## Color for camera view area
@export var enemy_dot_size: float = 3.0 ## Size of enemy dots on minimap
@export var update_interval: float = 0.2 ## How often to update minimap

@onready var camera: Camera3D
@onready var enemy_spawner: EnemySpawner

# Minimap components
var background_panel: Panel
var minimap_canvas: Control
var update_timer: Timer

# Game world bounds
var world_bounds: AABB

func _ready() -> void:
  # Setup minimap UI
  _setup_minimap_ui()
  
  # Find game components
  _find_game_components()
  
  # Setup update timer
  update_timer = Timer.new()
  update_timer.wait_time = update_interval
  update_timer.timeout.connect(_update_minimap)
  add_child(update_timer)
  update_timer.start()
  
  # Calculate world bounds
  _calculate_world_bounds()

func _setup_minimap_ui() -> void:
  # Set minimap size and position
  set_size(minimap_size)
  position = minimap_position
  
  # Create background panel
  background_panel = Panel.new()
  background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  background_panel.modulate = background_color
  add_child(background_panel)
  
  # Create canvas for drawing minimap elements
  minimap_canvas = Control.new()
  minimap_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  minimap_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
  add_child(minimap_canvas)
  
  # Connect mouse input for click-to-move
  minimap_canvas.gui_input.connect(_on_minimap_clicked)

func _find_game_components() -> void:
  # Find camera and enemy spawner
  camera = _find_camera(get_tree().root)
  enemy_spawner = _find_enemy_spawner(get_tree().root)
  
  if not camera:
    Logger.error("Minimap", "Could not find camera")
  if not enemy_spawner:
    Logger.error("Minimap", "Could not find enemy spawner")
  else:
    Logger.info("Minimap", "Found camera and enemy spawner successfully")

func _find_camera(node: Node) -> Camera3D:
  if node is Camera3D:
    return node as Camera3D
  
  for child in node.get_children():
    var result = _find_camera(child)
    if result:
      return result
  
  return null

func _find_enemy_spawner(node: Node) -> EnemySpawner:
  if node is EnemySpawner:
    return node as EnemySpawner
  
  for child in node.get_children():
    var result = _find_enemy_spawner(child)
    if result:
      return result
  
  return null

func _calculate_world_bounds() -> void:
  # For now, use a fixed world bounds. In a real implementation,
  # you'd calculate this from the navigation mesh or level geometry
  world_bounds = AABB(Vector3(-100, 0, -100), Vector3(200, 10, 200))

func _update_minimap() -> void:
  if not camera or not enemy_spawner:
    return
  
  # Clear previous elements
  _clear_minimap_canvas()
  
  # Draw camera viewport
  _draw_camera_viewport()
  
  # Draw enemies
  _draw_enemies()
  
  # Draw obstacles and targets (if we can find them)
  _draw_obstacles_and_targets()

func _clear_minimap_canvas() -> void:
  # Remove all child nodes from canvas (they'll be recreated)
  for child in minimap_canvas.get_children():
    child.queue_free()

func _draw_camera_viewport() -> void:
  if not camera:
    return
  
  # Get camera position and create a visual representation
  var camera_pos = camera.global_position
  var minimap_pos = _world_to_minimap(camera_pos)
  
  # Create a simple rectangle to represent camera view area
  var camera_indicator = Panel.new()
  camera_indicator.set_size(Vector2(20, 20))
  camera_indicator.position = minimap_pos - Vector2(10, 10)
  camera_indicator.modulate = camera_view_color
  minimap_canvas.add_child(camera_indicator)

func _draw_enemies() -> void:
  if not enemy_spawner:
    return
  
  for enemy in enemy_spawner.current_enemies:
    if not enemy or not is_instance_valid(enemy):
      continue
    
    var enemy_pos = enemy.global_position
    var minimap_pos = _world_to_minimap(enemy_pos)
    
    # Create enemy dot
    var enemy_dot = Panel.new()
    enemy_dot.set_size(Vector2(enemy_dot_size, enemy_dot_size))
    enemy_dot.position = minimap_pos - Vector2(enemy_dot_size/2, enemy_dot_size/2)
    enemy_dot.modulate = enemy_color
    minimap_canvas.add_child(enemy_dot)

func _draw_obstacles_and_targets() -> void:
  # Find obstacles and targets in the scene
  var obstacles = get_tree().get_nodes_in_group("obstacles")
  var targets = get_tree().get_nodes_in_group("targets")
  
  # Draw obstacles
  for obstacle in obstacles:
    if obstacle is Node3D:
      var obstacle_pos = obstacle.global_position
      var minimap_pos = _world_to_minimap(obstacle_pos)
      
      var obstacle_marker = Panel.new()
      obstacle_marker.set_size(Vector2(4, 4))
      obstacle_marker.position = minimap_pos - Vector2(2, 2)
      obstacle_marker.modulate = obstacle_color
      minimap_canvas.add_child(obstacle_marker)
  
  # Draw targets
  for target in targets:
    if target is Node3D:
      var target_pos = target.global_position
      var minimap_pos = _world_to_minimap(target_pos)
      
      var target_marker = Panel.new()
      target_marker.set_size(Vector2(6, 6))
      target_marker.position = minimap_pos - Vector2(3, 3)
      target_marker.modulate = target_color
      minimap_canvas.add_child(target_marker)

func _world_to_minimap(world_pos: Vector3) -> Vector2:
  # Convert 3D world position to 2D minimap coordinates
  var normalized_x = (world_pos.x - world_bounds.position.x) / world_bounds.size.x
  var normalized_z = (world_pos.z - world_bounds.position.z) / world_bounds.size.z
  
  return Vector2(
    normalized_x * minimap_size.x,
    normalized_z * minimap_size.y
  )

func _minimap_to_world(minimap_pos: Vector2) -> Vector3:
  # Convert 2D minimap coordinates to 3D world position
  var normalized_x = minimap_pos.x / minimap_size.x
  var normalized_z = minimap_pos.y / minimap_size.y
  
  return Vector3(
    world_bounds.position.x + normalized_x * world_bounds.size.x,
    0, # Keep Y at ground level
    world_bounds.position.z + normalized_z * world_bounds.size.z
  )

func _on_minimap_clicked(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    if not camera:
      return
    
    # Get local click position
    var local_click = minimap_canvas.get_local_mouse_position()
    
    # Convert to world position
    var world_pos = _minimap_to_world(local_click)
    
    # Move camera to clicked position
    camera.global_position = Vector3(world_pos.x, camera.global_position.y, world_pos.z)
    
    Logger.info("Minimap", "Camera moved to: %s" % world_pos)