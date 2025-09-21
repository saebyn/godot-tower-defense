extends Node
class_name Health

@export var hitpoints: int = 100

@onready var health_bar := $SubViewportContainer/SubViewport/VBoxContainer/HealthBar
@onready var health_label := $SubViewportContainer/SubViewport/VBoxContainer/HealthLabel
@onready var subviewport := $SubViewportContainer/SubViewport

var max_hitpoints: int
var dead: bool = false

signal died
signal damaged(amount: int, hitpoints: int)

func take_damage(amount: int):
  hitpoints -= amount
  damaged.emit(amount, hitpoints)
  _update_display()
  if hitpoints <= 0:
    die()


func _ready():
  # Store the initial hitpoints as max_hitpoints
  max_hitpoints = hitpoints
  _update_display()
  subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _update_display():
  # Set up health display UI
  health_bar.max_value = max_hitpoints
  health_bar.value = hitpoints
  health_label.text = str(hitpoints) + " / " + str(max_hitpoints)

func die():
  if dead:
    return

  dead = true
  hitpoints = 0
  died.emit()
