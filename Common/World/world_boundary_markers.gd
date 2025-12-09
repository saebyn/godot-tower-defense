extends Node3D
## Visual boundary markers that become visible when camera approaches world edges

@export var camera: Camera3D ## The camera to track
@export var fade_distance: float = 50.0 ## Distance from boundary at which markers start to fade in
@export var world_min_x: float = -200.0
@export var world_max_x: float = 200.0
@export var world_min_z: float = -200.0
@export var world_max_z: float = 200.0
@export var max_boundary_opacity: float = 0.5 ## Maximum opacity for boundary markers (0.0 to 1.0)

@onready var north_boundary: MeshInstance3D = $Boundaries/NorthBoundary
@onready var south_boundary: MeshInstance3D = $Boundaries/SouthBoundary
@onready var east_boundary: MeshInstance3D = $Boundaries/EastBoundary
@onready var west_boundary: MeshInstance3D = $Boundaries/WestBoundary

var boundaries: Array[MeshInstance3D] = []

func _ready() -> void:
  boundaries = [north_boundary, south_boundary, east_boundary, west_boundary]


## Update boundary positions and sizes based on scenario dimensions
func set_boundaries(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
  world_min_x = min_x
  world_max_x = max_x
  world_min_z = min_z
  world_max_z = max_z
  
  # Calculate dimensions
  var width = max_x - min_x
  var depth = max_z - min_z
  var center_x = (min_x + max_x) / 2.0
  var center_z = (min_z + max_z) / 2.0
  
  # Update north and south boundaries (walls at min_z and max_z, stretching along X axis)
  if north_boundary:
    north_boundary.position = Vector3(center_x, 5, min_z)
    var mesh = north_boundary.mesh as BoxMesh
    if mesh:
      mesh.size = Vector3(width, 10, 1)
  
  if south_boundary:
    south_boundary.position = Vector3(center_x, 5, max_z)
    var mesh = south_boundary.mesh as BoxMesh
    if mesh:
      mesh.size = Vector3(width, 10, 1)
  
  # Update east and west boundaries (walls at min_x and max_x, stretching along Z axis)
  if east_boundary:
    east_boundary.position = Vector3(max_x, 5, center_z)
    var mesh = east_boundary.mesh as BoxMesh
    if mesh:
      mesh.size = Vector3(1, 10, depth)
  
  if west_boundary:
    west_boundary.position = Vector3(min_x, 5, center_z)
    var mesh = west_boundary.mesh as BoxMesh
    if mesh:
      mesh.size = Vector3(1, 10, depth)
  
  MyLogger.info("WorldBoundaries", "Boundaries updated: X[%d, %d] Z[%d, %d]" % [int(min_x), int(max_x), int(min_z), int(max_z)])
