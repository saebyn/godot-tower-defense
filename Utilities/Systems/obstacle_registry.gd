## Obstacle Registry
## Manages loading and availability of obstacle types based on tech tree unlocks.
## This script should be set as an Autoload in the project settings.
extends Node

signal obstacle_types_updated(added_types: Array[ObstacleTypeResource], removed_types: Array[ObstacleTypeResource])

var _obstacle_types: Array[ObstacleTypeResource] = []
var available_obstacle_types: Array[ObstacleTypeResource] = []

@export var obstacle_types_directory: String = "res://Config/Obstacles/"
@export var obstacle_type_resource_extension: String = ".tres"


func _ready() -> void:
  Logger.info("ObstacleRegistry", "Initializing ObstacleRegistry...")
  _load_obstacle_types()
  
  # Connect to TechTreeManager (autoload singleton)
  TechTreeManager.tech_unlocked.connect(_on_tech_unlocked)
  TechTreeManager.tech_locked.connect(_on_tech_locked)
  Logger.info("ObstacleRegistry", "Connected to TechTreeManager")
  
  _update_available_obstacles()
  Logger.info("ObstacleRegistry", "ObstacleRegistry initialized with %d total obstacles, %d available" % [_obstacle_types.size(), available_obstacle_types.size()])


## Load all obstacle type resources from the obstacles directory
func _load_obstacle_types() -> void:
  _obstacle_types.clear()
  var dir = DirAccess.open(obstacle_types_directory)
  if not dir:
    Logger.error("ObstacleRegistry", "Could not open obstacles directory: %s" % obstacle_types_directory)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  while file_name != "":
    if file_name.ends_with(obstacle_type_resource_extension):
      var file_path = obstacle_types_directory + file_name
      var resource = ResourceLoader.load(file_path)
      if resource and resource is ObstacleTypeResource:
        _obstacle_types.append(resource)
        Logger.debug("ObstacleRegistry", "Loaded obstacle type: %s (%s)" % [resource.id, resource.name])
      else:
        Logger.warn("ObstacleRegistry", "Failed to load obstacle type from: %s" % file_path)
    file_name = dir.get_next()
  dir.list_dir_end()


## Update the list of available obstacles based on tech tree state
func _update_available_obstacles() -> void:
  var added_types: Array[ObstacleTypeResource] = []
  var removed_types: Array[ObstacleTypeResource] = []
  var updated_available: Array[ObstacleTypeResource] = []
  
  for obstacle_type in _obstacle_types:
    var is_unlocked = _is_obstacle_unlocked(obstacle_type)
    var was_available = obstacle_type in available_obstacle_types
    
    if is_unlocked:
      updated_available.append(obstacle_type)
      if not was_available:
        added_types.append(obstacle_type)
        Logger.info("ObstacleRegistry", "Obstacle unlocked: %s (%s)" % [obstacle_type.id, obstacle_type.name])
    elif was_available:
      removed_types.append(obstacle_type)
      Logger.info("ObstacleRegistry", "Obstacle locked: %s (%s)" % [obstacle_type.id, obstacle_type.name])
  
  available_obstacle_types = updated_available
  
  if added_types.size() > 0 or removed_types.size() > 0:
    obstacle_types_updated.emit(added_types, removed_types)


## Check if an obstacle is unlocked based on tech tree
func _is_obstacle_unlocked(obstacle_type: ObstacleTypeResource) -> bool:
  # If no tech requirements, obstacle is always unlocked
  if obstacle_type.required_tech_ids.is_empty():
    return true
  
  # All required techs must be unlocked
  for tech_id in obstacle_type.required_tech_ids:
    if not TechTreeManager.is_tech_unlocked(tech_id):
      return false
  
  return true


## Called when a tech is unlocked
func _on_tech_unlocked(tech_id: String) -> void:
  Logger.debug("ObstacleRegistry", "Tech unlocked: %s - checking for new obstacles" % tech_id)
  _update_available_obstacles()


## Called when a tech is locked (mutually exclusive)
func _on_tech_locked(tech_id: String) -> void:
  Logger.debug("ObstacleRegistry", "Tech locked: %s - checking for removed obstacles" % tech_id)
  _update_available_obstacles()


## Get an obstacle type by ID
func get_obstacle_type(obstacle_id: String) -> ObstacleTypeResource:
  for obstacle_type in _obstacle_types:
    if obstacle_type.id == obstacle_id:
      return obstacle_type
  return null


## Check if an obstacle is available
func is_obstacle_available(obstacle_id: String) -> bool:
  for obstacle_type in available_obstacle_types:
    if obstacle_type.id == obstacle_id:
      return true
  return false
