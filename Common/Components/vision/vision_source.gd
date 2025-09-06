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
    create_debug_visualization()

func create_debug_visualization():
  var parent = get_parent()
  if not parent is Node3D:
    return

  # Create a simple ring to show vision range
  debug_mesh = MeshInstance3D.new()
  var ring_mesh = create_simple_ring()
  debug_mesh.mesh = ring_mesh

  # Create material
  var material = StandardMaterial3D.new()
  material.flags_transparent = true
  material.albedo_color = Color(0, 1, 0, 0.3)
  material.flags_unshaded = true
  debug_mesh.set_surface_override_material(0, material)

  parent.add_child(debug_mesh)
  debug_mesh.position.y = 0.1

func create_simple_ring() -> ArrayMesh:
  # Create a simple ring mesh for vision range visualization
  var array_mesh = ArrayMesh.new()
  var arrays = []
  arrays.resize(Mesh.ARRAY_MAX)

  var vertices = PackedVector3Array()
  var indices = PackedInt32Array()

  var segments = 32
  var inner_radius = vision_range * 0.9
  var outer_radius = vision_range

  # Create ring vertices
  for i in range(segments):
    var angle = i * 2.0 * PI / segments
    var cos_a = cos(angle)
    var sin_a = sin(angle)

    vertices.append(Vector3(cos_a * inner_radius, 0, sin_a * inner_radius))
    vertices.append(Vector3(cos_a * outer_radius, 0, sin_a * outer_radius))

  # Create indices for triangles
  for i in range(segments):
    var next = (i + 1) % segments
    var base = i * 2
    var next_base = next * 2

    # Two triangles per segment
    indices.append_array([base, next_base, base + 1])
    indices.append_array([base + 1, next_base, next_base + 1])

  arrays[Mesh.ARRAY_VERTEX] = vertices
  arrays[Mesh.ARRAY_INDEX] = indices

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
