extends Node3D
class_name ObstacleSlotManager

signal slot_selection_changed(selected_slot: ObstacleSlot)
signal navigation_mesh_update_requested

@export_group("Slot Management")
@export var auto_detect_slots: bool = true
@export var slot_scenes: Array[PackedScene] = []

@export_group("Obstacle Types")
@export var available_obstacle_types: Dictionary = {}

@export_group("Node References")
@export var navigation_region: NavigationRegion3D

var obstacle_slots: Array[ObstacleSlot] = []
var selected_slot: ObstacleSlot = null

func _ready():
  if auto_detect_slots:
    _detect_slots()
  
  # Connect to all slot signals
  for slot in obstacle_slots:
    _connect_slot_signals(slot)

func _detect_slots():
  obstacle_slots.clear()
  
  # Find all ObstacleSlot children
  for child in get_children():
    if child is ObstacleSlot:
      obstacle_slots.append(child)
  
  Logger.info("ObstacleSlotManager", "Detected %d obstacle slots" % obstacle_slots.size())

func _connect_slot_signals(slot: ObstacleSlot):
  if not slot.slot_clicked.is_connected(_on_slot_clicked):
    slot.slot_clicked.connect(_on_slot_clicked)
  if not slot.obstacle_type_changed.is_connected(_on_obstacle_type_changed):
    slot.obstacle_type_changed.connect(_on_obstacle_type_changed)

func add_slot(slot: ObstacleSlot):
  if slot not in obstacle_slots:
    obstacle_slots.append(slot)
    _connect_slot_signals(slot)
    Logger.info("ObstacleSlotManager", "Added slot '%s'" % slot.slot_id)

func remove_slot(slot: ObstacleSlot):
  if slot in obstacle_slots:
    obstacle_slots.erase(slot)
    # Disconnect signals
    if slot.slot_clicked.is_connected(_on_slot_clicked):
      slot.slot_clicked.disconnect(_on_slot_clicked)
    if slot.obstacle_type_changed.is_connected(_on_obstacle_type_changed):
      slot.obstacle_type_changed.disconnect(_on_obstacle_type_changed)
    
    if selected_slot == slot:
      selected_slot = null
      slot_selection_changed.emit(null)
    
    Logger.info("ObstacleSlotManager", "Removed slot '%s'" % slot.slot_id)

func get_slot_by_id(slot_id: String) -> ObstacleSlot:
  for slot in obstacle_slots:
    if slot.slot_id == slot_id:
      return slot
  return null

func set_obstacle_in_slot(slot_id: String, obstacle_type: String) -> bool:
  var slot = get_slot_by_id(slot_id)
  if not slot:
    Logger.error("ObstacleSlotManager", "Slot with ID '%s' not found" % slot_id)
    return false
  
  if obstacle_type.is_empty():
    slot.clear_obstacle()
    return true
  
  if obstacle_type not in available_obstacle_types:
    Logger.error("ObstacleSlotManager", "Obstacle type '%s' not available" % obstacle_type)
    return false
  
  var obstacle_scene = available_obstacle_types[obstacle_type] as PackedScene
  return slot.set_obstacle_type(obstacle_type, obstacle_scene)

func clear_all_slots():
  for slot in obstacle_slots:
    slot.clear_obstacle()
  Logger.info("ObstacleSlotManager", "Cleared all obstacle slots")

func get_all_slots() -> Array[ObstacleSlot]:
  return obstacle_slots.duplicate()

func get_empty_slots() -> Array[ObstacleSlot]:
  var empty_slots: Array[ObstacleSlot] = []
  for slot in obstacle_slots:
    if slot.is_empty():
      empty_slots.append(slot)
  return empty_slots

func get_occupied_slots() -> Array[ObstacleSlot]:
  var occupied_slots: Array[ObstacleSlot] = []
  for slot in obstacle_slots:
    if not slot.is_empty():
      occupied_slots.append(slot)
  return occupied_slots

func select_slot(slot: ObstacleSlot):
  if selected_slot == slot:
    return
  
  # Unhighlight previous selection
  if selected_slot:
    selected_slot.set_highlight(false)
  
  selected_slot = slot
  
  # Highlight new selection
  if selected_slot:
    selected_slot.set_highlight(true)
  
  slot_selection_changed.emit(selected_slot)

func deselect_slot():
  select_slot(null)

func get_selected_slot() -> ObstacleSlot:
  return selected_slot

func _on_slot_clicked(slot: ObstacleSlot):
  Logger.debug("ObstacleSlotManager", "Slot '%s' clicked" % slot.slot_id)
  select_slot(slot)

func _on_obstacle_type_changed(slot: ObstacleSlot, old_type: String, new_type: String):
  Logger.info("ObstacleSlotManager", "Slot '%s' obstacle changed: '%s' -> '%s'" % [slot.slot_id, old_type, new_type])
  
  # Request navigation mesh update
  navigation_mesh_update_requested.emit()
  
  # If we have a navigation region, trigger rebake
  if navigation_region:
    _rebake_navigation_mesh()

func _rebake_navigation_mesh():
  if not navigation_region or not navigation_region.navigation_mesh:
    return
  
  Logger.info("ObstacleSlotManager", "Rebaking navigation mesh due to slot change...")
  
  # Wait for any ongoing baking to finish
  if navigation_region.is_baking():
    await navigation_region.bake_finished
  
  navigation_region.bake_navigation_mesh()

func add_obstacle_type(type_name: String, scene: PackedScene):
  available_obstacle_types[type_name] = scene
  Logger.info("ObstacleSlotManager", "Added obstacle type '%s'" % type_name)

func remove_obstacle_type(type_name: String):
  if type_name in available_obstacle_types:
    available_obstacle_types.erase(type_name)
    Logger.info("ObstacleSlotManager", "Removed obstacle type '%s'" % type_name)

func get_available_obstacle_types() -> Array[String]:
  return available_obstacle_types.keys()