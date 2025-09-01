extends MeshInstance3D

@onready var health: Health = $Health
var health_display: HealthDisplay

func _ready():
  # Connect health signals  
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)
  
  # Set up health display
  _setup_health_display()

func _setup_health_display():
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
      health_display.setup(health, main_camera)

func _on_died():
  print("Target has died.")
  # Clean up health display
  if health_display:
    health_display.queue_free()
  queue_free() # Remove the target from the scene when it dies.


func _on_health_damaged(amount: float, hitpoints: int) -> void:
  print("Enemy took ", amount, " damage. Remaining HP: ", hitpoints)
