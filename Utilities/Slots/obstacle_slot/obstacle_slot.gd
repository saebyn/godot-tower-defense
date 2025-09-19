extends Node3D
class_name ObstacleSlot

signal obstacle_type_changed(slot: ObstacleSlot, old_type: String, new_type: String)
signal slot_clicked(slot: ObstacleSlot)

@export_group("Slot Configuration")
@export var slot_id: String = "" # Unique identifier for this slot
@export var allowed_obstacle_types: Array[String] = [] # Empty means all types allowed

@export_group("Visual Feedback")
@export var empty_material: StandardMaterial3D
@export var occupied_material: StandardMaterial3D
@export var highlight_material: StandardMaterial3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var area_3d: Area3D = $Area3D

var current_obstacle_type: String = ""
var current_obstacle_instance: PlaceableObstacle = null
var is_highlighted: bool = false

func _ready():
  # Set up materials if not assigned
  if not empty_material:
    empty_material = StandardMaterial3D.new()
    empty_material.albedo_color = Color.GRAY
    empty_material.flags_transparent = true
    empty_material.albedo_color.a = 0.3
  
  if not occupied_material:
    occupied_material = StandardMaterial3D.new()
    occupied_material.albedo_color = Color.BLUE
    occupied_material.flags_transparent = true
    occupied_material.albedo_color.a = 0.5
  
  if not highlight_material:
    highlight_material = StandardMaterial3D.new()
    highlight_material.albedo_color = Color.YELLOW
    highlight_material.flags_transparent = true
    highlight_material.albedo_color.a = 0.7
  
  # Connect area signals for click detection
  area_3d.input_event.connect(_on_area_input_event)
  area_3d.mouse_entered.connect(_on_mouse_entered)
  area_3d.mouse_exited.connect(_on_mouse_exited)
  
  # Set initial visual state
  _update_visual_state()

func _on_area_input_event(_camera: Node, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int):
  if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
    slot_clicked.emit(self)

func _on_mouse_entered():
  set_highlight(true)

func _on_mouse_exited():
  set_highlight(false)

func set_highlight(highlighted: bool):
  is_highlighted = highlighted
  _update_visual_state()

func is_empty() -> bool:
  return current_obstacle_instance == null

func can_place_obstacle_type(obstacle_type: String) -> bool:
  if allowed_obstacle_types.is_empty():
    return true
  return obstacle_type in allowed_obstacle_types

func set_obstacle_type(obstacle_type: String, obstacle_scene: PackedScene = null) -> bool:
  if not can_place_obstacle_type(obstacle_type):
    Logger.warn("ObstacleSlot", "Cannot place obstacle type '%s' in slot '%s'" % [obstacle_type, slot_id])
    return false
  
  var old_type = current_obstacle_type
  
  # Remove existing obstacle if any
  if current_obstacle_instance:
    current_obstacle_instance.queue_free()
    current_obstacle_instance = null
  
  # Set new obstacle if provided
  if obstacle_scene:
    current_obstacle_instance = obstacle_scene.instantiate() as PlaceableObstacle
    if current_obstacle_instance:
      add_child(current_obstacle_instance)
      current_obstacle_instance.global_position = global_position
      current_obstacle_type = obstacle_type
    else:
      Logger.error("ObstacleSlot", "Failed to instantiate obstacle of type '%s'" % obstacle_type)
      return false
  else:
    current_obstacle_type = ""
  
  _update_visual_state()
  obstacle_type_changed.emit(self, old_type, current_obstacle_type)
  
  Logger.info("ObstacleSlot", "Slot '%s' changed from '%s' to '%s'" % [slot_id, old_type, current_obstacle_type])
  return true

func clear_obstacle():
  set_obstacle_type("", null)

func get_obstacle_type() -> String:
  return current_obstacle_type

func get_obstacle_instance() -> PlaceableObstacle:
  return current_obstacle_instance

func _update_visual_state():
  if not mesh_instance:
    return
  
  var material: StandardMaterial3D
  
  if is_highlighted:
    material = highlight_material
  elif is_empty():
    material = empty_material
  else:
    material = occupied_material
  
  mesh_instance.set_surface_override_material(0, material)