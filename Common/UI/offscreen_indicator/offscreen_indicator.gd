extends Control
class_name OffscreenIndicator

## UI component that displays indicators for enemies outside the viewport
## Shows direction and count of offscreen enemies at screen edges

@export var indicator_margin: float = 20.0 ## Distance from screen edge to place indicators
@export var indicator_size: Vector2 = Vector2(40, 40) ## Size of individual indicators
@export var update_interval: float = 0.1 ## How often to update indicator positions
@export var max_indicators_per_edge: int = 5 ## Maximum indicators per screen edge

@onready var camera: Camera3D
@onready var enemy_spawner: EnemySpawner

# Indicator pools for reuse
var indicator_pools: Dictionary = {}
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
  
  # Initialize indicator pools
  _initialize_indicator_pools()

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

func _initialize_indicator_pools() -> void:
  # Create pools for different edge directions
  indicator_pools["top"] = []
  indicator_pools["bottom"] = []
  indicator_pools["left"] = []
  indicator_pools["right"] = []

func _update_indicators() -> void:
  if not camera or not enemy_spawner:
    return
  
  # Clear previous indicators
  _clear_active_indicators()
  
  # Get all enemies
  var enemies = enemy_spawner.current_enemies
  if enemies.is_empty():
    return
  
  Logger.debug("OffscreenIndicator", "Checking %d enemies for offscreen indicators" % enemies.size())
  
  # Group enemies by screen edge direction
  var edge_groups = _group_enemies_by_edge(enemies)
  
  # Create indicators for each edge
  for edge in edge_groups:
    var enemy_group = edge_groups[edge]
    if enemy_group.size() > 0:
      Logger.debug("OffscreenIndicator", "Creating indicator for %s edge with %d enemies" % [edge, enemy_group.size()])
      _create_edge_indicator(edge, enemy_group)

func _group_enemies_by_edge(enemies: Array[Node3D]) -> Dictionary:
  var edge_groups = {
    "top": [],
    "bottom": [],
    "left": [],
    "right": []
  }
  
  var viewport_size = get_viewport().get_visible_rect().size
  Logger.debug("OffscreenIndicator", "Viewport size: %s" % viewport_size)
  
  for enemy in enemies:
    if not enemy or not is_instance_valid(enemy):
      continue
    
    # Convert enemy world position to screen position
    var screen_pos = camera.unproject_position(enemy.global_position)
    Logger.debug("OffscreenIndicator", "Enemy at world %s -> screen %s" % [enemy.global_position, screen_pos])
    
    # Check if enemy is offscreen and determine which edge
    var is_offscreen = false
    var edge = ""
    
    if screen_pos.x < 0:
      edge = "left"
      is_offscreen = true
    elif screen_pos.x > viewport_size.x:
      edge = "right"
      is_offscreen = true
    elif screen_pos.y < 0:
      edge = "top"
      is_offscreen = true
    elif screen_pos.y > viewport_size.y:
      edge = "bottom"
      is_offscreen = true
    
    if is_offscreen:
      Logger.debug("OffscreenIndicator", "Enemy offscreen on %s edge" % edge)
      edge_groups[edge].append(enemy)
  
  return edge_groups

func _create_edge_indicator(edge: String, enemies: Array) -> void:
  if enemies.is_empty():
    return
  
  # Get or create indicator for this edge
  var indicator = _get_indicator_from_pool(edge)
  if not indicator:
    indicator = _create_new_indicator(edge)
  
  # Update indicator content
  _update_indicator_content(indicator, enemies)
  
  # Position indicator on edge
  _position_indicator_on_edge(indicator, edge, enemies)
  
  # Add to active indicators
  active_indicators.append(indicator)
  indicator.visible = true

func _get_indicator_from_pool(edge: String) -> Control:
  var pool = indicator_pools[edge]
  if pool.size() > 0:
    return pool.pop_back()
  return null

func _create_new_indicator(edge: String) -> Control:
  var indicator = Control.new()
  indicator.set_size(indicator_size)
  
  # Add background panel
  var panel = Panel.new()
  panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  indicator.add_child(panel)
  
  # Add arrow label
  var arrow_label = Label.new()
  arrow_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
  arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  arrow_label.name = "ArrowLabel"
  arrow_label.text = _get_arrow_for_edge(edge)
  indicator.add_child(arrow_label)
  
  # Add count label
  var count_label = Label.new()
  count_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
  count_label.offset_left = -15
  count_label.offset_top = -5
  count_label.offset_right = 0
  count_label.offset_bottom = 15
  count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  count_label.name = "CountLabel"
  count_label.modulate = Color.YELLOW
  indicator.add_child(count_label)
  
  add_child(indicator)
  return indicator

func _get_arrow_for_edge(edge: String) -> String:
  match edge:
    "top":
      return "↑"
    "bottom":
      return "↓"
    "left":
      return "←"
    "right":
      return "→"
    _:
      return "•"

func _update_indicator_content(indicator: Control, enemies: Array) -> void:
  # Update count
  var count_label = indicator.get_node("CountLabel")
  if count_label:
    count_label.text = str(enemies.size())

func _position_indicator_on_edge(indicator: Control, edge: String, enemies: Array) -> void:
  var viewport_size = get_viewport().get_visible_rect().size
  var indicator_pos = Vector2.ZERO
  
  # Calculate average position of enemies for this edge
  var avg_screen_pos = Vector2.ZERO
  for enemy in enemies:
    if enemy and is_instance_valid(enemy):
      avg_screen_pos += camera.unproject_position(enemy.global_position)
  avg_screen_pos /= enemies.size()
  
  # Position indicator based on edge
  match edge:
    "top":
      indicator_pos.x = clamp(avg_screen_pos.x - indicator_size.x / 2, indicator_margin, viewport_size.x - indicator_size.x - indicator_margin)
      indicator_pos.y = indicator_margin
    "bottom":
      indicator_pos.x = clamp(avg_screen_pos.x - indicator_size.x / 2, indicator_margin, viewport_size.x - indicator_size.x - indicator_margin)
      indicator_pos.y = viewport_size.y - indicator_size.y - indicator_margin
    "left":
      indicator_pos.x = indicator_margin
      indicator_pos.y = clamp(avg_screen_pos.y - indicator_size.y / 2, indicator_margin, viewport_size.y - indicator_size.y - indicator_margin)
    "right":
      indicator_pos.x = viewport_size.x - indicator_size.x - indicator_margin
      indicator_pos.y = clamp(avg_screen_pos.y - indicator_size.y / 2, indicator_margin, viewport_size.y - indicator_size.y - indicator_margin)
  
  indicator.position = indicator_pos

func _clear_active_indicators() -> void:
  for indicator in active_indicators:
    indicator.visible = false
    # Return to pool for reuse
    var edge = _determine_indicator_edge(indicator)
    if edge != "":
      indicator_pools[edge].append(indicator)
  
  active_indicators.clear()

func _determine_indicator_edge(indicator: Control) -> String:
  # Determine which edge this indicator belongs to based on position
  var viewport_size = get_viewport().get_visible_rect().size
  var pos = indicator.position
  
  if pos.y <= indicator_margin * 2:
    return "top"
  elif pos.y >= viewport_size.y - indicator_size.y - indicator_margin * 2:
    return "bottom"
  elif pos.x <= indicator_margin * 2:
    return "left"
  elif pos.x >= viewport_size.x - indicator_size.x - indicator_margin * 2:
    return "right"
  
  return ""