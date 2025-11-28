extends Node
class_name Component_Health

@export var hitpoints: int = 100
@export var disabled: bool:
  get:
    return disabled
  set(value):
    disabled = value
    _update_display()

@export var show_damage_numbers: bool = true ## Whether to display floating damage numbers

@onready var health_bar := $SubViewportContainer/SubViewport/VBoxContainer/HealthBar
@onready var health_label := $SubViewportContainer/SubViewport/VBoxContainer/HealthLabel
@onready var subviewport := $SubViewportContainer/SubViewport
@onready var sprite := $Sprite3D

var max_hitpoints: int
var dead: bool = false

signal died(damage_source: String)
signal damaged(amount: int, hitpoints: int, damage_source: String)

func take_damage(amount: int, damage_source: String = "unknown"):
  if disabled:
    return

  hitpoints -= amount
  damaged.emit(amount, hitpoints, damage_source)
  _update_display()
  
  # Show damage number via damage numbers component if available
  var parent = get_parent()
  if parent and parent.has_meta("damage_numbers_component"):
    var damage_numbers = parent.get_meta("damage_numbers_component")
    if damage_numbers and damage_numbers.has_method("show_damage"):
      damage_numbers.show_damage(amount, damage_source)
  
  if hitpoints <= 0:
    _die(damage_source)


func _ready():
  # Store the initial hitpoints as max_hitpoints
  max_hitpoints = hitpoints
  _update_display()
  subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  
  # Register this component in parent's metadata for discovery
  if get_parent():
    get_parent().set_meta("health_component", self)

func _update_display():
  if not is_node_ready():
    return
  
  sprite.visible = not disabled

  # Set up health display UI
  health_bar.max_value = max_hitpoints
  health_bar.value = hitpoints
  health_label.text = str(hitpoints) + " / " + str(max_hitpoints)

func _die(damage_source: String = "unknown"):
  if dead:
    return

  dead = true
  hitpoints = 0
  died.emit(damage_source)
