"""
# FireballAttackEffect.gd

Fireball attack effect with particle trail and explosion.
"""
extends BaseAttackEffect

@export var fireball_speed: float = 15.0
@export var explosion_radius: float = 2.0

@onready var fireball_mesh: MeshInstance3D = $FireballMesh
@onready var trail_particles: GPUParticles3D = $TrailParticles
@onready var explosion_particles: GPUParticles3D = $ExplosionParticles

func _ready():
	# Create fireball visual
	if fireball_mesh:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.15
		sphere_mesh.height = 0.3
		fireball_mesh.mesh = sphere_mesh
		
		# Create glowing orange material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.ORANGE_RED
		material.emission_enabled = true
		material.emission = Color.ORANGE_RED * 0.8
		fireball_mesh.set_surface_override_material(0, material)
	
	# Configure trail particles
	if trail_particles:
		_setup_trail_particles()
	
	# Configure explosion particles
	if explosion_particles:
		_setup_explosion_particles()

func _setup_trail_particles():
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, -1)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.1
	material.scale_max = 0.3
	
	trail_particles.process_material = material
	trail_particles.amount = 50
	trail_particles.lifetime = 0.5
	trail_particles.emitting = true

func _setup_explosion_particles():
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3(0, -9.8, 0)
	material.scale_min = 0.2
	material.scale_max = 0.8
	
	explosion_particles.process_material = material
	explosion_particles.amount = 100
	explosion_particles.lifetime = 1.0
	explosion_particles.emitting = false

func _animate_effect(from_pos: Vector3, to_pos: Vector3) -> void:
	# Calculate travel time
	var distance = from_pos.distance_to(to_pos)
	var travel_time = distance / fireball_speed
	
	# Start trail particles
	if trail_particles:
		trail_particles.emitting = true
	
	# Create tween for fireball movement
	effect_tween = create_tween()
	effect_tween.tween_property(self, "global_position", to_pos, travel_time)
	
	# When fireball reaches target, trigger explosion
	effect_tween.finished.connect(_trigger_explosion)

func _trigger_explosion():
	# Hide fireball and stop trail
	if fireball_mesh:
		fireball_mesh.visible = false
	if trail_particles:
		trail_particles.emitting = false
	
	# Start explosion particles
	if explosion_particles:
		explosion_particles.emitting = true
		# Wait for explosion to finish
		await get_tree().create_timer(explosion_particles.lifetime).timeout
	
	_finish_effect()