extends HBoxContainer
class_name KeybindButton

## Keybind Button - Displays and allows rebinding of input actions

@onready var action_label: Label = $ActionLabel
@onready var key_button: Button = $KeyButton

var action_name: String = "":
  set(value):
    action_name = value
    if is_node_ready():
      _update_display()

var is_remapping: bool = false

func _ready() -> void:
  _update_display()
  key_button.pressed.connect(_on_key_button_pressed)

func _update_display() -> void:
  if not action_label or not key_button:
    return
  
  # Format action name for display
  var display_name = action_name.replace("_", " ").capitalize()
  action_label.text = display_name
  
  # Get current key binding
  var events = InputMap.action_get_events(action_name)
  if events.size() > 0:
    var event = events[0]
    if event is InputEventKey:
      key_button.text = OS.get_keycode_string(event.physical_keycode)
    else:
      key_button.text = "Unbound"
  else:
    key_button.text = "Unbound"

func _on_key_button_pressed() -> void:
  if not is_remapping:
    is_remapping = true
    key_button.text = "Press any key..."
    set_process_input(true)

func _input(event: InputEvent) -> void:
  if not is_remapping:
    return
  
  if event is InputEventKey and event.pressed:
    # Rebind the action
    _rebind_action(event)
    is_remapping = false
    set_process_input(false)
    get_viewport().set_input_as_handled()

func _rebind_action(event: InputEventKey) -> void:
  # Clear existing bindings for this action
  InputMap.action_erase_events(action_name)
  
  # Add new binding
  InputMap.action_add_event(action_name, event)
  
  # Update display
  _update_display()
  
  Logger.info("KeybindButton", "Rebound '%s' to %s" % [action_name, OS.get_keycode_string(event.physical_keycode)])
  
  # Note: We don't save keybinds to file in this version
  # This could be added later if needed
