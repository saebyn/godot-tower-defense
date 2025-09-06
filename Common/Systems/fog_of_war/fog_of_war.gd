extends Node3D
class_name FogOfWar

signal fog_updated(revealed_cells: Array[Vector2i])

@export_group("Fog Settings")
@export var grid_size: float = 2.0 # Size of each fog cell in world units
@export var map_width: int = 125 # Map width in grid cells
@export var map_height: int = 125 # Map height in grid cells
@export var map_center: Vector3 = Vector3(17.678, 0, 7.322) # Center of the map
@export var default_vision_range: float = 10.0 # Default vision range for sources

@export_group("Visual Settings")
@export var fog_color: Color = Color(0, 0, 0, 0.8)
@export var explored_color: Color = Color(0, 0, 0, 0.4)

@export_group("Debug Settings")
@export var debug_enabled: bool = false
@export var show_grid: bool = false

# Fog state for each cell: 0 = unexplored, 1 = explored, 2 = visible
var fog_grid: Array[Array] = []
var vision_sources: Array[Node] = []

@onready var fog_overlay: MeshInstance3D = $FogOverlay

func _ready():
  print("FogOfWar system initializing...")
  initialize_fog_grid()
  create_fog_overlay()
  print("FogOfWar system ready. Grid size: ", map_width, "x", map_height, " Cell size: ", grid_size)

func initialize_fog_grid():
  fog_grid.clear()
  for x in range(map_width):
    var column: Array[int] = []
    for y in range(map_height):
      column.append(0) # Start all cells as unexplored
    fog_grid.append(column)

func create_fog_overlay():
  # Create a quad mesh for the fog overlay
  fog_overlay.mesh.size = Vector2(map_width * grid_size, map_height * grid_size)
  # Position the overlay to match the ground
  fog_overlay.position = Vector3(
    map_center.x,
    map_center.y + 0.1, # Slightly above ground to avoid z-fighting
    map_center.z
  )
  fog_overlay.rotation_degrees = Vector3(-90, 0, 0) # Rotate to be horizontal

  # Create material for fog rendering - unshaded to avoid specular highlights
  var material = StandardMaterial3D.new()
  material.flags_transparent = true
  material.flags_unshaded = true # Remove lighting effects
  material.no_depth_test = false
  material.cull_mode = BaseMaterial3D.CULL_DISABLED # Visible from both sides
  material.albedo_color = fog_color
  fog_overlay.set_surface_override_material(0, material)

func add_vision_source(source: Node):
  await ready
  if source not in vision_sources:
    vision_sources.append(source)
    print("Added vision source. Total sources: ", vision_sources.size())
    update_fog()
  else:
    print("Vision source already registered")

func remove_vision_source(source: Node):
  if source in vision_sources:
    vision_sources.erase(source)
    update_fog()

func update_fog():
  # Reset all cells to explored (if they were visible before)
  for x in range(map_width):
    for y in range(map_height):
      if fog_grid[x][y] == 2: # Was visible
        fog_grid[x][y] = 1 # Now just explored

  # Calculate visibility from all sources
  var newly_visible_cells: Array[Vector2i] = []
  for source in vision_sources:
    if is_instance_valid(source) and is_instance_valid(source.get_parent()):
      var visible_cells = calculate_vision_area(source)
      for cell in visible_cells:
        if is_valid_cell(cell):
          fog_grid[cell.x][cell.y] = 2 # Mark as visible
          newly_visible_cells.append(cell)

  if debug_enabled:
    print("Fog update: ", vision_sources.size(), " sources, ", newly_visible_cells.size(), " newly visible cells")

  update_fog_visual()
  fog_updated.emit(newly_visible_cells)

func calculate_vision_area(source: Node) -> Array[Vector2i]:
  var visible_cells: Array[Vector2i] = []
  var source_pos = source.get_parent().global_position
  var source_cell = world_to_grid(source_pos)
  var vision_range_cells = int(source.vision_range / grid_size)

  # Simple circular vision without line-of-sight for now
  for x in range(-vision_range_cells, vision_range_cells + 1):
    for y in range(-vision_range_cells, vision_range_cells + 1):
      var cell = Vector2i(source_cell.x + x, source_cell.y + y)
      var distance = Vector2(x, y).length()

      if distance <= vision_range_cells and is_valid_cell(cell):
        visible_cells.append(cell)

  return visible_cells

func world_to_grid(world_pos: Vector3) -> Vector2i:
  # Convert world position to grid coordinates relative to map center
  var relative_pos = world_pos - map_center
  return Vector2i(
    int((relative_pos.x + (map_width * grid_size / 2.0)) / grid_size),
    int((relative_pos.z + (map_height * grid_size / 2.0)) / grid_size)
  )

func grid_to_world(grid_pos: Vector2i) -> Vector3:
  # Convert grid coordinates back to world position
  var relative_x = (grid_pos.x * grid_size) - (map_width * grid_size / 2.0) + grid_size / 2.0
  var relative_z = (grid_pos.y * grid_size) - (map_height * grid_size / 2.0) + grid_size / 2.0
  return Vector3(
    map_center.x + relative_x,
    map_center.y,
    map_center.z + relative_z
  )

func is_valid_cell(cell: Vector2i) -> bool:
  return cell.x >= 0 and cell.x < map_width and cell.y >= 0 and cell.y < map_height

func is_cell_visible(world_pos: Vector3) -> bool:
  var cell = world_to_grid(world_pos)
  if not is_valid_cell(cell):
    return false
  return fog_grid[cell.x][cell.y] == 2

func is_cell_explored(world_pos: Vector3) -> bool:
  var cell = world_to_grid(world_pos)
  if not is_valid_cell(cell):
    return false
  return fog_grid[cell.x][cell.y] >= 1

func update_fog_visual():
  # Create a more sophisticated fog overlay with proper fog-like appearance
  var material = fog_overlay.get_surface_override_material(0) as StandardMaterial3D
  if not material:
    return

  # Calculate visibility statistics
  var unexplored_count = 0
  var explored_count = 0
  var visible_count = 0
  var total_count = map_width * map_height

  for x in range(map_width):
    for y in range(map_height):
      match fog_grid[x][y]:
        0: unexplored_count += 1
        1: explored_count += 1
        2: visible_count += 1

  # Create proper fog appearance
  if visible_count > 0:
    # Areas are visible - make fog less opaque in visible regions
    # For a simple implementation, we'll reduce overall opacity when vision sources are active
    var visibility_ratio = float(visible_count) / float(total_count)
    
    # Use a darker, more fog-like color
    var fog_base_color = Color(0.1, 0.1, 0.15, 0.9) # Dark blue-gray fog
    var clear_areas_blend = Color(0.05, 0.05, 0.1, 0.3) # Much lighter for visible areas
    
    # Blend between full fog and clearer areas based on visibility
    material.albedo_color = fog_base_color.lerp(clear_areas_blend, visibility_ratio * 2.0)
  else:
    # No vision sources - full fog coverage
    material.albedo_color = Color(0.1, 0.1, 0.15, 0.95) # Nearly opaque dark fog
