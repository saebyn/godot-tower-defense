extends Node3D
class_name PlaceableObstacle

@export_group("Cost Settings")
@export var cost: int = 10 ## Currency cost to place this obstacle

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var health: Health = $Health

func _ready():
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

func _on_died():
  Logger.info("Obstacle", "Obstacle destroyed")
  queue_free()

func _on_health_damaged(amount: int, hitpoints: int) -> void:
  Logger.debug("Obstacle.Combat", "Obstacle took %d damage. Remaining HP: %d" % [amount, hitpoints])


func place(navigation_region: NavigationRegion3D) -> void:
    if not is_inside_tree():
        Logger.error("Obstacle", "PlaceableObstacle must be added to the scene tree before placing.")
        return

    Logger.info("Obstacle", "Placing obstacle at: %s" % global_position)
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