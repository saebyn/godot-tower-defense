extends Node3D
class_name ObstaclePreview

var placement_preview_node: Node3D
var obstacle_type: ObstacleTypeResource
var original_materials: Dictionary = {}  # Maps MeshInstance3D to its original material
var placement_bounds: AABB

func _init(from_obstacle_type: ObstacleTypeResource):
  obstacle_type = from_obstacle_type
  _create_mesh_from_obstacle_type()

func _create_mesh_from_obstacle_type() -> void:
  # Extract just the mesh from the obstacle scene
  var temp_obstacle: PlaceableObstacle = obstacle_type.scene.instantiate()
  var temp_meshes = temp_obstacle.mesh_instances

  if not temp_meshes or temp_meshes.is_empty():
    Logger.error("ObstaclePreview", "Could not find MeshInstance3D in obstacle scene: %s" % obstacle_type.name)
    temp_obstacle.queue_free()
    return
  
  # Create our own mesh instances based on the temporary obstacle's meshes
  placement_preview_node = Node3D.new()
  for temp_mesh in temp_meshes:
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = temp_mesh.mesh
    mesh_instance.transform = temp_mesh.transform
    mesh_instance.scale = temp_mesh.scale

    # Extract original material for restoration later
    var original_material = temp_mesh.get_surface_override_material(0)
    if not original_material and temp_mesh.mesh:
      original_material = temp_mesh.mesh.surface_get_material(0)
    
    # Store the original material for this specific mesh instance
    original_materials[mesh_instance] = original_material

    placement_preview_node.add_child(mesh_instance)
  
  add_child(placement_preview_node)
  placement_bounds = temp_obstacle.get_aabb()
  
  # Clean up temporary obstacle
  temp_obstacle.queue_free()
  
  Logger.debug("ObstaclePreview", "Created preview for obstacle: %s" % obstacle_type.name)

func set_preview_material(material: Material) -> void:
  if placement_preview_node:
    for mesh_instance in placement_preview_node.get_children():
      if mesh_instance is MeshInstance3D:
        mesh_instance.set_surface_override_material(0, material)

func restore_original_material() -> void:
  if placement_preview_node:
    for mesh_instance in placement_preview_node.get_children():
      if mesh_instance is MeshInstance3D and mesh_instance in original_materials:
        mesh_instance.set_surface_override_material(0, original_materials[mesh_instance])

func get_bounds() -> AABB:
  return placement_bounds

func get_mesh_instance() -> MeshInstance3D:
  if placement_preview_node:
    for mesh_instance in placement_preview_node.get_children():
      if mesh_instance is MeshInstance3D:
        return mesh_instance
  return null
