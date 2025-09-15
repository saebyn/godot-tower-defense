extends Node

@export var shake_magnitude: float = 0.1  # Magnitude of the shake effect

var shake_tween: Tween  # Tween for shake animation


func damage_taken(_amount: int, _current_hp: int) -> void:
  _shake_effect()


func _shake_effect():
  # Stop any existing shake animation
  if shake_tween:
    shake_tween.kill()

  # Create shake animation
  shake_tween = create_tween()

  # Quick shake sequence
  shake_tween.tween_method(_set_shake_offset, Vector2.ZERO, Vector2(shake_magnitude, 0), 0.05)
  shake_tween.tween_method(
    _set_shake_offset, Vector2(shake_magnitude, 0), Vector2(-shake_magnitude, shake_magnitude), 0.05
  )
  shake_tween.tween_method(
    _set_shake_offset,
    Vector2(-shake_magnitude, shake_magnitude),
    Vector2(shake_magnitude, -shake_magnitude),
    0.05
  )
  shake_tween.tween_method(
    _set_shake_offset,
    Vector2(shake_magnitude, -shake_magnitude),
    Vector2(-shake_magnitude / 2, shake_magnitude / 2),
    0.05
  )
  shake_tween.tween_method(
    _set_shake_offset, Vector2(-shake_magnitude / 2, shake_magnitude / 2), Vector2.ZERO, 0.1
  )


func _set_shake_offset(offset: Vector2):
  get_parent().global_position += Vector3(offset.x, 0, offset.y)


func _exit_tree() -> void:
  # Stop any active shake animation
  if shake_tween:
    shake_tween.kill()
