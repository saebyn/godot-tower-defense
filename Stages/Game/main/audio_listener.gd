extends AudioListener3D

## Audio listener that follows the camera's ground focus point
## In an orthographic/isometric view, this approximates where the viewer's attention is

@export var camera: Camera3D

func _ready() -> void:
	if not camera:
		MyLogger.warn("AudioListener", "No camera assigned to audio listener")
		return
	
	# Enable this as the active listener
	make_current()
	MyLogger.info("AudioListener", "Audio listener initialized and activated")


func _process(_delta: float) -> void:
	if not camera:
		return
	
	# Get the orbit_center from the camera, which represents the ground point
	# the camera is focused on - this is where the "viewer" is conceptually looking
	# The orbit_center is updated by the camera script whenever the camera moves
	var orbit_center = camera.orbit_center
	
	# Position the audio listener at the ground focus point
	# This makes spatial audio sound relative to where the player is looking
	global_position = orbit_center
