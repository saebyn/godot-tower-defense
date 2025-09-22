extends Node3D
class_name ObstaclePreview

var mesh_instance: MeshInstance3D
var obstacle_type: ObstacleTypeResource
var original_material: Material

func _init(from_obstacle_type: ObstacleTypeResource):
  obstacle_type = from_obstacle_type
  _create_mesh_from_obstacle_type()

func _create_mesh_from_obstacle_type() -> void:
  # Extract just the mesh from the obstacle scene
  var temp_obstacle = obstacle_type.scene.instantiate()
  var temp_mesh = temp_obstacle.get_node("MeshInstance3D")
  
  if not temp_mesh:
    Logger.error("ObstaclePreview", "Could not find MeshInstance3D in obstacle scene: %s" % obstacle_type.name)
    temp_obstacle.queue_free()
    return
  
  # Create our own mesh instance
  mesh_instance = MeshInstance3D.new()
  mesh_instance.mesh = temp_mesh.mesh
  
  # Extract original material for restoration later
  original_material = temp_mesh.get_surface_override_material(0)
  if not original_material and temp_mesh.mesh:
    original_material = temp_mesh.mesh.surface_get_material(0)
  
  add_child(mesh_instance)
  
  # Clean up temporary obstacle
  temp_obstacle.queue_free()
  
  Logger.debug("ObstaclePreviewScene", "Created preview for obstacle: %s" % obstacle_type.name)

func set_preview_material(material: Material) -> void:
  if mesh_instance:
    mesh_instance.set_surface_override_material(0, material)

func restore_original_material() -> void:
  if mesh_instance:
    mesh_instance.set_surface_override_material(0, original_material)

func get_bounds() -> AABB:
  if mesh_instance:
    return mesh_instance.get_aabb()
  return AABB()

func get_mesh_instance() -> MeshInstance3D:
  return mesh_instance