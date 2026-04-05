## A component that adds a shake effect to an entity when it takes damage.
## The shake effect is achieved using a Tween to animate the position offset.
## Add this node as a child of any entity that has a Health component to enable the effect.
class_name Effect_Shake
extends Node

@export var disable: bool = false # If true, disables the shake effect
@export var lock_position_while_shaking: bool = true # If true, locks the entity's position during the shake to prevent external movement from interfering with the effect
@export var shake_magnitude: float = 0.1 # Magnitude of the shake effect
@export var shake_duration: float = 0.3 # Total duration of the shake effect in seconds

var shake_tween: Tween # Tween for shake animation

func damage_taken(_amount: int, _current_hp: int, _source: String) -> void:
  _shake_effect()

func _shake_effect():
  if disable:
    return

  # Stop any existing shake animation
  if shake_tween:
    shake_tween.kill()
  
  # Create shake animation
  shake_tween = create_tween()

  var parent := get_parent()
  if not parent:
    return

  if lock_position_while_shaking:
    var original_position: Vector3 = parent.global_position
    
    # Quick shake sequence
    shake_tween.tween_property(parent, "global_position", original_position + Vector3(shake_magnitude, 0, 0), shake_duration / 6.0)
    shake_tween.tween_property(parent, "global_position", original_position + Vector3(-shake_magnitude, 0, shake_magnitude), shake_duration / 6.0)
    shake_tween.tween_property(parent, "global_position", original_position + Vector3(shake_magnitude, 0, -shake_magnitude), shake_duration / 6.0)
    shake_tween.tween_property(parent, "global_position", original_position + Vector3(-shake_magnitude / 2, 0, shake_magnitude / 2), shake_duration / 6.0)
    shake_tween.tween_property(parent, "global_position", original_position, shake_duration / 3.0)
  else:
    shake_tween.tween_property(parent, "global_position", Vector3(shake_magnitude, 0, 0), shake_duration / 6.0).as_relative()
    shake_tween.tween_property(parent, "global_position", Vector3(-shake_magnitude, 0, shake_magnitude), shake_duration / 6.0).as_relative()
    shake_tween.tween_property(parent, "global_position", Vector3(shake_magnitude, 0, -shake_magnitude), shake_duration / 6.0).as_relative()
    shake_tween.tween_property(parent, "global_position", Vector3(-shake_magnitude / 2, 0, shake_magnitude / 2), shake_duration / 6.0).as_relative()
    shake_tween.tween_property(parent, "global_position", Vector3(-shake_magnitude / 2, 0, -shake_magnitude / 2), shake_duration / 3.0).as_relative()


func _exit_tree() -> void:
  # Stop any active shake animation
  if shake_tween:
    shake_tween.kill()
