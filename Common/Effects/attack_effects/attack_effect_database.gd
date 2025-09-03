"""
# AttackEffectDatabase.gd

A resource that contains all available attack effect types.
This serves as a registry of effects that can be selected by Attack components.
"""
extends Resource
class_name AttackEffectDatabase

@export var effects: Array[AttackEffectResource] = []

func get_effect_by_name(effect_name: String) -> AttackEffectResource:
	"""Get an effect resource by its name."""
	for effect in effects:
		if effect.effect_name == effect_name:
			return effect
	return null

func get_effect_names() -> Array[String]:
	"""Get a list of all available effect names."""
	var names: Array[String] = []
	for effect in effects:
		names.append(effect.effect_name)
	return names

func add_effect(effect: AttackEffectResource) -> void:
	"""Add a new effect to the database."""
	if effect:
		effects.append(effect)

func remove_effect(effect_name: String) -> bool:
	"""Remove an effect from the database by name."""
	for i in range(effects.size()):
		if effects[i].effect_name == effect_name:
			effects.remove_at(i)
			return true
	return false