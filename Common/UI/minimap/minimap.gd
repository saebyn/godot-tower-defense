## Minimap
## 
## A minimap UI component that shows an overhead view of the game area.
## Displays enemy positions, buildings, and the player's camera view area.
## 
## Features:
## - Top-down view of the entire game area
## - Real-time enemy position tracking
## - Building and survivor display
## - Configurable size and position
## 
## Usage:
## - Add as child to main UI scene
## - Automatically finds game components
## - Configurable through exported properties
extends Control
class_name UI_Minimap

@export var background_color: Color = Color(0.1, 0.1, 0.1, 0.8) ## Background color
@export var enemy_color: Color = Color.RED ## Color for enemy dots
@export var building_color: Color = Color.GRAY ## Color for building markers
@export var survivor_color: Color = Color.GREEN ## Color for survivor markers
@export var enemy_dot_size: Vector2 = Vector2(3, 3) ## Size of enemy dots on minimap
@export var update_interval: float = 0.2 ## How often to update minimap
@export var building_size: Vector2 = Vector2(4, 4) ## Size of building markers
@export var survivor_size: Vector2 = Vector2(6, 6) ## Size of survivor markers

# Minimap components
@onready var background_panel := $BackgroundPanel
@onready var minimap_canvas := $MinimapCanvas
@onready var update_timer := $Timer

# Game world bounds
# AABB uses (position, size), so this fallback spans X/Z from -200 to 200
# until Scenario bounds are provided via update_world_bounds().
var world_bounds: AABB = AABB(Vector3(-200, 0, -200), Vector3(400, 10, 400))

# Cached references (lazily refreshed when null/invalid)
var _enemy_spawner: System_EnemySpawner = null

func _ready() -> void:
  # Set up background panel
  background_panel.modulate = background_color
  
  # Setup update timer
  update_timer.wait_time = update_interval
  

func update_world_bounds(new_bounds: AABB) -> void:
  MyLogger.info("Minimap", "Updating world bounds: position=%s, size=%s" % [new_bounds.position, new_bounds.size])
  world_bounds = new_bounds

func _update_minimap() -> void:
  # Clear previous elements
  _clear_minimap_canvas()
  
  # Draw enemies
  _draw_enemies()
  
  # Draw buildings and survivors (if we can find them)
  _draw_buildings_and_survivors()

func _clear_minimap_canvas() -> void:
  # Remove all child nodes from canvas (they'll be recreated)
  for child in minimap_canvas.get_children():
    child.queue_free()


func _draw_enemies() -> void:
  if not _enemy_spawner or not is_instance_valid(_enemy_spawner):
    _enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner") as System_EnemySpawner
  if not _enemy_spawner:
    return
  
  for enemy in _enemy_spawner.current_enemies:
    if not enemy or not is_instance_valid(enemy):
      continue
    
    var enemy_pos = enemy.global_position
    var minimap_pos = _world_to_minimap(enemy_pos)
    
    # Create enemy dot
    var enemy_dot = Panel.new()
    enemy_dot.set_size(enemy_dot_size)
    enemy_dot.position = minimap_pos - enemy_dot_size / 2
    enemy_dot.modulate = enemy_color
    minimap_canvas.add_child(enemy_dot)

func _draw_buildings_and_survivors() -> void:
  # Find buildings and survivors in the scene
  var buildings = get_tree().get_nodes_in_group("buildings")
  var survivors = get_tree().get_nodes_in_group("survivors")
  
  # Draw buildings
  for building in buildings:
    if building is Node3D:
      var building_pos = building.global_position
      var minimap_pos = _world_to_minimap(building_pos)
      
      var building_marker = Panel.new()
      building_marker.set_size(building_size)
      building_marker.position = minimap_pos - building_size / 2
      building_marker.modulate = building_color
      minimap_canvas.add_child(building_marker)
  
  # Draw survivors
  for survivor in survivors:
    if survivor is Node3D:
      var survivor_pos = survivor.global_position
      var minimap_pos = _world_to_minimap(survivor_pos)
      
      var survivor_marker = Panel.new()
      survivor_marker.set_size(survivor_size)
      survivor_marker.position = minimap_pos - survivor_size / 2
      survivor_marker.modulate = survivor_color
      minimap_canvas.add_child(survivor_marker)

func _world_to_minimap(world_pos: Vector3) -> Vector2:
  # Convert 3D world position to 2D minimap coordinates
  var normalized_x = (world_pos.x - world_bounds.position.x) / world_bounds.size.x
  var normalized_z = (world_pos.z - world_bounds.position.z) / world_bounds.size.z
  
  return Vector2(
    normalized_x * size.x,
    normalized_z * size.y
  )

func _minimap_to_world(minimap_pos: Vector2) -> Vector3:
  # Convert 2D minimap coordinates to 3D world position
  var normalized_x = minimap_pos.x / size.x
  var normalized_z = minimap_pos.y / size.y
  
  return Vector3(
    world_bounds.position.x + normalized_x * world_bounds.size.x,
    0, # Keep Y at ground level
    world_bounds.position.z + normalized_z * world_bounds.size.z
  )
