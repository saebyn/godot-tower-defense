## BuffLineEffect.gd
## Visual component that draws lines from buff buildings to buffed targets
## Shows active buff connections with color-coded, pulsing lines

class_name Component_BuffLineEffect
extends Node3D

## Base opacity for buff lines (pulsing animation adds variation)
@export_range(0.0, 1.0) var line_opacity: float = 0.6

## Speed of pulsing animation (higher = faster pulse)
@export var pulse_speed: float = 3.0

## Line width (achieved by drawing multiple parallel lines)
@export_range(0.0, 1.0) var line_width: float = 0.15

## Vertical offset from buff tower's position (start of line)
@export var line_offset_start: float = 0.1

## Vertical offset at target building's position (end of line)
@export var line_offset_end: float = 0.1

## Update interval in seconds (0 = every frame, 0.1 = 10fps for performance)
@export var update_interval: float = 0.0

## Optional color override (uses buff type color if transparent)
@export var override_color: Color = Color.TRANSPARENT

## Maximum number of lines to draw (helps reduce visual clutter)
@export var max_lines_displayed: int = 16

var mesh_instance: MeshInstance3D
var material: StandardMaterial3D
var buff_building: Entity_BuffBuilding
var time_since_update: float = 0.0

func _ready():
  buff_building = get_parent() as Entity_BuffBuilding
  if not buff_building:
    MyLogger.error("BuffLineEffect", "Parent must be Entity_BuffBuilding")
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
  material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED # Don't write to depth buffer
  material.disable_receive_shadows = true
  
  # Render behind other objects (lower render priority)
  material.render_priority = -10
  
  mesh_instance.material_override = material
  mesh_instance.layers = 1 # Ensure it's on default render layer
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
  
  # Get currently buffed buildings
  var buffed_buildings = _get_buffed_buildings()
  
  if buffed_buildings.is_empty():
    return
  
  # Limit displayed lines to reduce visual clutter
  var buildings_to_draw = buffed_buildings
  if buffed_buildings.size() > max_lines_displayed:
    # Sort by distance, show closest ones
    buffed_buildings.sort_custom(func(a, b):
      return buff_building.global_position.distance_squared_to(a.global_position) < \
           buff_building.global_position.distance_squared_to(b.global_position)
    )
    buildings_to_draw = buffed_buildings.slice(0, max_lines_displayed)
  
  im.surface_begin(Mesh.PRIMITIVE_LINES, material)
  
  for building in buildings_to_draw:
    _draw_line_to_building(im, building)
  
  im.surface_end()

func _get_buffed_buildings() -> Array:
  var results = []
  var buildings = get_tree().get_nodes_in_group(Entity_PlaceableBuilding.BUILDING_GROUP)
  
  for building in buildings:
    if building == buff_building:
      continue
    if not is_instance_valid(building):
      continue
    if building is not Entity_PlaceableBuilding:
      continue
    
    var distance = buff_building.global_position.distance_to(building.global_position)
    if distance <= buff_building.effect_range:
      # Verify building actually has our buff
      if building.buffs.has(buff_building.get_instance_id()):
        results.append(building)
  
  return results

func _draw_line_to_building(im: ImmediateMesh, building: Node3D):
  var start_pos = buff_building.global_position
  var end_pos = building.global_position
  
  # Project to ground plane (low Y value)
  start_pos.y = line_offset_start
  end_pos.y = line_offset_end
  
  var color = _get_buff_color()
  var alpha = _calculate_alpha()
  var final_color = Color(color.r, color.g, color.b, alpha)
  
  # Draw main line
  im.surface_set_color(final_color)
  im.surface_add_vertex(to_local(start_pos))
  im.surface_add_vertex(to_local(end_pos))
  
  # Draw parallel lines for width (if width > 0)
  if line_width > 0.01:
    var direction = (end_pos - start_pos).normalized()
    var perpendicular = Vector3(-direction.z, 0, direction.x) * line_width
    
    # Left parallel line
    im.surface_set_color(final_color)
    im.surface_add_vertex(to_local(start_pos + perpendicular))
    im.surface_add_vertex(to_local(end_pos + perpendicular))
    
    # Right parallel line
    im.surface_set_color(final_color)
    im.surface_add_vertex(to_local(start_pos - perpendicular))
    im.surface_add_vertex(to_local(end_pos - perpendicular))

func _get_buff_color() -> Color:
  # Use override color if specified
  if override_color.a > 0.0:
    return override_color
  
  # Otherwise use buff type color
  match buff_building.buff_type:
    Entity_BuffBuilding.BuffType.ATTACK_SPEED:
      return Color(0.949, 0.655, 0.353) # Orange
    Entity_BuffBuilding.BuffType.DAMAGE:
      return Color(0.42, 0.549, 0.369) # Zombie Green
    Entity_BuffBuilding.BuffType.RANGE:
      return Color(0.18, 0.8, 0.44) # Economy Green
    _:
      return Color.WHITE

func _calculate_alpha() -> float:
  # Pulsing effect based on time
  var time_factor = Time.get_ticks_msec() * 0.001 * pulse_speed
  var pulse = sin(time_factor) * 0.2
  return clamp(line_opacity + pulse, 0.0, 1.0)
