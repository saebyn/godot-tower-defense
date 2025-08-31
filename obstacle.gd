extends Node3D
class_name PlaceableObstacle

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D


func place(navigation_region: NavigationRegion3D) -> void:
    if not is_inside_tree():
        print("PlaceableObstacle must be added to the scene tree before placing.")
        return

    print("Placing obstacle at: ", global_position)
    # Here you would implement the logic to finalize the placement of the obstacle
    var obstacle := NavigationObstacle3D.new()

    obstacle.affect_navigation_mesh = true
    obstacle.global_transform = global_transform

    # set the vertices based on the mesh size
    var aabb = mesh_instance.get_aabb()
    var size = aabb.size / 2.0
    obstacle.vertices = PackedVector3Array([
        Vector3(-size.x, 0, -size.z),
        Vector3(size.x, 0, -size.z),
        Vector3(size.x, 0, size.z),
        Vector3(-size.x, 0, size.z)
    ])

    navigation_region.add_child(obstacle)