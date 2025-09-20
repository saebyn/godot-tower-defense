"""
Hotbar.gd

A dynamic hotbar component that displays available obstacle types and allows quick access.
Supports both mouse clicks and keyboard shortcuts for obstacle selection.
"""
extends Control
class_name Hotbar

signal obstacle_selected(obstacle: ObstacleTypeResource)

@export var max_slots: int = 6  # Maximum number of hotbar slots
@export var slot_size: Vector2 = Vector2(64, 64)  # Size of each hotbar slot
@export var spacing: int = 8  # Spacing between slots

@onready var slots_container: HBoxContainer = $SlotsContainer

var hotbar_slots: Array[ObstacleTypeResource] = []  # Current obstacles in hotbar
var slot_buttons: Array[Button] = []  # Button references for each slot

func _ready() -> void:
  _setup_ui()
  _connect_signals()
  _populate_default_hotbar()

func _setup_ui() -> void:
  # Create the container if it doesn't exist
  if not slots_container:
    slots_container = HBoxContainer.new()
    slots_container.name = "SlotsContainer"
    add_child(slots_container)
  
  # Set container properties
  slots_container.add_theme_constant_override("separation", spacing)
  
  # Create hotbar slots
  _create_slots()

func _create_slots() -> void:
  # Clear existing slots
  for button in slot_buttons:
    if is_instance_valid(button):
      button.queue_free()
  slot_buttons.clear()
  
  # Create new slots
  for i in range(max_slots):
    var slot_button = Button.new()
    slot_button.custom_minimum_size = slot_size
    slot_button.expand_icon = true
    slot_button.flat = false
    
    # Add slot number as text overlay
    slot_button.text = str(i + 1)
    
    # Connect button signal
    slot_button.pressed.connect(_on_slot_pressed.bind(i))
    
    slots_container.add_child(slot_button)
    slot_buttons.append(slot_button)

func _connect_signals() -> void:
  # Connect to ObstacleRegistry for dynamic updates
  if ObstacleRegistry:
    ObstacleRegistry.obstacle_types_updated.connect(_on_obstacle_types_updated)

func _populate_default_hotbar() -> void:
  # Populate with available obstacles from registry
  if ObstacleRegistry:
    var available = ObstacleRegistry.available_obstacle_types
    for i in range(min(available.size(), max_slots)):
      set_slot_obstacle(i, available[i])

func set_slot_obstacle(slot_index: int, obstacle: ObstacleTypeResource) -> void:
  if slot_index < 0 or slot_index >= max_slots:
    Logger.warn("Hotbar", "Invalid slot index: %d" % slot_index)
    return
  
  # Ensure hotbar_slots array is large enough
  while hotbar_slots.size() <= slot_index:
    hotbar_slots.append(null)
  
  # Set the obstacle in the slot
  hotbar_slots[slot_index] = obstacle
  
  # Update the visual representation
  _update_slot_visual(slot_index)

func _update_slot_visual(slot_index: int) -> void:
  if slot_index >= slot_buttons.size():
    return
  
  var button = slot_buttons[slot_index]
  var obstacle = hotbar_slots[slot_index] if slot_index < hotbar_slots.size() else null
  
  if obstacle:
    # Set button icon and tooltip
    button.icon = obstacle.icon if obstacle.icon else null
    button.tooltip_text = "%s\nCost: %d\n%s" % [obstacle.name, obstacle.cost, obstacle.description]
    button.disabled = false
    
    # Show cost on button
    button.text = "%d\n$%d" % [slot_index + 1, obstacle.cost]
  else:
    # Empty slot
    button.icon = null
    button.tooltip_text = "Empty slot %d" % (slot_index + 1)
    button.disabled = true
    button.text = str(slot_index + 1)

func _on_slot_pressed(slot_index: int) -> void:
  if slot_index >= hotbar_slots.size():
    return
  
  var obstacle = hotbar_slots[slot_index]
  if obstacle:
    Logger.info("Hotbar", "Selected obstacle: %s from slot %d" % [obstacle.name, slot_index + 1])
    obstacle_selected.emit(obstacle)

func _input(event: InputEvent) -> void:
  # Handle keyboard shortcuts for hotbar slots (1-6)
  if event is InputEventKey and event.pressed:
    var slot_index = -1
    
    # Check for hotbar slot input actions
    if Input.is_action_just_pressed("hotbar_slot_1"):
      slot_index = 0
    elif Input.is_action_just_pressed("hotbar_slot_2"):
      slot_index = 1
    elif Input.is_action_just_pressed("hotbar_slot_3"):
      slot_index = 2
    elif Input.is_action_just_pressed("hotbar_slot_4"):
      slot_index = 3
    elif Input.is_action_just_pressed("hotbar_slot_5"):
      slot_index = 4
    elif Input.is_action_just_pressed("hotbar_slot_6"):
      slot_index = 5
    
    if slot_index >= 0 and slot_index < hotbar_slots.size():
      _on_slot_pressed(slot_index)

func _on_obstacle_types_updated(added_types: Array[ObstacleTypeResource], removed_types: Array[ObstacleTypeResource]) -> void:
  Logger.info("Hotbar", "Obstacle types updated. Added: %d, Removed: %d" % [added_types.size(), removed_types.size()])
  
  # For now, just repopulate the hotbar with available types
  # In the future, this could be smarter about preserving user configuration
  _populate_default_hotbar()

func get_slot_obstacle(slot_index: int) -> ObstacleTypeResource:
  if slot_index >= 0 and slot_index < hotbar_slots.size():
    return hotbar_slots[slot_index]
  return null

func clear_slot(slot_index: int) -> void:
  set_slot_obstacle(slot_index, null)

func get_all_slots() -> Array[ObstacleTypeResource]:
  return hotbar_slots.duplicate()