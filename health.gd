extends Node
class_name Health

@export var hitpoints: int = 100
@export var ui_path: NodePath = NodePath("UI")

var max_hitpoints: int
var dead: bool = false
var health_display: HealthDisplay

signal died
signal damaged(amount: int, hitpoints: int)

func take_damage(amount: int):
  hitpoints -= amount
  damaged.emit(amount, hitpoints)
  if hitpoints <= 0:
    die()


func _ready():
  # Store the initial hitpoints as max_hitpoints
  max_hitpoints = hitpoints
  
  # Set up health display (deferred to avoid await in _ready)
  _setup_health_display.call_deferred()


func _setup_health_display():
  # Wait a frame to ensure the scene tree is properly set up
  await get_tree().process_frame
  
  # Find the main camera from the scene
  var main_camera = get_viewport().get_camera_3d()
  if main_camera:
    # Load and instantiate the health display
    var health_display_scene = preload("res://health_display.tscn")
    health_display = health_display_scene.instantiate()
    
    # Add to the main scene's UI layer
    var main_scene = get_tree().current_scene
    var ui = main_scene.get_node(ui_path)
    ui.add_child(health_display)
    health_display.setup(self, main_camera, get_parent())

func die():
  if dead:
    return
  dead = true
  
  # Clean up health display
  if health_display:
    health_display.queue_free()
  
  died.emit()
