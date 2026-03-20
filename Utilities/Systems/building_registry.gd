## Building Registry
## Manages loading and availability of building types based on tech tree unlocks.
## This script should be set as an Autoload in the project settings.
extends Node

signal obstacle_types_updated(added_types: Array[Resource_BuildingType], removed_types: Array[Resource_BuildingType])

var _obstacle_types: Array[Resource_BuildingType] = []
var available_obstacle_types: Array[Resource_BuildingType] = []

@export var obstacle_types_directory: String = "res://Config/Obstacles/"
@export var obstacle_type_resource_extension: String = ".tres"


func _ready() -> void:
  MyLogger.info("BuildingRegistry", "Initializing BuildingRegistry...")
  _load_obstacle_types()
  
  # Connect to TechTreeManager (autoload singleton)
  TechTreeManager.tech_unlocked.connect(_on_tech_unlocked)
  TechTreeManager.tech_locked.connect(_on_tech_locked)
  MyLogger.info("BuildingRegistry", "Connected to TechTreeManager")
  
  # Connect to SaveManager to update buildings after save data is loaded
  SaveManager.load_completed.connect(_on_save_loaded)
  
  # Do initial update of available buildings
  # This will be updated again when save data loads
  _update_available_obstacles()
  MyLogger.info("BuildingRegistry", "BuildingRegistry initialized with %d total buildings, %d available" % [_obstacle_types.size(), available_obstacle_types.size()])


## Load all building type resources from the buildings directory
func _load_obstacle_types() -> void:
  _obstacle_types.clear()
  var dir = DirAccess.open(obstacle_types_directory)
  if not dir:
    MyLogger.error("BuildingRegistry", "Could not open buildings directory: %s" % obstacle_types_directory)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  while file_name != "":
    if file_name.ends_with(obstacle_type_resource_extension):
      var file_path = obstacle_types_directory + file_name
      var resource = ResourceLoader.load(file_path)
      if resource and resource is Resource_BuildingType:
        _obstacle_types.append(resource)
        MyLogger.debug("BuildingRegistry", "Loaded building type: %s (%s)" % [resource.id, resource.name])
      else:
        MyLogger.warn("BuildingRegistry", "Failed to load building type from: %s" % file_path)
    file_name = dir.get_next()


## Update the list of available buildings based on tech tree state
func _update_available_obstacles() -> void:
  var added_types: Array[Resource_BuildingType] = []
  var removed_types: Array[Resource_BuildingType] = []
  var updated_available: Array[Resource_BuildingType] = []
  
  for obstacle_type in _obstacle_types:
    var is_unlocked = _is_obstacle_unlocked(obstacle_type)
    var was_available = obstacle_type in available_obstacle_types
    
    if is_unlocked:
      updated_available.append(obstacle_type)
      if not was_available:
        added_types.append(obstacle_type)
        MyLogger.info("BuildingRegistry", "Building unlocked: %s (%s)" % [obstacle_type.id, obstacle_type.name])
    elif was_available:
      removed_types.append(obstacle_type)
      MyLogger.info("BuildingRegistry", "Building locked: %s (%s)" % [obstacle_type.id, obstacle_type.name])
  
  available_obstacle_types = updated_available
  
  if added_types.size() > 0 or removed_types.size() > 0:
    obstacle_types_updated.emit(added_types, removed_types)


## Check if a building is unlocked based on tech tree
func _is_obstacle_unlocked(obstacle_type: Resource_BuildingType) -> bool:
  # If no tech requirements, building is always unlocked
  if obstacle_type.required_tech_ids.is_empty():
    return true
  
  # All required techs must be unlocked
  for tech_id in obstacle_type.required_tech_ids:
    if not TechTreeManager.is_tech_unlocked(tech_id):
      return false
  
  return true


## Called when a tech is unlocked
func _on_tech_unlocked(tech_id: String) -> void:
  MyLogger.debug("BuildingRegistry", "Tech unlocked: %s - checking for new buildings" % tech_id)
  _update_available_obstacles()


## Called when a tech is locked (mutually exclusive)
func _on_tech_locked(tech_id: String) -> void:
  MyLogger.debug("BuildingRegistry", "Tech locked: %s - checking for removed buildings" % tech_id)
  _update_available_obstacles()


## Called when save data is loaded - refresh building availability
func _on_save_loaded() -> void:
  MyLogger.info("BuildingRegistry", "Save data loaded - updating available buildings")
  _update_available_obstacles()


## Get a building type by ID
func get_obstacle_type(obstacle_id: String) -> Resource_BuildingType:
  for obstacle_type in _obstacle_types:
    if obstacle_type.id == obstacle_id:
      return obstacle_type
  return null


## Check if a building is available
func is_obstacle_available(obstacle_id: String) -> bool:
  for obstacle_type in available_obstacle_types:
    if obstacle_type.id == obstacle_id:
      return true
  return false
