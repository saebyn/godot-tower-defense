## A component that adds a shake effect to an entity when it takes damage.
## The shake effect is achieved using a Tween to animate the position offset.
## Add this node as a child of any entity that has a Health component to enable the effect.
class_name ShakeEffect
extends Node

@export var shake_magnitude: float = 0.1 # Magnitude of the shake effect

var shake_tween: Tween # Tween for shake animation

func damage_taken(_amount: int, _current_hp: int) -> void:
  _shake_effect()

func _shake_effect():
  # Stop any existing shake animation
  if shake_tween:
    shake_tween.kill()
  
  # Create shake animation
  shake_tween = create_tween()

  var parent := get_parent()
  if not parent:
    return
  var original_position: Vector3 = parent.global_position
  
  # Quick shake sequence
  shake_tween.tween_property(parent, "global_position", original_position + Vector3(shake_magnitude, 0, 0), 0.05)
  shake_tween.tween_property(parent, "global_position", original_position + Vector3(-shake_magnitude, 0, shake_magnitude), 0.05)
  shake_tween.tween_property(parent, "global_position", original_position + Vector3(shake_magnitude, 0, -shake_magnitude), 0.05)
  shake_tween.tween_property(parent, "global_position", original_position + Vector3(-shake_magnitude / 2, 0, shake_magnitude / 2), 0.05)
  shake_tween.tween_property(parent, "global_position", original_position, 0.1)

func _exit_tree() -> void:
  # Stop any active shake animation
  if shake_tween:
    shake_tween.kill()
