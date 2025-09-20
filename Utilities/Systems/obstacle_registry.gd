extends Node
class_name ObstacleRegistry

signal obstacle_types_loaded
signal obstacle_type_added(obstacle_type: ObstacleTypeResource)
signal obstacle_type_removed(obstacle_id: String)

@export_group("Configuration")
@export var obstacle_type_resources: Array[ObstacleTypeResource] = []
@export var auto_load_from_directory: bool = true
@export var obstacle_types_directory: String = "res://Config/Obstacles/"

var _obstacle_types: Dictionary = {} # id -> ObstacleTypeResource

func _ready():
  if auto_load_from_directory:
    load_obstacle_types_from_directory()
  
  # Also register any manually assigned resources
  for resource in obstacle_type_resources:
    if resource and resource.is_valid():
      register_obstacle_type(resource)
  
  obstacle_types_loaded.emit()
  Logger.info("ObstacleRegistry", "Loaded %d obstacle types" % _obstacle_types.size())

func load_obstacle_types_from_directory():
  var dir = DirAccess.open(obstacle_types_directory)
  if not dir:
    Logger.warn("ObstacleRegistry", "Could not open obstacle types directory: %s" % obstacle_types_directory)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  
  while file_name != "":
    if file_name.ends_with(".tres") and not file_name.begins_with("."):
      var resource_path = obstacle_types_directory + file_name
      var resource = load(resource_path) as ObstacleTypeResource
      
      if resource and resource.is_valid():
        register_obstacle_type(resource)
        Logger.debug("ObstacleRegistry", "Loaded obstacle type: %s from %s" % [resource.id, file_name])
      else:
        Logger.warn("ObstacleRegistry", "Invalid obstacle type resource: %s" % resource_path)
    
    file_name = dir.get_next()

func register_obstacle_type(obstacle_type: ObstacleTypeResource):
  if not obstacle_type.is_valid():
    Logger.error("ObstacleRegistry", "Cannot register invalid obstacle type")
    return false
  
  if obstacle_type.id in _obstacle_types:
    Logger.warn("ObstacleRegistry", "Obstacle type '%s' already registered, overwriting" % obstacle_type.id)
  
  _obstacle_types[obstacle_type.id] = obstacle_type
  obstacle_type_added.emit(obstacle_type)
  return true

func unregister_obstacle_type(obstacle_id: String):
  if obstacle_id in _obstacle_types:
    _obstacle_types.erase(obstacle_id)
    obstacle_type_removed.emit(obstacle_id)
    Logger.info("ObstacleRegistry", "Unregistered obstacle type: %s" % obstacle_id)
    return true
  return false

func get_obstacle_type(obstacle_id: String) -> ObstacleTypeResource:
  return _obstacle_types.get(obstacle_id, null)

func get_all_obstacle_types() -> Array[ObstacleTypeResource]:
  var types: Array[ObstacleTypeResource] = []
  for resource in _obstacle_types.values():
    types.append(resource)
  return types

func get_obstacle_types_by_category(category: String) -> Array[ObstacleTypeResource]:
  var types: Array[ObstacleTypeResource] = []
  for resource in _obstacle_types.values():
    if resource.category == category:
      types.append(resource)
  return types

func get_available_obstacle_ids() -> Array[String]:
  var ids: Array[String] = []
  for id in _obstacle_types.keys():
    ids.append(id)
  return ids

func has_obstacle_type(obstacle_id: String) -> bool:
  return obstacle_id in _obstacle_types

func get_obstacle_count() -> int:
  return _obstacle_types.size()