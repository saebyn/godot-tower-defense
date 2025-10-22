@tool
extends EditorPlugin

## Tech Tree Editor Plugin
## Provides a visual graph-based editor for authoring and managing the tech tree

var dock: Control
var dock_scene: PackedScene

func _enter_tree() -> void:
	# Load and instance the dock scene
	dock_scene = preload("res://addons/tech_tree_editor/ui/tech_tree_editor_dock.tscn")
	dock = dock_scene.instantiate()
	
	# Add the dock to the editor
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL, dock)
	
	print("Tech Tree Editor Plugin: Enabled")

func _exit_tree() -> void:
	# Clean up the dock
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
	
	print("Tech Tree Editor Plugin: Disabled")
