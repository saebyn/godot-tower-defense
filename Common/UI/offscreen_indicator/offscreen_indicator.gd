## OffscreenIndicator
## 
## A UI component that displays individual dot indicators for enemies outside the camera viewport.
## Shows one dot per enemy positioned at screen edges to indicate direction relative to current view.
## 
## Features:
## - Real-time tracking of all enemies from EnemySpawner
## - Individual dot indicators for each offscreen enemy
## - Dynamic positioning on screen edges based on enemy direction
## - Efficient pooling system for performance
## - Automatic show/hide based on enemy visibility
## - Subtle pulsing animation for visibility
## 
## Usage:
## - Add as child to main UI scene
## - Automatically finds camera and enemy spawner in scene tree
## - Configurable through exported properties
extends Control
class_name OffscreenIndicator

## UI component that displays indicators for enemies outside the viewport
## Shows direction and count of offscreen enemies at screen edges

@export var indicator_margin: float = 30.0 ## Distance from screen edge to place indicators
@export var indicator_size: Vector2 = Vector2(12, 12) ## Size of individual dot indicators
@export var update_interval: float = 0.1 ## How often to update indicator positions
@export var indicator_texture: Texture2D ## Texture for the indicator dots

@onready var camera: Camera3D
@onready var enemy_spawner: EnemySpawner

# Indicator pools for reuse
var indicator_pool: Array[Control] = []
var active_indicators: Array[Control] = []

# Update timer
var update_timer: Timer

func _ready() -> void:
  # Find camera and enemy spawner
  _find_game_components()
  
  # Setup update timer
  update_timer = Timer.new()
  update_timer.wait_time = update_interval
  update_timer.timeout.connect(_update_indicators)
  add_child(update_timer)
  update_timer.start()
  
  # Initialize indicator pool
  _initialize_indicator_pool()

func _find_game_components() -> void:
  # Simple recursive search for camera and enemy spawner
  camera = _find_camera(get_tree().root)
  enemy_spawner = _find_enemy_spawner(get_tree().root)
  
  if not camera:
    Logger.error("OffscreenIndicator", "Could not find camera")
  if not enemy_spawner:
    Logger.error("OffscreenIndicator", "Could not find enemy spawner")
  else:
    Logger.info("OffscreenIndicator", "Found camera and enemy spawner successfully")

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

func _initialize_indicator_pool() -> void:
  # Start with empty pool - indicators will be created as needed
  indicator_pool.clear()

func _update_indicators() -> void:
  if not camera or not enemy_spawner:
    return
  
  # Check if we're in a valid state (viewport exists)
  var viewport = get_viewport()
  if not viewport:
    return
  
  # Clear previous indicators
  _clear_active_indicators()
  
  # Get all enemies
  var enemies = enemy_spawner.current_enemies
  if enemies.is_empty():
    return
  
  # Create individual indicators for each offscreen enemy
  for enemy in enemies:
    if not enemy or not is_instance_valid(enemy):
      continue
      
    var screen_pos = camera.unproject_position(enemy.global_position)
    var viewport_size = viewport.get_visible_rect().size
    
    # Check if enemy is offscreen
    if _is_enemy_offscreen(screen_pos, viewport_size):
      _create_individual_indicator(enemy, screen_pos, viewport_size)

func _is_enemy_offscreen(screen_pos: Vector2, viewport_size: Vector2) -> bool:
  return (screen_pos.x < 0 or screen_pos.x > viewport_size.x or
          screen_pos.y < 0 or screen_pos.y > viewport_size.y)

func _create_individual_indicator(_enemy: Node3D, screen_pos: Vector2, viewport_size: Vector2) -> void:
  # Get or create indicator
  var indicator = _get_indicator_from_pool()
  if not indicator:
    indicator = _create_new_dot_indicator()
  
  # Position indicator on screen edge based on enemy direction
  var edge_pos = _calculate_edge_position(screen_pos, viewport_size)
  indicator.position = edge_pos
  
  # Add to active indicators
  active_indicators.append(indicator)
  indicator.visible = true
  
func _calculate_edge_position(screen_pos: Vector2, viewport_size: Vector2) -> Vector2:
  var edge_pos = Vector2.ZERO
  
  # Determine which edge the enemy is closest to and position indicator there
  var center = viewport_size * 0.5
  var direction = (screen_pos - center).normalized()
  
  # Calculate intersection with viewport edges
  if abs(direction.x) > abs(direction.y):
    # Enemy is more to the left/right
    if direction.x > 0:
      # Right edge
      edge_pos.x = viewport_size.x - indicator_margin
      edge_pos.y = clamp(center.y + direction.y * (viewport_size.x * 0.5),
                         indicator_margin, viewport_size.y - indicator_margin)
    else:
      # Left edge
      edge_pos.x = indicator_margin
      edge_pos.y = clamp(center.y + direction.y * (viewport_size.x * 0.5),
                         indicator_margin, viewport_size.y - indicator_margin)
  else:
    # Enemy is more to the top/bottom
    if direction.y > 0:
      # Bottom edge
      edge_pos.y = viewport_size.y - indicator_margin
      edge_pos.x = clamp(center.x + direction.x * (viewport_size.y * 0.5),
                         indicator_margin, viewport_size.x - indicator_margin)
    else:
      # Top edge
      edge_pos.y = indicator_margin
      edge_pos.x = clamp(center.x + direction.x * (viewport_size.y * 0.5),
                         indicator_margin, viewport_size.x - indicator_margin)
  
  return edge_pos

func _get_indicator_from_pool() -> Control:
  if indicator_pool.size() > 0:
    return indicator_pool.pop_back()
  return null

func _create_new_dot_indicator() -> Control:
  var indicator = Control.new()
  indicator.set_size(indicator_size)
  
  # Create circular dot panel
  var panel = TextureRect.new()
  panel.texture = indicator_texture
  panel.set_size(indicator_size)
  panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  
  # Make it circular by setting border radius (if supported) or use a simple colored rectangle
  indicator.add_child(panel)
  
  add_child(indicator)
  _animate_indicator(indicator)
  return indicator

func _clear_active_indicators() -> void:
  for indicator in active_indicators:
    indicator.visible = false
    # Return to pool for reuse
    indicator_pool.append(indicator)
  
  active_indicators.clear()

func _animate_indicator(indicator: Control) -> void:
  # Create a subtle pulsing animation
  var tween = create_tween()
  tween.set_loops()
  tween.tween_property(indicator, "modulate:a", 1, 0.5)
  tween.tween_property(indicator, "modulate:a", 0.5, 0.5)
