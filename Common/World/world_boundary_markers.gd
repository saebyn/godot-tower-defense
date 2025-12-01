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


func _ready():
  # Collect all boundary markers
  boundaries = [north_boundary, south_boundary, east_boundary, west_boundary]
  
  # Set initial transparency to fully transparent
  for boundary in boundaries:
    _set_boundary_transparency(boundary, 0.0)


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
  
  Logger.info("WorldBoundaries", "Boundaries updated: X[%d, %d] Z[%d, %d]" % [int(min_x), int(max_x), int(min_z), int(max_z)])


func _process(_delta: float):
  if not camera:
    return
  
  # Get the camera's orbit center (where it's looking at the ground)
  var camera_forward = -camera.transform.basis.z.normalized()
  var ground_plane = Plane(Vector3.UP, 0)
  var ray_origin = camera.global_position
  var ray_direction = camera_forward
  var intersection = ground_plane.intersects_ray(ray_origin, ray_direction)
  
  var camera_ground_pos: Vector3
  if intersection:
    camera_ground_pos = intersection
  else:
    # Fallback when camera ray doesn't intersect ground plane (camera pointing away from ground)
    camera_ground_pos = Vector3(camera.global_position.x, 0, camera.global_position.z)
  
  # Calculate distance to each boundary and update transparency
  _update_boundary_visibility(north_boundary, camera_ground_pos.z, world_min_z, true)
  _update_boundary_visibility(south_boundary, camera_ground_pos.z, world_max_z, false)
  _update_boundary_visibility(east_boundary, camera_ground_pos.x, world_max_x, false)
  _update_boundary_visibility(west_boundary, camera_ground_pos.x, world_min_x, true)


func _update_boundary_visibility(boundary: MeshInstance3D, camera_pos: float, boundary_pos: float, is_min_boundary: bool):
  # Calculate distance from camera to boundary
  var distance: float
  if is_min_boundary:
    distance = camera_pos - boundary_pos
  else:
    distance = boundary_pos - camera_pos
  
  # Calculate transparency based on distance (0 = invisible, 1 = fully visible)
  var transparency: float
  if distance <= 0:
    # Camera is past the boundary
    transparency = 1.0
  elif distance >= fade_distance:
    # Camera is far from boundary
    transparency = 0.0
  else:
    # Camera is approaching - fade in gradually
    transparency = 1.0 - (distance / fade_distance)
  
  _set_boundary_transparency(boundary, transparency)


func _set_boundary_transparency(boundary: MeshInstance3D, transparency: float):
  if not boundary:
    return
  
  # Get the material from the mesh instance
  var mat = boundary.get_surface_override_material(0) as StandardMaterial3D
  if mat:
    # Keep transparency mode enabled always - just update alpha value
    # This avoids unnecessary material mode updates every frame
    mat.albedo_color.a = transparency * max_boundary_opacity
