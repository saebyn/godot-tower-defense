## LaserBeamAttackEffect.gd
##
## Instant laser beam attack effect.
extends BaseAttackEffect

@export var beam_color: Color = Color.RED
@export var beam_width: float = 0.05
@export var beam_duration: float = 0.3

@onready var beam_mesh: MeshInstance3D = $BeamMesh
@onready var impact_particles: GPUParticles3D = $ImpactParticles

func _ready():
	## Configure impact particles
	if impact_particles:
		_setup_impact_particles()

func _setup_impact_particles():
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 6.0
	material.gravity = Vector3(0, -5.0, 0)
	material.scale_min = 0.1
	material.scale_max = 0.3
	
	impact_particles.process_material = material
	impact_particles.amount = 40
	impact_particles.lifetime = 0.8
	impact_particles.emitting = false

func _animate_effect(from_pos: Vector3, to_pos: Vector3) -> void:
	## Create laser beam instantly
	_create_beam(from_pos, to_pos)
	
	## Start impact particles at target
	if impact_particles:
		impact_particles.global_position = to_pos
		impact_particles.emitting = true
	
	## Create tween for beam fade out
	effect_tween = create_tween()
	effect_tween.set_parallel(true)
	
	## Fade out beam
	if beam_mesh:
		var material = beam_mesh.get_surface_override_material(0)
		if material:
			effect_tween.tween_property(material, "albedo_color:a", 0.0, beam_duration)
			effect_tween.tween_property(material, "emission:a", 0.0, beam_duration)
	
	## Wait for beam duration then finish
	effect_tween.tween_callback(_finish_effect).set_delay(beam_duration)

func _create_beam(from_pos: Vector3, to_pos: Vector3):
	if not beam_mesh:
		return
	
	## Calculate beam direction and distance
	var direction = (to_pos - from_pos).normalized()
	var distance = from_pos.distance_to(to_pos)
	
	## Create cylinder mesh for beam
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = distance
	cylinder_mesh.top_radius = beam_width
	cylinder_mesh.bottom_radius = beam_width
	beam_mesh.mesh = cylinder_mesh
	
	## Position beam
	beam_mesh.global_position = (from_pos + to_pos) / 2.0
	beam_mesh.look_at(to_pos, Vector3.UP)
	beam_mesh.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	## Create glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = beam_color
	material.emission_enabled = true
	material.emission = beam_color * 1.5
	material.flags_transparent = true
	material.flags_unshaded = true
	beam_mesh.set_surface_override_material(0, material)