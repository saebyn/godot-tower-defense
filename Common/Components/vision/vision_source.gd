extends Node
class_name VisionSource

signal vision_changed(source: Node)

@export var vision_range: float = 10.0
@export var active: bool = true: set = set_active
@export var show_debug_range: bool = false

var fog_of_war: FogOfWar
var debug_mesh: MeshInstance3D

func _ready():
  # Find the FogOfWar node in the scene
  fog_of_war = get_tree().get_first_node_in_group("fog_of_war")
  if fog_of_war:
    register_with_fog_system()

  # Create debug visualization if enabled
  if show_debug_range:
    # Wait a bit for the parent to be fully set up
    await get_tree().process_frame
    create_debug_visualization()

func create_debug_visualization():
  var parent = get_parent()
  if not parent is Node3D:
    print("Warning: VisionSource parent is not Node3D, cannot create debug visualization")
    return

  print("Creating debug visualization for VisionSource with range: ", vision_range)
  
  # Create a simple ring to show vision range
  debug_mesh = MeshInstance3D.new()
  var ring_mesh = create_simple_ring()
  debug_mesh.mesh = ring_mesh
  debug_mesh.name = "VisionRangeDebug"

  # Create bright green material for visibility - but only on terrain
  var material = StandardMaterial3D.new()
  material.flags_transparent = true
  material.flags_unshaded = true # Make it always visible
  material.albedo_color = Color(0, 1, 0, 0.4) # Bright green with moderate opacity
  material.cull_mode = BaseMaterial3D.CULL_DISABLED # Visible from both sides
  material.no_depth_test = false # Use normal depth testing so it doesn't overlay obstacles
  material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY # Proper depth handling
  debug_mesh.set_surface_override_material(0, material)

  parent.add_child(debug_mesh)
  debug_mesh.position = Vector3(0, 0.05, 0) # Very close to ground to avoid appearing on obstacles
  
  print("Debug ring created successfully at position: ", debug_mesh.global_position)

func create_simple_ring() -> ArrayMesh:
  # Create a simple ring mesh for vision range visualization
  var array_mesh = ArrayMesh.new()
  var arrays = []
  arrays.resize(Mesh.ARRAY_MAX)

  var vertices = PackedVector3Array()
  var indices = PackedInt32Array()
  var normals = PackedVector3Array()

  var segments = 32
  var inner_radius = vision_range * 0.95
  var outer_radius = vision_range * 1.05

  # Create ring vertices
  for i in range(segments):
    var angle = i * 2.0 * PI / segments
    var cos_a = cos(angle)
    var sin_a = sin(angle)

    # Inner vertex
    vertices.append(Vector3(cos_a * inner_radius, 0, sin_a * inner_radius))
    normals.append(Vector3(0, 1, 0))
    
    # Outer vertex
    vertices.append(Vector3(cos_a * outer_radius, 0, sin_a * outer_radius))
    normals.append(Vector3(0, 1, 0))

  # Create indices for triangles
  for i in range(segments):
    var next = (i + 1) % segments
    var base = i * 2
    var next_base = next * 2

    # Two triangles per segment to form the ring
    indices.append_array([base, next_base, base + 1])
    indices.append_array([base + 1, next_base, next_base + 1])

  arrays[Mesh.ARRAY_VERTEX] = vertices
  arrays[Mesh.ARRAY_INDEX] = indices
  arrays[Mesh.ARRAY_NORMAL] = normals

  array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
  return array_mesh

func set_active(value: bool):
  if active != value:
    active = value
    if fog_of_war:
      if active:
        fog_of_war.add_vision_source(self)
      else:
        fog_of_war.remove_vision_source(self)
    vision_changed.emit(self)

func register_with_fog_system():
  if active and fog_of_war:
    fog_of_war.add_vision_source(self)
    print("VisionSource registered with fog system. Range: ", vision_range, " Debug enabled: ", show_debug_range)

func unregister_from_fog_system():
  if fog_of_war:
    fog_of_war.remove_vision_source(self)

func _exit_tree():
  unregister_from_fog_system()
  if debug_mesh and is_instance_valid(debug_mesh):
    debug_mesh.queue_free()

func get_world_position() -> Vector3:
  var parent = get_parent()
  if parent and parent is Node3D:
    return parent.global_position
  return Vector3.ZERO
