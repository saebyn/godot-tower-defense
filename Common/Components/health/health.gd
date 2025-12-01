extends Node
class_name Component_Health

@export var hitpoints: int = 100
@export var disabled: bool:
  get:
    return disabled
  set(value):
    disabled = value
    _update_display()


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

## Triggers death for this entity, emitting the died signal.
## Can be called directly to trigger instant death (e.g., instant-kill mechanics or scripted sequences).
##
## @param damage_source A string describing what caused the death.
func die(damage_source: String = "unknown"):
  _die(damage_source)

func _die(damage_source: String = "unknown"):
  if dead:
    return

  dead = true
  hitpoints = 0
  died.emit(damage_source)
