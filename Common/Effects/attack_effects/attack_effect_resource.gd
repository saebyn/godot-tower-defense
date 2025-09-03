"""
# AttackEffectResource.gd

A resource that defines an attack effect type with its scene and default parameters.
This allows for flexible, data-driven attack effect configuration without hardcoding.
"""
extends Resource
class_name AttackEffectResource

@export var effect_name: String = ""
@export var effect_scene: PackedScene
@export var effect_parameters: Dictionary = {}
@export var description: String = ""

func _init(name: String = "", scene: PackedScene = null, parameters: Dictionary = {}, desc: String = ""):
	effect_name = name
	effect_scene = scene
	effect_parameters = parameters
	description = desc