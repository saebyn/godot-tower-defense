extends PanelContainer
class_name TechNodeCard

## Individual tech node card component
## Displays tech node state and basic info

signal selected()

enum NodeState {
	UNLOCKED,        # Green - tech is unlocked
	AVAILABLE,       # Yellow - can be unlocked now
	LOCKED,          # Gray - locked but not permanently
	PERMANENTLY_LOCKED  # Red - permanently locked by exclusive choice
}

var tech: TechNodeResource
var current_state: NodeState = NodeState.LOCKED

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel

func setup(tech_node: TechNodeResource) -> void:
	tech = tech_node
	name_label.text = tech.display_name
	level_label.text = "Level %d" % tech.level_requirement
	
	# Make the card clickable
	mouse_filter = Control.MOUSE_FILTER_STOP

func update_state(new_state: NodeState) -> void:
	current_state = new_state
	
	# Update visual appearance based on state
	match current_state:
		NodeState.UNLOCKED:
			state_label.text = "✅ Unlocked"
			_set_card_color(Color(0.2, 0.8, 0.2, 1.0))  # Green
		NodeState.AVAILABLE:
			state_label.text = "⚡ Available"
			_set_card_color(Color(0.8, 0.8, 0.2, 1.0))  # Yellow
		NodeState.LOCKED:
			state_label.text = "🔒 Locked"
			_set_card_color(Color(0.5, 0.5, 0.5, 1.0))  # Gray
		NodeState.PERMANENTLY_LOCKED:
			state_label.text = "⛔ Locked"
			_set_card_color(Color(0.8, 0.2, 0.2, 1.0))  # Red

func _set_card_color(color: Color) -> void:
	# Create a StyleBoxFlat for the panel background
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected.emit()
			accept_event()
