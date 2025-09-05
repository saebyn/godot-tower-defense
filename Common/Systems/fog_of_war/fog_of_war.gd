extends Node3D
class_name FogOfWar

signal fog_updated(revealed_cells: Array[Vector2i])

@export_group("Fog Settings")
@export var grid_size: float = 2.0 # Size of each fog cell in world units
@export var map_width: int = 250 # Map width in grid cells
@export var map_height: int = 250 # Map height in grid cells
@export var default_vision_range: float = 10.0 # Default vision range for sources

@export_group("Visual Settings")  
@export var fog_color: Color = Color(0, 0, 0, 0.8)
@export var explored_color: Color = Color(0, 0, 0, 0.4)

# Fog state for each cell: 0 = unexplored, 1 = explored, 2 = visible
var fog_grid: Array[Array] = []
var vision_sources: Array[Node] = []

@onready var fog_overlay: MeshInstance3D = $FogOverlay

func _ready():
	initialize_fog_grid()
	create_fog_overlay()

func initialize_fog_grid():
	fog_grid.clear()
	for x in range(map_width):
		var column: Array[int] = []
		for y in range(map_height):
			column.append(0) # Start all cells as unexplored
		fog_grid.append(column)

func create_fog_overlay():
	# Create a quad mesh for the fog overlay
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(map_width * grid_size, map_height * grid_size)
	
	fog_overlay.mesh = quad_mesh
	
	# Position the overlay to cover the map
	fog_overlay.position = Vector3(
		(map_width * grid_size) / 2.0,
		0.1, # Slightly above ground to avoid z-fighting
		(map_height * grid_size) / 2.0
	)
	fog_overlay.rotation_degrees = Vector3(-90, 0, 0) # Rotate to be horizontal
	
	# Create material for fog rendering
	var material = StandardMaterial3D.new()
	material.flags_transparent = true
	material.albedo_color = fog_color
	fog_overlay.set_surface_override_material(0, material)

func add_vision_source(source: Node):
	if source not in vision_sources:
		vision_sources.append(source)
		update_fog()

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
	return Vector2i(
		int(world_pos.x / grid_size),
		int(world_pos.z / grid_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return Vector3(
		grid_pos.x * grid_size + grid_size / 2.0,
		0,
		grid_pos.y * grid_size + grid_size / 2.0
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
	# For now, just update the overall fog opacity
	# TODO: Implement more sophisticated shader-based fog rendering
	var visible_count = 0
	var total_count = map_width * map_height
	
	for x in range(map_width):
		for y in range(map_height):
			if fog_grid[x][y] == 2:
				visible_count += 1
	
	# Adjust fog opacity based on visibility
	var visibility_ratio = float(visible_count) / float(total_count)
	var material = fog_overlay.get_surface_override_material(0) as StandardMaterial3D
	if material:
		material.albedo_color.a = fog_color.a * (1.0 - visibility_ratio * 0.5)