"""
# BulletAttackEffect.gd

Bullet attack effect that creates a projectile moving from source to target.
"""
extends BaseAttackEffect

@export var bullet_speed: float = 20.0
@export var bullet_color: Color = Color.YELLOW

@onready var bullet_mesh: MeshInstance3D = $BulletMesh

func _ready():
	# Create bullet visual
	if bullet_mesh:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.1
		sphere_mesh.height = 0.2
		bullet_mesh.mesh = sphere_mesh
		
		# Create material for bullet
		var material = StandardMaterial3D.new()
		material.albedo_color = bullet_color
		material.emission_enabled = true
		material.emission = bullet_color * 0.5
		bullet_mesh.set_surface_override_material(0, material)

func _animate_effect(from_pos: Vector3, to_pos: Vector3) -> void:
	# Calculate travel time based on distance and speed
	var distance = from_pos.distance_to(to_pos)
	var travel_time = distance / bullet_speed
	
	# Create tween for bullet movement
	effect_tween = create_tween()
	effect_tween.tween_property(self, "global_position", to_pos, travel_time)
	
	# Connect to finish when tween completes
	effect_tween.finished.connect(_finish_effect)