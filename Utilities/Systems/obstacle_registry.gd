## Obstacle Registry
## Manages loading and availability of obstacle types based on game conditions.
## This script should be set as an Autoload in the project settings.
extends Node

signal obstacle_types_updated(added_types: Array[ObstacleTypeResource], removed_types: Array[ObstacleTypeResource])

var _obstacle_types: Array[ObstacleTypeResource] = []
var available_obstacle_types: Array[ObstacleTypeResource] = []

@export var obstacle_types_directory: String = "res://Config/Obstacles/"
@export var obstacle_type_resource_extension: String = ".tres"


func apply_conditions(conditions: Array[String]) -> void:
  var added_types = []
  var removed_types = []
  var updated_available_obstacle_types: Array[ObstacleTypeResource] = []
  # Unlock or remove obstacle types based on conditions
  for obstacle_type in _obstacle_types:
    var unlocked = true
    for condition in obstacle_type.unlock_conditions:
      if condition not in conditions:
        unlocked = false
        break
    if unlocked and obstacle_type not in available_obstacle_types:
      updated_available_obstacle_types.append(obstacle_type)
      added_types.append(obstacle_type)
    elif not unlocked and obstacle_type in available_obstacle_types:
      removed_types.append(obstacle_type)

  available_obstacle_types = updated_available_obstacle_types
  if added_types.size() > 0 or removed_types.size() > 0:
    obstacle_types_updated.emit(added_types, removed_types)

func _ready() -> void:
  _obstacle_types.clear()
  var dir = DirAccess.open(obstacle_types_directory)
  if dir:
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
      if file_name.ends_with(obstacle_type_resource_extension):
        var file_path = obstacle_types_directory + file_name
        var resource = ResourceLoader.load(file_path)
        if resource and resource is ObstacleTypeResource:
          _obstacle_types.append(resource)
      file_name = dir.get_next()
    dir.list_dir_end()

  apply_conditions([])
