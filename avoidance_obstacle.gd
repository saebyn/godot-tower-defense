extends MeshInstance3D

var obstacle_rid: RID

func _ready() -> void:
  var default_map_rid: RID = get_world_3d().get_navigation_map()
  var faces := self.mesh.get_faces()
  obstacle_rid = NavigationServer3D.obstacle_create()
  NavigationServer3D.obstacle_set_map(obstacle_rid, default_map_rid)
  NavigationServer3D.obstacle_set_position(obstacle_rid, global_position)

  NavigationServer3D.obstacle_set_vertices(
    obstacle_rid,
    faces
  )
  NavigationServer3D.obstacle_set_avoidance_enabled(
    obstacle_rid,
    true
  )
  NavigationServer3D.obstacle_set_use_3d_avoidance(
    obstacle_rid,
    false
  )