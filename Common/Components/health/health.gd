extends Node
class_name Component_Health

@export var hitpoints: int = 100
## Reference camera size at which the health bar appears at the correct size
@export var reference_camera_size: float = 65.0

@onready var health_bar := $SubViewportContainer/SubViewport/VBoxContainer/HealthBar
@onready var health_label := $SubViewportContainer/SubViewport/VBoxContainer/HealthLabel
@onready var subviewport := $SubViewportContainer/SubViewport
@onready var sprite3d := $Sprite3D

var max_hitpoints: int
var dead: bool = false
var camera: Camera3D = null
var last_camera_size: float = 0.0

signal died(damage_source: String)
signal damaged(amount: int, hitpoints: int, damage_source: String)

func take_damage(amount: int, damage_source: String = "unknown"):
  hitpoints -= amount
  damaged.emit(amount, hitpoints, damage_source)
  _update_display()
  if hitpoints <= 0:
    die(damage_source)


func _ready():
  # Store the initial hitpoints as max_hitpoints
  max_hitpoints = hitpoints
  _update_display()
  subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  
  # Register this component in parent's metadata for discovery
  if get_parent():
    get_parent().set_meta("health_component", self)
  
  # Find the camera in the scene
  _find_camera()

func _find_camera():
  # Look for the camera in the scene tree
  var root = get_tree().root
  camera = _search_for_camera(root)
  if not camera:
    push_warning("Health component could not find Camera3D in scene tree")

func _search_for_camera(node: Node) -> Camera3D:
  # Check if this node is a Camera3D
  if node is Camera3D:
    return node
  
  # Recursively search children
  for child in node.get_children():
    var result = _search_for_camera(child)
    if result:
      return result
  
  return null

func _process(_delta: float):
  # Update health bar scale based on camera size for consistent screen-space appearance
  if camera and sprite3d:
    # Only update scale if camera size has changed to avoid unnecessary updates
    if camera.size != last_camera_size:
      last_camera_size = camera.size
      var scale_factor = camera.size / reference_camera_size
      sprite3d.scale = Vector3(scale_factor, scale_factor, scale_factor)

func _update_display():
  # Set up health display UI
  health_bar.max_value = max_hitpoints
  health_bar.value = hitpoints
  health_label.text = str(hitpoints) + " / " + str(max_hitpoints)

func die(damage_source: String = "unknown"):
  if dead:
    return

  dead = true
  hitpoints = 0
  died.emit(damage_source)
