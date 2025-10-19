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
var modifier_wait_timer: float = 0.0
var pending_modifier_event: InputEventKey = null

func _ready() -> void:
  _update_display()
  key_button.pressed.connect(_on_key_button_pressed)
  set_process(false)  # Disable process by default

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
      key_button.text = _format_key_with_modifiers(event)
    elif event is InputEventMouseButton:
      key_button.text = _get_mouse_button_name(event.button_index)
    else:
      key_button.text = "Unbound"
  else:
    key_button.text = "Unbound"

func _format_key_with_modifiers(event: InputEventKey) -> String:
  var parts: Array[String] = []
  
  # Add modifiers in a consistent order
  if event.ctrl_pressed or event.command_or_control_autoremap:
    parts.append("Ctrl")
  if event.alt_pressed:
    parts.append("Alt")
  if event.shift_pressed:
    parts.append("Shift")
  if event.meta_pressed:
    parts.append("Meta")
  
  # Add the actual key
  parts.append(OS.get_keycode_string(event.physical_keycode))
  
  # Join with "+" separator
  return "+".join(parts)

func _is_modifier_key(keycode: int) -> bool:
  # Check if the key is a modifier key (Shift, Ctrl, Alt, Meta, etc.)
  return keycode in [
    KEY_SHIFT,
    KEY_CTRL, 
    KEY_ALT,
    KEY_META,
    KEY_CAPSLOCK,
    KEY_NUMLOCK,
    KEY_SCROLLLOCK
  ]

func _get_mouse_button_name(button_index: int) -> String:
  match button_index:
    MOUSE_BUTTON_LEFT:
      return "Left Mouse"
    MOUSE_BUTTON_RIGHT:
      return "Right Mouse"
    MOUSE_BUTTON_MIDDLE:
      return "Middle Mouse"
    MOUSE_BUTTON_WHEEL_UP:
      return "Mouse Wheel Up"
    MOUSE_BUTTON_WHEEL_DOWN:
      return "Mouse Wheel Down"
    MOUSE_BUTTON_WHEEL_LEFT:
      return "Mouse Wheel Left"
    MOUSE_BUTTON_WHEEL_RIGHT:
      return "Mouse Wheel Right"
    MOUSE_BUTTON_XBUTTON1:
      return "Mouse X1"
    MOUSE_BUTTON_XBUTTON2:
      return "Mouse X2"
    _:
      return "Mouse Button %d" % button_index

func _on_key_button_pressed() -> void:
  if not is_remapping:
    is_remapping = true
    key_button.text = "Press any key..."
    set_process_input(true)
    set_process(true)
    modifier_wait_timer = 0.0
    pending_modifier_event = null

func _process(delta: float) -> void:
  # Handle timeout for modifier-only key binding
  if is_remapping and pending_modifier_event != null:
    modifier_wait_timer += delta
    # After 0.5 seconds, accept the modifier-only binding
    if modifier_wait_timer >= 0.5:
      _rebind_action(pending_modifier_event)
      is_remapping = false
      set_process_input(false)
      set_process(false)
      pending_modifier_event = null

func _input(event: InputEvent) -> void:
  if not is_remapping:
    return
  
  if event is InputEventKey and event.pressed:
    # Check if this is a modifier-only key
    if _is_modifier_key(event.physical_keycode):
      # Store the modifier event and start waiting
      pending_modifier_event = event
      modifier_wait_timer = 0.0
      return
    
    # If we had a pending modifier and now got a real key, use the combination
    pending_modifier_event = null
    modifier_wait_timer = 0.0
    
    # Rebind the action to keyboard key (with or without modifiers)
    _rebind_action(event)
    is_remapping = false
    set_process_input(false)
    set_process(false)
    get_viewport().set_input_as_handled()
  elif event is InputEventMouseButton and event.pressed:
    # Clear any pending modifier
    pending_modifier_event = null
    modifier_wait_timer = 0.0
    
    # Rebind the action to mouse button
    _rebind_action(event)
    is_remapping = false
    set_process_input(false)
    set_process(false)
    get_viewport().set_input_as_handled()

func _rebind_action(event: InputEvent) -> void:
  # Clear existing bindings for this action
  InputMap.action_erase_events(action_name)
  
  # Add new binding
  InputMap.action_add_event(action_name, event)
  
  # Update display
  _update_display()
  
  var binding_name = ""
  if event is InputEventKey:
    binding_name = _format_key_with_modifiers(event)
  elif event is InputEventMouseButton:
    binding_name = _get_mouse_button_name(event.button_index)
  
  Logger.info("KeybindButton", "Rebound '%s' to %s" % [action_name, binding_name])
  
  # Note: We don't save keybinds to file in this version
  # This could be added later if needed
