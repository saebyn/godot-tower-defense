@tool
extends Control

## Tech Tree Editor Dock
## Main UI container for the tech tree editor

# Branch color scheme
const BRANCH_COLORS := {
	"Offensive": Color("#E74C3C"),
	"Defensive": Color("#3498DB"),
	"Economy": Color("#2ECC71"),
	"Support": Color("#F39C12"),
	"Click": Color("#9B59B6"),
	"Advanced": Color("#F1C40F")
}

# Valid branch names
const VALID_BRANCHES := ["Offensive", "Defensive", "Economy", "Support", "Click", "Advanced"]

# ID prefixes for validation
const ID_PREFIXES := {
	"Offensive": ["tur_"],
	"Defensive": ["ob_"],
	"Economy": ["eco_"],
	"Support": ["sup_"],
	"Click": ["clk_"],
	"Advanced": ["adv_"]
}

@onready var graph_edit: GraphEdit = $VBoxContainer/GraphEdit
@onready var toolbar: HBoxContainer = $VBoxContainer/Toolbar
@onready var status_label: Label = $VBoxContainer/StatusBar/StatusLabel
@onready var validation_panel: Panel = $VBoxContainer/ValidationPanel
@onready var validation_list: ItemList = $VBoxContainer/ValidationPanel/VBoxContainer/ValidationList
@onready var inspector_panel: Panel = $VBoxContainer/InspectorPanel
@onready var inspector_container: VBoxContainer = $VBoxContainer/InspectorPanel/ScrollContainer/InspectorContainer

# Data
var tech_nodes: Dictionary = {} # tech_id -> TechNodeResource
var graph_nodes: Dictionary = {} # tech_id -> GraphNode
var selected_tech_id: String = ""
var validation_errors: Array[String] = []

const TECH_TREE_PATH := "res://Config/TechTree/"

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	
	_setup_ui()
	_load_tech_tree()
	_rebuild_graph()
	_update_status()

func _setup_ui() -> void:
	# Setup GraphEdit
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.node_selected.connect(_on_node_selected)
	graph_edit.node_deselected.connect(_on_node_deselected)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	graph_edit.popup_request.connect(_on_popup_request)
	
	# Setup toolbar buttons
	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.pressed.connect(_on_refresh_pressed)
	toolbar.add_child(refresh_button)
	
	var add_node_button := Button.new()
	add_node_button.text = "Add Node"
	add_node_button.pressed.connect(_on_add_node_pressed)
	toolbar.add_child(add_node_button)
	
	var validate_button := Button.new()
	validate_button.text = "Validate"
	validate_button.pressed.connect(_on_validate_pressed)
	toolbar.add_child(validate_button)
	
	var export_button := Button.new()
	export_button.text = "Export Markdown"
	export_button.pressed.connect(_on_export_pressed)
	toolbar.add_child(export_button)
	
	# Hide validation and inspector panels by default
	validation_panel.hide()
	inspector_panel.hide()

func _load_tech_tree() -> void:
	tech_nodes.clear()
	
	var dir := DirAccess.open(TECH_TREE_PATH)
	if not dir:
		_set_status("Error: Could not open tech tree directory", true)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path := TECH_TREE_PATH + file_name
			var tech_node := load(resource_path) as TechNodeResource
			
			if tech_node and tech_node.is_valid():
				tech_nodes[tech_node.id] = tech_node
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	_set_status("Loaded %d tech nodes" % tech_nodes.size())

func _rebuild_graph() -> void:
	# Clear existing graph nodes
	for node in graph_edit.get_children():
		if node is GraphNode:
			graph_edit.remove_child(node)
			node.queue_free()
	
	graph_nodes.clear()
	
	# Create graph nodes
	var position_offset := Vector2(50, 50)
	var column_width := 300
	var row_height := 150
	
	# Group nodes by branch
	var branches_dict: Dictionary = {}
	for tech_id in tech_nodes:
		var tech := tech_nodes[tech_id]
		if tech.branch_name not in branches_dict:
			branches_dict[tech.branch_name] = []
		branches_dict[tech.branch_name].append(tech)
	
	# Position nodes by branch
	var branch_index := 0
	for branch_name in VALID_BRANCHES:
		if branch_name not in branches_dict:
			continue
		
		var branch_techs: Array = branches_dict[branch_name]
		for i in range(branch_techs.size()):
			var tech: TechNodeResource = branch_techs[i]
			var graph_node := _create_graph_node(tech)
			
			# Position node
			graph_node.position_offset = position_offset + Vector2(branch_index * column_width, i * row_height)
			
			graph_edit.add_child(graph_node)
			graph_nodes[tech.id] = graph_node
		
		branch_index += 1
	
	# Draw connections
	_draw_connections()

func _create_graph_node(tech: TechNodeResource) -> GraphNode:
	var graph_node := GraphNode.new()
	graph_node.name = tech.id
	graph_node.title = tech.display_name
	graph_node.resizable = false
	graph_node.draggable = true
	
	# Set color based on branch
	if tech.branch_name in BRANCH_COLORS:
		var color := BRANCH_COLORS[tech.branch_name]
		graph_node.modulate = Color(color.r, color.g, color.b, 0.3)
	
	# Add content
	var vbox := VBoxContainer.new()
	
	var id_label := Label.new()
	id_label.text = "ID: " + tech.id
	id_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(id_label)
	
	var branch_label := Label.new()
	branch_label.text = "Branch: " + tech.branch_name
	vbox.add_child(branch_label)
	
	var level_label := Label.new()
	level_label.text = "Level: " + str(tech.level_requirement)
	vbox.add_child(level_label)
	
	if tech.prerequisite_tech_ids.size() > 0:
		var prereq_label := Label.new()
		prereq_label.text = "Prerequisites: " + str(tech.prerequisite_tech_ids.size())
		vbox.add_child(prereq_label)
	
	if tech.mutually_exclusive_with.size() > 0:
		var excl_label := Label.new()
		excl_label.text = "⚠ Mutually Exclusive: " + str(tech.mutually_exclusive_with.size())
		excl_label.add_theme_color_override("font_color", Color.RED)
		vbox.add_child(excl_label)
	
	graph_node.add_child(vbox)
	return graph_node

func _draw_connections() -> void:
	# Clear existing connections
	graph_edit.clear_connections()
	
	# Draw prerequisite connections (normal lines)
	for tech_id in tech_nodes:
		var tech := tech_nodes[tech_id]
		for prereq_id in tech.prerequisite_tech_ids:
			if prereq_id in graph_nodes:
				graph_edit.connect_node(prereq_id, 0, tech_id, 0)
	
	# Note: GraphEdit doesn't support custom line styles for mutual exclusivity
	# We'll handle this differently in the visual representation

func _validate_tech_tree() -> Array[String]:
	var errors: Array[String] = []
	
	# Check ID uniqueness (already handled by dictionary keys)
	
	# Check for circular dependencies
	for tech_id in tech_nodes:
		if _has_circular_dependency(tech_id):
			errors.append("Circular dependency detected for: " + tech_id)
	
	# Verify prerequisite node existence
	for tech_id in tech_nodes:
		var tech := tech_nodes[tech_id]
		for prereq_id in tech.prerequisite_tech_ids:
			if prereq_id not in tech_nodes:
				errors.append("%s: Prerequisite '%s' does not exist" % [tech_id, prereq_id])
	
	# Validate mutual exclusivity pairs
	for tech_id in tech_nodes:
		var tech := tech_nodes[tech_id]
		for excl_id in tech.mutually_exclusive_with:
			if excl_id not in tech_nodes:
				errors.append("%s: Mutually exclusive tech '%s' does not exist" % [tech_id, excl_id])
			else:
				var other_tech := tech_nodes[excl_id]
				if tech_id not in other_tech.mutually_exclusive_with:
					errors.append("%s: Mutual exclusivity with '%s' is not bidirectional" % [tech_id, excl_id])
	
	# Check branch completion requirements
	for tech_id in tech_nodes:
		var tech := tech_nodes[tech_id]
		for branch in tech.requires_branch_completion:
			if branch not in VALID_BRANCHES:
				errors.append("%s: Invalid branch completion requirement '%s'" % [tech_id, branch])
	
	# Validate ID prefix consistency
	for tech_id in tech_nodes:
		var tech := tech_nodes[tech_id]
		if tech.branch_name in ID_PREFIXES:
			var valid_prefixes: Array = ID_PREFIXES[tech.branch_name]
			var has_valid_prefix := false
			for prefix in valid_prefixes:
				if tech_id.begins_with(prefix):
					has_valid_prefix = true
					break
			if not has_valid_prefix:
				errors.append("%s: ID should start with one of %s for branch '%s'" % [tech_id, str(valid_prefixes), tech.branch_name])
	
	return errors

func _has_circular_dependency(tech_id: String, visited: Array[String] = []) -> bool:
	if tech_id in visited:
		return true
	
	if tech_id not in tech_nodes:
		return false
	
	var new_visited := visited.duplicate()
	new_visited.append(tech_id)
	
	var tech := tech_nodes[tech_id]
	for prereq_id in tech.prerequisite_tech_ids:
		if _has_circular_dependency(prereq_id, new_visited):
			return true
	
	return false

func _set_status(text: String, is_error: bool = false) -> void:
	status_label.text = text
	if is_error:
		status_label.add_theme_color_override("font_color", Color.RED)
	else:
		status_label.add_theme_color_override("font_color", Color.WHITE)

func _update_status() -> void:
	_set_status("Tech nodes: %d | Errors: %d" % [tech_nodes.size(), validation_errors.size()], validation_errors.size() > 0)

# Signal handlers
func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	# Add prerequisite connection
	if to_node in tech_nodes:
		var tech := tech_nodes[to_node]
		if from_node not in tech.prerequisite_tech_ids:
			tech.prerequisite_tech_ids.append(from_node)
			_save_tech_node(tech)
			_rebuild_graph()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	# Remove prerequisite connection
	if to_node in tech_nodes:
		var tech := tech_nodes[to_node]
		var idx := tech.prerequisite_tech_ids.find(from_node)
		if idx >= 0:
			tech.prerequisite_tech_ids.remove_at(idx)
			_save_tech_node(tech)
			_rebuild_graph()

func _on_node_selected(node: Node) -> void:
	if node is GraphNode:
		selected_tech_id = node.name
		_show_inspector(selected_tech_id)

func _on_node_deselected(node: Node) -> void:
	selected_tech_id = ""
	inspector_panel.hide()

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	# TODO: Implement node deletion with dependency warnings
	pass

func _on_popup_request(position: Vector2) -> void:
	# TODO: Show context menu for adding nodes
	pass

func _on_refresh_pressed() -> void:
	_load_tech_tree()
	_rebuild_graph()
	_update_status()

func _on_add_node_pressed() -> void:
	# TODO: Implement node creation dialog
	_set_status("Add node feature not yet implemented", true)

func _on_validate_pressed() -> void:
	validation_errors = _validate_tech_tree()
	
	validation_list.clear()
	for error in validation_errors:
		validation_list.add_item(error)
	
	if validation_errors.size() > 0:
		validation_panel.show()
		_set_status("Validation failed: %d errors" % validation_errors.size(), true)
	else:
		validation_panel.hide()
		_set_status("Validation passed!", false)

func _on_export_pressed() -> void:
	# TODO: Implement markdown export
	_set_status("Export feature not yet implemented", true)

func _show_inspector(tech_id: String) -> void:
	if tech_id not in tech_nodes:
		return
	
	# Clear inspector
	for child in inspector_container.get_children():
		child.queue_free()
	
	var tech := tech_nodes[tech_id]
	
	# Add inspector fields
	_add_inspector_field("ID", tech.id, false)
	_add_inspector_field("Display Name", tech.display_name, true)
	_add_inspector_field("Description", tech.description, true)
	_add_inspector_field("Branch", tech.branch_name, false)
	_add_inspector_field("Level Requirement", str(tech.level_requirement), true)
	
	inspector_panel.show()

func _add_inspector_field(label_text: String, value: String, editable: bool) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(label)
	
	if editable:
		var line_edit := LineEdit.new()
		line_edit.text = value
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(line_edit)
	else:
		var value_label := Label.new()
		value_label.text = value
		hbox.add_child(value_label)
	
	inspector_container.add_child(hbox)

func _save_tech_node(tech: TechNodeResource) -> void:
	var file_path := TECH_TREE_PATH + tech.id + ".tres"
	var error := ResourceSaver.save(tech, file_path)
	if error != OK:
		_set_status("Failed to save tech node: " + tech.id, true)
	else:
		_set_status("Saved: " + tech.id)

func _on_validation_close_pressed() -> void:
	validation_panel.hide()
