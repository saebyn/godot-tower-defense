## BaseAttackEffect.gd
##
## Base class for attack visual effects.
## Provides common functionality for all attack effect types.
extends Node3D
class_name BaseAttackEffect

signal effect_finished

@export var effect_duration: float = 1.0
@export var auto_cleanup: bool = false ## Default to false since effects are now persistent child components

var effect_tween: Tween

func play_effect(from_position: Vector3, to_position: Vector3) -> void:
  ## Play the attack effect from source to target position.
  ## Override this method in derived classes.
  global_position = from_position
  _animate_effect(from_position, to_position)

func _animate_effect(from_pos: Vector3, to_pos: Vector3) -> void:
  ## Override this method to implement specific effect animation.
  ## Default implementation - just finish immediately
  _finish_effect()

func _finish_effect() -> void:
  ## Called when the effect animation is complete.
  effect_finished.emit()
  if auto_cleanup:
    queue_free()

func _exit_tree() -> void:
  ## Clean up tween if it exists
  if effect_tween:
    effect_tween.kill()