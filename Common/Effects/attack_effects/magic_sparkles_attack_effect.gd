## MagicSparklesAttackEffect.gd
##
## Magic sparkles attack effect with glittery particles and magical appearance.
extends BaseAttackEffect

@export var sparkle_colors: Array[Color] = [Color.CYAN, Color.MAGENTA, Color.YELLOW, Color.WHITE]
@export var magic_speed: float = 25.0

@onready var sparkle_particles: GPUParticles3D = $SparkleParticles
@onready var magic_core: MeshInstance3D = $MagicCore
@onready var impact_particles: GPUParticles3D = $ImpactParticles

func _ready():
  ## Create magic core visual
  if magic_core:
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = 0.08
    sphere_mesh.height = 0.16
    magic_core.mesh = sphere_mesh
    
    ## Create shimmering material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.WHITE
    material.emission_enabled = true
    material.emission = Color.CYAN * 0.7
    material.metallic = 0.8
    material.roughness = 0.2
    magic_core.set_surface_override_material(0, material)
  
  ## Configure sparkle particles
  if sparkle_particles:
    _setup_sparkle_particles()
  
  ## Configure impact particles
  if impact_particles:
    _setup_impact_particles()

func _setup_sparkle_particles():
  var material = ParticleProcessMaterial.new()
  material.direction = Vector3(0, 0, 0)
  material.spread = 30.0
  material.initial_velocity_min = 1.0
  material.initial_velocity_max = 3.0
  material.gravity = Vector3.ZERO
  material.scale_min = 0.05
  material.scale_max = 0.15
  
  sparkle_particles.process_material = material
  sparkle_particles.amount = 30
  sparkle_particles.lifetime = 0.8
  sparkle_particles.emitting = true

func _setup_impact_particles():
  var material = ParticleProcessMaterial.new()
  material.direction = Vector3(0, 1, 0)
  material.spread = 60.0
  material.initial_velocity_min = 3.0
  material.initial_velocity_max = 8.0
  material.gravity = Vector3(0, -2.0, 0)
  material.scale_min = 0.1
  material.scale_max = 0.4
  
  impact_particles.process_material = material
  impact_particles.amount = 60
  impact_particles.lifetime = 1.2
  impact_particles.emitting = false

func _animate_effect(from_pos: Vector3, to_pos: Vector3) -> void:
  ## Store positions for arc calculation
  _from_pos = from_pos
  _to_pos = to_pos
  _mid_pos = (_from_pos + _to_pos) / 2.0
  _mid_pos.y += 1.0
  
  ## Calculate travel time
  var distance = from_pos.distance_to(to_pos)
  var travel_time = distance / magic_speed
  
  ## Start sparkle trail
  if sparkle_particles:
    sparkle_particles.emitting = true
  
  ## Create tween for magic movement with slight arc
  effect_tween = create_tween()
  
  ## Use the arc movement
  effect_tween.tween_method(_set_arc_position, 0.0, 1.0, travel_time)
  
  ## When magic reaches target, trigger impact
  effect_tween.finished.connect(_trigger_impact)

var _from_pos: Vector3
var _to_pos: Vector3
var _mid_pos: Vector3

func _set_arc_position(progress: float):
  ## Quadratic bezier curve for arc movement
  var pos = _from_pos.lerp(_mid_pos, progress).lerp(_mid_pos.lerp(_to_pos, progress), progress)
  global_position = pos

func _trigger_impact():
  ## Hide magic core and stop sparkles
  if magic_core:
    magic_core.visible = false
  if sparkle_particles:
    sparkle_particles.emitting = false
  
  ## Start impact particles
  if impact_particles:
    impact_particles.emitting = true
    ## Wait for impact to finish
    await get_tree().create_timer(impact_particles.lifetime).timeout
  
  _finish_effect()
