"""
Hotbar.gd

A dynamic hotbar component that displays available obstacle types and allows quick access.
Supports both mouse clicks and keyboard shortcuts for obstacle selection.
Includes configuration capabilities to change which obstacles are in which slots.
"""
extends Control
class_name Hotbar

signal obstacle_selected(obstacle: ObstacleTypeResource)

@export var max_slots: int = 6  # Maximum number of hotbar slots
@export var slot_size: Vector2 = Vector2(64, 64)  # Size of each hotbar slot
@export var spacing: int = 8  # Spacing between slots

@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var obstacle_selection_menu: PopupMenu = $ObstacleSelectionMenu

var slot_obstacle_ids: Array[String] = []  # Obstacle IDs for each slot
var slot_buttons: Array[Button] = []  # Button references for each slot
var current_configuring_slot: int = -1  # Track which slot is being configured

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
    
    # Connect button signals for both left and right click
    slot_button.pressed.connect(_on_slot_pressed.bind(i))
    slot_button.gui_input.connect(_on_slot_gui_input.bind(i))
    
    slots_container.add_child(slot_button)
    slot_buttons.append(slot_button)

func _connect_signals() -> void:
  # Connect to ObstacleRegistry for dynamic updates
  if ObstacleRegistry:
    ObstacleRegistry.obstacle_types_updated.connect(_on_obstacle_types_updated)

func _populate_default_hotbar() -> void:
  """Populate hotbar with default obstacles from registry"""
  Logger.info("Hotbar", "Populating hotbar with default obstacles")
  
  # Initialize the slot_obstacle_ids array
  slot_obstacle_ids.clear()
  
  if ObstacleRegistry:
    var available = ObstacleRegistry.available_obstacle_types
    for i in range(max_slots):
      if i < available.size():
        slot_obstacle_ids.append(available[i].id)
        Logger.info("Hotbar", "Setting slot %d to %s" % [i, available[i].name])
      else:
        slot_obstacle_ids.append("")  # Empty slot
  else:
    # Fill with empty slots if registry not available
    for i in range(max_slots):
      slot_obstacle_ids.append("")
  
  # Update all slot visuals
  for i in range(max_slots):
    _update_slot_visual(i)

func _get_obstacle_by_id(obstacle_id: String) -> ObstacleTypeResource:
  """Get obstacle resource by ID from the registry"""
  if obstacle_id.is_empty() or not ObstacleRegistry:
    return null
  
  for obstacle in ObstacleRegistry.available_obstacle_types:
    if obstacle.id == obstacle_id:
      return obstacle
  
  return null

func _update_slot_visual(slot_index: int) -> void:
  """Update the visual representation of a slot"""
  if slot_index >= slot_buttons.size() or slot_index >= slot_obstacle_ids.size():
    return
  
  var button = slot_buttons[slot_index]
  var obstacle_id = slot_obstacle_ids[slot_index]
  var obstacle = _get_obstacle_by_id(obstacle_id)
  
  if obstacle:
    # Set button icon and tooltip
    button.icon = obstacle.icon if obstacle.icon else null
    button.tooltip_text = "%s\nCost: %d\n%s\n\nLeft click: Select\nRight click: Choose different obstacle" % [obstacle.name, obstacle.cost, obstacle.description]
    button.disabled = false
    
    # Show cost and slot number on button
    button.text = "%d\n$%d" % [slot_index + 1, obstacle.cost]
  else:
    # Empty slot
    button.icon = null
    button.tooltip_text = "Empty slot %d\n\nRight click to choose an obstacle" % (slot_index + 1)
    button.disabled = true
    button.text = str(slot_index + 1)

func _on_slot_pressed(slot_index: int) -> void:
  """Handle left click on slot - select obstacle for placement"""
  var obstacle_id = slot_obstacle_ids[slot_index] if slot_index < slot_obstacle_ids.size() else ""
  var obstacle = _get_obstacle_by_id(obstacle_id)
  
  if obstacle:
    Logger.info("Hotbar", "Selected obstacle: %s from slot %d" % [obstacle.name, slot_index + 1])
    obstacle_selected.emit(obstacle)

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
  """Handle GUI input for advanced slot interactions"""
  if event is InputEventMouseButton and event.pressed:
    if event.button_index == MOUSE_BUTTON_RIGHT:
      _show_obstacle_selection_menu(slot_index)

func _show_obstacle_selection_menu(slot_index: int) -> void:
  """Show popup menu with available obstacles for slot assignment"""
  if not ObstacleRegistry or not obstacle_selection_menu:
    return
  
  var available = ObstacleRegistry.available_obstacle_types
  if available.is_empty():
    return
  
  # Remember which slot we're configuring
  current_configuring_slot = slot_index
  
  # Clear existing menu items
  obstacle_selection_menu.clear()
  
  # Add "Clear Slot" option for non-empty slots
  var current_obstacle_id = slot_obstacle_ids[slot_index] if slot_index < slot_obstacle_ids.size() else ""
  if not current_obstacle_id.is_empty():
    obstacle_selection_menu.add_item("Clear Slot", -1)
    obstacle_selection_menu.add_separator()
  
  # Add available obstacles to menu
  for i in range(available.size()):
    var obstacle = available[i]
    var item_text = "%s ($%d)" % [obstacle.name, obstacle.cost]
    obstacle_selection_menu.add_item(item_text, i)
    
    # Set icon if available
    if obstacle.icon:
      obstacle_selection_menu.set_item_icon(obstacle_selection_menu.get_item_count() - 1, obstacle.icon)
    
    # Highlight current selection
    if obstacle.id == current_obstacle_id:
      obstacle_selection_menu.set_item_disabled(obstacle_selection_menu.get_item_count() - 1, false)
      # Mark as current selection in some way - could add checkmark or different styling
  
  # Position menu near the clicked slot button
  var button = slot_buttons[slot_index]
  var button_global_rect = button.get_global_rect()
  var menu_position = Vector2i(button_global_rect.position.x, button_global_rect.position.y + button_global_rect.size.y)
  
  # Show the popup menu
  obstacle_selection_menu.popup_on_parent(Rect2i(menu_position, Vector2i(200, 0)))
  
  Logger.info("Hotbar", "Showing obstacle selection menu for slot %d" % (slot_index + 1))

func _on_obstacle_menu_item_selected(id: int) -> void:
  """Handle selection from the obstacle popup menu"""
  if current_configuring_slot < 0:
    return
  
  if id == -1:
    # Clear slot option selected
    set_slot_obstacle(current_configuring_slot, null)
    Logger.info("Hotbar", "Cleared slot %d" % (current_configuring_slot + 1))
  else:
    # Obstacle selected
    var available = ObstacleRegistry.available_obstacle_types
    if id >= 0 and id < available.size():
      var selected_obstacle = available[id]
      set_slot_obstacle(current_configuring_slot, selected_obstacle)
      Logger.info("Hotbar", "Assigned %s to slot %d" % [selected_obstacle.name, current_configuring_slot + 1])
  
  # Reset the configuring slot
  current_configuring_slot = -1

func set_slot_obstacle(slot_index: int, obstacle: ObstacleTypeResource) -> void:
  """Set an obstacle for a specific slot"""
  if slot_index < 0 or slot_index >= max_slots:
    Logger.warn("Hotbar", "Invalid slot index: %d" % slot_index)
    return
  
  # Ensure array is large enough
  while slot_obstacle_ids.size() <= slot_index:
    slot_obstacle_ids.append("")
  
  # Set the obstacle ID
  var obstacle_id = obstacle.id if obstacle else ""
  slot_obstacle_ids[slot_index] = obstacle_id
  
  # Update visual
  _update_slot_visual(slot_index)

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
    
    if slot_index >= 0:
      _on_slot_pressed(slot_index)

func _on_obstacle_types_updated(added_types: Array[ObstacleTypeResource], removed_types: Array[ObstacleTypeResource]) -> void:
  Logger.info("Hotbar", "Obstacle types updated. Added: %d, Removed: %d" % [added_types.size(), removed_types.size()])
  
  # Update visuals for all slots to reflect changes
  for i in range(max_slots):
    _update_slot_visual(i)

func get_slot_obstacle(slot_index: int) -> ObstacleTypeResource:
  """Get the obstacle for a specific slot"""
  if slot_index < 0 or slot_index >= slot_obstacle_ids.size():
    return null
  
  var obstacle_id = slot_obstacle_ids[slot_index]
  return _get_obstacle_by_id(obstacle_id)

func clear_slot(slot_index: int) -> void:
  """Clear a specific slot"""
  set_slot_obstacle(slot_index, null)