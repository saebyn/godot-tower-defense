extends Control
class_name SlotUIPanel

signal obstacle_type_selected(obstacle_type: String)

@export_group("UI Configuration")
@export var slot_id_label: Label
@export var obstacle_type_label: Label
@export var obstacle_buttons_container: Container

@export_group("Node References")
@export var slot_manager: ObstacleSlotManager

var current_slot: ObstacleSlot = null
var obstacle_buttons: Dictionary = {}

func _ready():
  # Connect to slot manager if available
  if slot_manager:
    slot_manager.slot_selection_changed.connect(_on_slot_selection_changed)
  
  # Hide panel initially
  visible = false

func set_slot_manager(manager: ObstacleSlotManager):
  if slot_manager and slot_manager.slot_selection_changed.is_connected(_on_slot_selection_changed):
    slot_manager.slot_selection_changed.disconnect(_on_slot_selection_changed)
  
  slot_manager = manager
  
  if slot_manager:
    slot_manager.slot_selection_changed.connect(_on_slot_selection_changed)
    _update_obstacle_buttons()

func _update_obstacle_buttons():
  if not slot_manager or not obstacle_buttons_container:
    return
  
  # Clear existing buttons
  for button in obstacle_buttons.values():
    button.queue_free()
  obstacle_buttons.clear()
  
  # Create button for clearing the slot
  var clear_button = Button.new()
  clear_button.text = "Clear"
  clear_button.pressed.connect(_on_clear_pressed)
  obstacle_buttons_container.add_child(clear_button)
  
  # Create buttons for each available obstacle type
  for obstacle_type in slot_manager.get_available_obstacle_types():
    var button = Button.new()
    button.text = obstacle_type.capitalize()
    button.pressed.connect(_on_obstacle_button_pressed.bind(obstacle_type))
    obstacle_buttons[obstacle_type] = button
    obstacle_buttons_container.add_child(button)

func _on_slot_selection_changed(selected_slot: ObstacleSlot):
  current_slot = selected_slot
  
  if current_slot:
    visible = true
    _update_slot_info()
    _update_button_states()
  else:
    visible = false

func _update_slot_info():
  if not current_slot:
    return
  
  if slot_id_label:
    slot_id_label.text = "Slot: " + current_slot.slot_id
  
  if obstacle_type_label:
    var obstacle_type = current_slot.get_obstacle_type()
    if obstacle_type.is_empty():
      obstacle_type_label.text = "Type: Empty"
    else:
      obstacle_type_label.text = "Type: " + obstacle_type.capitalize()

func _update_button_states():
  if not current_slot:
    return
  
  # Update button availability based on slot restrictions
  for obstacle_type in obstacle_buttons.keys():
    var button = obstacle_buttons[obstacle_type]
    button.disabled = not current_slot.can_place_obstacle_type(obstacle_type)

func _on_clear_pressed():
  if current_slot and slot_manager:
    slot_manager.set_obstacle_in_slot(current_slot.slot_id, "")
    _update_slot_info()

func _on_obstacle_button_pressed(obstacle_type: String):
  if current_slot and slot_manager:
    if slot_manager.set_obstacle_in_slot(current_slot.slot_id, obstacle_type):
      _update_slot_info()
      obstacle_type_selected.emit(obstacle_type)
    else:
      Logger.warn("SlotUIPanel", "Failed to set obstacle type '%s' in slot '%s'" % [obstacle_type, current_slot.slot_id])