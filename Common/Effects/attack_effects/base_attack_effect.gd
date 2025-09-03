"""
# BaseAttackEffect.gd

Base class for attack visual effects.
Provides common functionality for all attack effect types.
"""
extends Node3D
class_name BaseAttackEffect

signal effect_finished

@export var effect_duration: float = 1.0
@export var auto_cleanup: bool = true

var effect_tween: Tween

func play_effect(from_position: Vector3, to_position: Vector3, parameters: Dictionary = {}) -> void:
	"""
	Play the attack effect from source to target position.
	Parameters can override default effect settings.
	Override this method in derived classes.
	"""
	global_position = from_position
	_apply_parameters(parameters)
	_animate_effect(from_position, to_position)

func _apply_parameters(parameters: Dictionary) -> void:
	"""
	Apply parameter overrides to this effect instance.
	Override this method in derived classes to handle specific parameters.
	"""
	# Apply any parameters that match exported properties
	for param_name in parameters:
		if param_name in self:
			set(param_name, parameters[param_name])

func _animate_effect(from_pos: Vector3, to_pos: Vector3) -> void:
	"""
	Override this method to implement specific effect animation.
	"""
	# Default implementation - just finish immediately
	_finish_effect()

func _finish_effect() -> void:
	"""
	Called when the effect animation is complete.
	"""
	effect_finished.emit()
	if auto_cleanup:
		queue_free()

func _exit_tree() -> void:
	# Clean up tween if it exists
	if effect_tween:
		effect_tween.kill()