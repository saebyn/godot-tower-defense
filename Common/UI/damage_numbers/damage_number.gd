extends Node3D
class_name UI_DamageNumber

## Visual feedback component that displays floating damage numbers or currency gains
## Appears above entities when they take damage or when currency is earned

enum NumberType {
  DAMAGE_NORMAL,
  DAMAGE_CRITICAL,
  DAMAGE_FIRE,
  DAMAGE_ICE,
  DAMAGE_POISON,
  SCRAP_GAIN
}

@export var float_speed: float = 1.0 ## Speed at which the number floats upward
@export var fade_duration: float = 1.5 ## Duration of the fade out animation
@export var float_distance: float = 2.0 ## Distance the number travels upward

var is_active: bool = false
var elapsed_time: float = 0.0
var start_position: Vector3
var number_type: NumberType = NumberType.DAMAGE_NORMAL

@onready var label_3d: Label3D = $Label3D

func _ready():
  if not label_3d:
    # Create Label3D if it doesn't exist
    label_3d = Label3D.new()
    add_child(label_3d)
    label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label_3d.no_depth_test = true
    label_3d.modulate = Color.WHITE
    label_3d.outline_size = 8
    label_3d.outline_modulate = Color.BLACK
    label_3d.font_size = 32
  
  # Start invisible
  visible = false
  is_active = false

func display_damage(amount: int, world_position: Vector3, damage_type: NumberType = NumberType.DAMAGE_NORMAL):
  """Display a damage number at the specified world position"""
  if amount <= 0:
    return
  
  # Set up the number
  label_3d.text = str(amount)
  number_type = damage_type
  
  # Set color based on damage type
  match damage_type:
    NumberType.DAMAGE_NORMAL:
      label_3d.modulate = Color.WHITE
    NumberType.DAMAGE_CRITICAL:
      label_3d.modulate = Color.RED
      label_3d.font_size = 40  # Slightly larger for crits
    NumberType.DAMAGE_FIRE:
      label_3d.modulate = Color.ORANGE
    NumberType.DAMAGE_ICE:
      label_3d.modulate = Color.CYAN
    NumberType.DAMAGE_POISON:
      label_3d.modulate = Color.PURPLE
    NumberType.SCRAP_GAIN:
      label_3d.modulate = Color.GOLD
      label_3d.text = "+%d" % amount
  
  # Position and activate
  global_position = world_position
  start_position = world_position
  elapsed_time = 0.0
  visible = true
  is_active = true
  
  Logger.trace("DamageNumber", "Displaying %s at position %v" % [label_3d.text, world_position])

func _process(delta: float):
  if not is_active:
    return
  
  elapsed_time += delta
  
  # Calculate progress (0 to 1)
  var progress = elapsed_time / fade_duration
  
  if progress >= 1.0:
    # Animation complete, deactivate
    deactivate()
    return
  
  # Float upward with predictable animation
  global_position = start_position + Vector3.UP * (float_distance * progress)
  
  # Fade out
  var alpha = 1.0 - progress
  var current_color = label_3d.modulate
  label_3d.modulate = Color(current_color.r, current_color.g, current_color.b, alpha)

func deactivate():
  """Deactivate this damage number and return it to the pool"""
  is_active = false
  visible = false
  elapsed_time = 0.0
  label_3d.font_size = 32  # Reset font size
  
  # Notify manager that this number is ready for reuse
  if get_parent() and get_parent().has_method("_return_to_pool"):
    get_parent()._return_to_pool(self)

func is_available() -> bool:
  """Check if this damage number is available for reuse"""
  return not is_active
