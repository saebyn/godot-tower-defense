## BuffLineEffect.gd
## Visual component that draws lines from buff obstacles to buffed targets
## Shows active buff connections with color-coded, pulsing lines

class_name Component_BuffLineEffect
extends Node3D

## Base opacity for buff lines (pulsing animation adds variation)
@export_range(0.0, 1.0) var line_opacity: float = 0.4

## Speed of pulsing animation (higher = faster pulse)
@export var pulse_speed: float = 3.0

## Vertical offset from buff tower's position (start of line)
@export var line_offset_start: float = 1.5

## Vertical offset at target obstacle's position (end of line)
@export var line_offset_end: float = 1.0

## Update interval in seconds (0 = every frame, 0.1 = 10fps for performance)
@export var update_interval: float = 0.0

## Optional color override (uses buff type color if transparent)
@export var override_color: Color = Color.TRANSPARENT

var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var buff_obstacle: Entity_BuffObstacle
var time_since_update: float = 0.0

func _ready():
	buff_obstacle = get_parent() as Entity_BuffObstacle
	if not buff_obstacle:
		MyLogger.error("BuffLineEffect", "Parent must be Entity_BuffObstacle")
		queue_free()
		return
	
	_setup_mesh()

func _setup_mesh():
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = ImmediateMesh.new()
	
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true # Always visible through geometry
	material.disable_receive_shadows = true
	
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _process(delta):
	if update_interval > 0.0:
		time_since_update += delta
		if time_since_update >= update_interval:
			time_since_update = 0.0
			_draw_buff_lines()
	else:
		_draw_buff_lines()

func _draw_buff_lines():
	var im: ImmediateMesh = mesh_instance.mesh
	im.clear_surfaces()
	
	# Get currently buffed obstacles
	var buffed_obstacles = _get_buffed_obstacles()
	
	if buffed_obstacles.is_empty():
		return
	
	im.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	for obstacle in buffed_obstacles:
		_draw_line_to_obstacle(im, obstacle)
	
	im.surface_end()

func _get_buffed_obstacles() -> Array:
	var results = []
	var obstacles = get_tree().get_nodes_in_group(Entity_PlaceableObstacle.OBSTACLE_GROUP)
	
	for obstacle in obstacles:
		if obstacle == buff_obstacle:
			continue
		if not is_instance_valid(obstacle):
			continue
		
		var distance = buff_obstacle.global_position.distance_to(obstacle.global_position)
		if distance <= buff_obstacle.effect_range:
			# Verify obstacle actually has our buff
			if obstacle.buffs.has(buff_obstacle.get_instance_id()):
				results.append(obstacle)
	
	return results

func _draw_line_to_obstacle(im: ImmediateMesh, obstacle: Node3D):
	var start_pos = buff_obstacle.global_position
	var end_pos = obstacle.global_position
	
	# Offset vertically for visibility
	start_pos.y += line_offset_start
	end_pos.y += line_offset_end
	
	var color = _get_buff_color()
	var alpha = _calculate_alpha()
	
	im.surface_set_color(Color(color.r, color.g, color.b, alpha))
	im.surface_add_vertex(to_local(start_pos))
	im.surface_add_vertex(to_local(end_pos))

func _get_buff_color() -> Color:
	# Use override color if specified
	if override_color.a > 0.0:
		return override_color
	
	# Otherwise use buff type color
	match buff_obstacle.buff_type:
		Entity_BuffObstacle.BuffType.ATTACK_SPEED:
			return Color(0.949, 0.655, 0.353) # Orange
		Entity_BuffObstacle.BuffType.DAMAGE:
			return Color(0.42, 0.549, 0.369) # Zombie Green
		Entity_BuffObstacle.BuffType.RANGE:
			return Color(0.18, 0.8, 0.44) # Economy Green
		_:
			return Color.WHITE

func _calculate_alpha() -> float:
	# Pulsing effect based on time
	var time_factor = Time.get_ticks_msec() * 0.001 * pulse_speed
	var pulse = sin(time_factor) * 0.2
	return clamp(line_opacity + pulse, 0.0, 1.0)
