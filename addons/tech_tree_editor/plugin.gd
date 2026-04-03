@tool
extends EditorPlugin

## Tech Tree Editor Plugin
## Provides a full main-screen editor for authoring and managing the tech tree

var main_screen: VBoxContainer

func _enter_tree() -> void:
	# Load and instance the main screen scene
	var main_scene: PackedScene = preload("res://addons/tech_tree_editor/ui/tech_tree_editor_main.tscn")
	main_screen = main_scene.instantiate()

	# Add to editor main screen (appears next to 2D, 3D, Script, etc.)
	EditorInterface.get_editor_main_screen().add_child(main_screen)
	# Ensure the control fills the entire main screen area
	main_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_screen.hide()

	print("Tech Tree Editor Plugin: Enabled")

func _exit_tree() -> void:
	# Clean up the main screen
	if main_screen:
		main_screen.queue_free()

	print("Tech Tree Editor Plugin: Disabled")

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if main_screen:
		main_screen.visible = visible

func _get_plugin_name() -> String:
	return "Tech Tree"

func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/tech_tree_editor/icons/plugin_icon.svg")
