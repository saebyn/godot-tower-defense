extends Node3D
class_name PlaceableObstacle

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var health: Health = $Health

var health_display: HealthDisplay

func _ready():
  # Connect health signals
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)
  
  # Set up health display (deferred to avoid await in _ready)
  _setup_health_display.call_deferred()

func _setup_health_display():
  # Wait a frame to ensure the scene tree is properly set up
  await get_tree().process_frame
  
  # Find the main camera from the scene
  var main_camera = get_viewport().get_camera_3d()
  if main_camera and health:
    # Load and instantiate the health display
    var health_display_scene = preload("res://health_display.tscn")
    health_display = health_display_scene.instantiate()
    
    # Add to the main scene's UI layer
    var main_scene = get_tree().current_scene
    if main_scene.has_node("UI"):
      main_scene.get_node("UI").add_child(health_display)
      health_display.setup(health, main_camera, self)
    else:
      print("Warning: No UI node found in main scene for health display")

func _on_died():
  print("Obstacle destroyed")
  # Clean up health display
  if health_display:
    health_display.queue_free()
  queue_free()

func _on_health_damaged(amount: int, hitpoints: int) -> void:
  print("Obstacle took ", amount, " damage. Remaining HP: ", hitpoints)


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