extends Node3D
class_name PlaceableObstacle


func place(navigation_region: NavigationRegion3D) -> void:
    if not is_inside_tree():
        print("PlaceableObstacle must be added to the scene tree before placing.")
        return

    print("Placing obstacle at: ", global_position)
    # Here you would implement the logic to finalize the placement of the obstacle


func create_obstacle(spawn_pos: Vector3):
  # Create obstacle manually
  var obstacle = NavigationObstacle3D.new()
  var mesh_instance = MeshInstance3D.new()
  var box_mesh = BoxMesh.new()
  box_mesh.size = Vector3(5, 2, 5) # TODO get the mesh info from the obstacle
  mesh_instance.mesh = box_mesh
  
  # Set obstacle vertices from the collision shape
  var size = Vector3(2.5, 0, 2.5)
  obstacle.vertices = PackedVector3Array([
    Vector3(-size.x, 0, -size.z),
    Vector3(size.x, 0, -size.z),
    Vector3(size.x, 0, size.z),
    Vector3(-size.x, 0, size.z)
  ])
  
  obstacle.global_position = spawn_pos
  #navigation_region.add_child(obstacle)

  # create collision shape (won't use this, just enable collision)
  var collision_shape = CollisionShape3D.new()
  collision_shape.shape = BoxShape3D.new()
  collision_shape.shape.size = size
  collision_shape.global_position = spawn_pos
  obstacle.add_child(collision_shape)
  print("Spawned debug obstacle at: ", spawn_pos)
