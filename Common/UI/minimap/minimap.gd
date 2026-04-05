## Minimap
##
## A minimap UI component that shows an overhead view of the game area.
## Displays enemy positions, buildings, and survivor positions.
##
## Uses CanvasItem _draw() / queue_redraw() for efficient rendering —
## no child nodes are created per-frame.
##
## Usage:
## - Add as child to main UI scene
## - Automatically finds game components via groups
## - Configurable through exported properties
extends Control
class_name UI_Minimap

@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.8) ## Background color
@export var enemy_color: Color = Color.RED ## Color for enemy dots
@export var building_color: Color = Color.GRAY ## Color for building markers
@export var survivor_color: Color = Color.GREEN ## Color for survivor markers
@export var enemy_dot_radius: float = 2.0 ## Radius of enemy dots on minimap
@export var update_interval: float = 0.2 ## How often to redraw the minimap
@export var building_half_size: Vector2 = Vector2(2, 2) ## Half-size of building markers
@export var survivor_half_size: Vector2 = Vector2(3, 3) ## Half-size of survivor markers

@onready var update_timer := $Timer

# Game world bounds
# AABB uses (position, size), so this fallback spans X/Z from -200 to 200
# until Scenario bounds are provided via update_world_bounds().
var world_bounds: AABB = AABB(Vector3(-200, 0, -200), Vector3(400, 10, 400))

# Cached references (lazily refreshed when null/invalid)
var _enemy_spawner: System_EnemySpawner = null

# Snapshot data built during _on_timer_timeout, consumed in _draw()
var _enemy_positions: Array[Vector2] = []
var _building_positions: Array[Vector2] = []
var _survivor_positions: Array[Vector2] = []


func _ready() -> void:
  update_timer.wait_time = update_interval


## Called by the Scenario/Stage to set the visible world area.
func update_world_bounds(new_bounds: AABB) -> void:
  MyLogger.info("Minimap", "Updating world bounds: position=%s, size=%s" % [new_bounds.position, new_bounds.size])
  world_bounds = new_bounds
  queue_redraw()


## Timer callback: refresh data snapshot then request a redraw.
func _on_timer_timeout() -> void:
  _refresh_snapshot()
  queue_redraw()


## Collect current world-space positions and project them to minimap space.
func _refresh_snapshot() -> void:
  _enemy_positions.clear()
  _building_positions.clear()
  _survivor_positions.clear()

  # --- Enemies ---
  if not _enemy_spawner or not is_instance_valid(_enemy_spawner):
    _enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner") as System_EnemySpawner
  if _enemy_spawner:
    for enemy in _enemy_spawner.current_enemies:
      if enemy and is_instance_valid(enemy):
        _enemy_positions.append(_world_to_minimap(enemy.global_position))

  # --- Buildings ---
  for building in get_tree().get_nodes_in_group("buildings"):
    if building is Node3D:
      _building_positions.append(_world_to_minimap(building.global_position))

  # --- Survivors ---
  for survivor in get_tree().get_nodes_in_group("survivors"):
    if survivor is Node3D:
      _survivor_positions.append(_world_to_minimap(survivor.global_position))


## CanvasItem draw callback — all rendering happens here, zero extra nodes.
func _draw() -> void:
  var rect := Rect2(Vector2.ZERO, size)

  # Background
  draw_rect(rect, background_color)

  # Buildings (filled rectangles)
  for pos in _building_positions:
    draw_rect(Rect2(pos - building_half_size, building_half_size * 2), building_color)

  # Survivors (filled rectangles)
  for pos in _survivor_positions:
    draw_rect(Rect2(pos - survivor_half_size, survivor_half_size * 2), survivor_color)

  # Enemies (filled circles)
  for pos in _enemy_positions:
    draw_circle(pos, enemy_dot_radius, enemy_color)


func _world_to_minimap(world_pos: Vector3) -> Vector2:
  # Map X/Z world coordinates to the Control's local 2D space.
  var normalized_x := (world_pos.x - world_bounds.position.x) / world_bounds.size.x
  var normalized_z := (world_pos.z - world_bounds.position.z) / world_bounds.size.z
  return Vector2(
    clampf(normalized_x * size.x, 0.0, size.x),
    clampf(normalized_z * size.y, 0.0, size.y)
  )


func _minimap_to_world(minimap_pos: Vector2) -> Vector3:
  # Inverse of _world_to_minimap; Y is kept at ground level.
  var normalized_x := minimap_pos.x / size.x
  var normalized_z := minimap_pos.y / size.y
  return Vector3(
    world_bounds.position.x + normalized_x * world_bounds.size.x,
    0.0,
    world_bounds.position.z + normalized_z * world_bounds.size.z
  )
