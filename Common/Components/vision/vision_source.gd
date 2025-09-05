extends Node
class_name VisionSource

signal vision_changed(source: Node)

@export var vision_range: float = 10.0
@export var active: bool = true : set = set_active

var fog_of_war: FogOfWar

func _ready():
	# Find the FogOfWar node in the scene
	fog_of_war = get_tree().get_first_node_in_group("fog_of_war")
	if fog_of_war:
		register_with_fog_system()

func set_active(value: bool):
	if active != value:
		active = value
		if fog_of_war:
			if active:
				fog_of_war.add_vision_source(self)
			else:
				fog_of_war.remove_vision_source(self)
		vision_changed.emit(self)

func register_with_fog_system():
	if active and fog_of_war:
		fog_of_war.add_vision_source(self)

func unregister_from_fog_system():
	if fog_of_war:
		fog_of_war.remove_vision_source(self)

func _exit_tree():
	unregister_from_fog_system()

func get_world_position() -> Vector3:
	var parent = get_parent()
	if parent and parent is Node3D:
		return parent.global_position
	return Vector3.ZERO