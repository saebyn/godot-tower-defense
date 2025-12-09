# Component_DamageNumbers
# A component that displays floating damage numbers and scrap gain feedback above entities.
# Add this component to entities that need visual damage/currency feedback.
# Uses a pooling system for performance via DamageNumbersManager.
extends Node
class_name Component_DamageNumbers

## Types of numbers that can be displayed
enum NumberType {
  DAMAGE_NORMAL,
  DAMAGE_CRITICAL,
  DAMAGE_FIRE,
  DAMAGE_ICE,
  DAMAGE_POISON,
  SCRAP_GAIN
}

## Duration of the fade out animation in seconds
@export var fade_duration: float = 1.5
## Distance the number travels upward
@export var float_distance: float = 2.0
## Vertical offset above the entity
@export var vertical_offset: float = 2.0
## Whether damage numbers are enabled
@export var show_damage_numbers: bool = true
## Whether scrap gain numbers are enabled  
@export var show_scrap_gain: bool = true

func _ready():
  # Register this component in parent's metadata for discovery
  if get_parent():
    get_parent().set_meta("damage_numbers_component", self)


## Display a damage number at the entity's position
func show_damage(amount: int, damage_source: String = "unknown"):
  if not show_damage_numbers or amount <= 0:
    return
  
  var parent = get_parent()
  if not parent or not parent is Node3D:
    return
  
  # Determine damage type based on source
  var damage_type = NumberType.DAMAGE_NORMAL
  match damage_source:
    "fire", "flame":
      damage_type = NumberType.DAMAGE_FIRE
    "ice", "frost", "cold":
      damage_type = NumberType.DAMAGE_ICE
    "poison", "toxic":
      damage_type = NumberType.DAMAGE_POISON
    "critical", "crit":
      damage_type = NumberType.DAMAGE_CRITICAL
  
  var world_pos = parent.global_position + Vector3.UP * vertical_offset
  _display_number(amount, world_pos, damage_type)


## Display a scrap gain number at the entity's position
func show_scrap(amount: int):
  if not show_scrap_gain or amount <= 0:
    return
  
  var parent = get_parent()
  if not parent or not parent is Node3D:
    return
  
  var world_pos = parent.global_position + Vector3.UP * (vertical_offset + 0.5)
  _display_number(amount, world_pos, NumberType.SCRAP_GAIN)


## Internal method to display a number
func _display_number(amount: int, world_position: Vector3, number_type: NumberType):
  var label = DamageNumbersManager.get_or_create_label()
  if not label:
    return
  
  # Set up the label text
  if number_type == NumberType.SCRAP_GAIN:
    label.text = "+%d" % amount
  else:
    label.text = str(amount)
  
  # Set color based on type
  match number_type:
    NumberType.DAMAGE_NORMAL:
      label.modulate = Color.WHITE
    NumberType.DAMAGE_CRITICAL:
      label.modulate = Color.RED
      label.font_size += 8 # Slightly larger for crits
    NumberType.DAMAGE_FIRE:
      label.modulate = Color.ORANGE
    NumberType.DAMAGE_ICE:
      label.modulate = Color.CYAN
    NumberType.DAMAGE_POISON:
      label.modulate = Color.PURPLE
    NumberType.SCRAP_GAIN:
      label.modulate = Color.GOLD
  
  # Store the base color for the fade animation
  var base_color = label.modulate
  
  # Position and activate
  label.global_position = world_position
  label.visible = true

  # Create tween for animation
  var tween = get_tree().create_tween()
  tween.set_parallel(true)
  
  # Float upward
  var end_position = world_position + Vector3.UP * float_distance
  tween.tween_property(label, "global_position", end_position, fade_duration).set_ease(Tween.EASE_OUT)
  
  # Fade out (animate modulate alpha)
  var end_color = Color(base_color.r, base_color.g, base_color.b, 0.0)
  tween.tween_property(label, "modulate", end_color, fade_duration).set_ease(Tween.EASE_IN)
  
  # Track tween and deactivate when complete
  DamageNumbersManager.add_tween(label, tween)
  
  MyLogger.trace("DamageNumbers", "Displaying %s at position %v" % [label.text, world_position])