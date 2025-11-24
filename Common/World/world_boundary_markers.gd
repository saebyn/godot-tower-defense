extends Node3D
## Visual boundary markers that become visible when camera approaches world edges

@export var camera: Camera3D ## The camera to track
@export var fade_distance: float = 50.0 ## Distance from boundary at which markers start to fade in
@export var world_min_x: float = -200.0
@export var world_max_x: float = 200.0
@export var world_min_z: float = -200.0
@export var world_max_z: float = 200.0
@export var max_boundary_opacity: float = 0.5 ## Maximum opacity for boundary markers (0.0 to 1.0)

@onready var north_boundary = $Boundaries/NorthBoundary
@onready var south_boundary = $Boundaries/SouthBoundary
@onready var east_boundary = $Boundaries/EastBoundary
@onready var west_boundary = $Boundaries/WestBoundary

var boundaries: Array[MeshInstance3D] = []


func _ready():
  # Collect all boundary markers
  boundaries = [north_boundary, south_boundary, east_boundary, west_boundary]
  
  # Set initial transparency to fully transparent
  for boundary in boundaries:
    _set_boundary_transparency(boundary, 0.0)


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
    # Enable transparency if needed
    if transparency > 0:
      mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
      mat.albedo_color.a = transparency * max_boundary_opacity
    else:
      mat.albedo_color.a = 0.0
      mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
