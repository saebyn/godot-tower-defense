@tool
extends Entity_ShootingObstacle
class_name Entity_BasicTurret

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var rotation_speed: float = 12.5 # Degrees per second
@export var idle_animation: String = "idle_turret"
@export var aim_margin: float = 0.1 # Radians within which we consider ourselves "aimed" at the target
@onready var turret_top_mesh: MeshInstance3D = $turret/Top

func _process(delta: float) -> void:
  if current_target:
    # TODO animation handling causes us not to rotate properly - fix this
    #if animation_player.current_animation:
    #  animation_player.stop()
    #  animation_player.play("RESET")
    var target_direction: Vector3 = (current_target.global_position - turret_top_mesh.global_position).normalized()
    var aim_yaw_angle: float = atan2(-target_direction.x, -target_direction.z) + PI / 2
    var turret_yaw_angle: float = turret_top_mesh.rotation.y

    var rotation_delta: float = deg_to_rad(rotation_speed) * delta
    var lerp_weight: float = clamp(rotation_delta, 0, 1)

    var lerped_target_angle := lerp_angle(
      turret_yaw_angle,
      aim_yaw_angle,
      # TODO this shouldn't slow down as it gets closer - fix this
      lerp_weight
    )

    var rotation_amount: float = lerped_target_angle - turret_yaw_angle

    if abs(rotation_amount) > aim_margin:
      Logger.debug("BasicTurret", "Rotating turret by %f radians towards target." % rotation_amount)
      ready_to_attack = false
      turret_top_mesh.rotate_y(rotation_amount)
    else:
      Logger.debug("BasicTurret", "Turret aligned with target.")
      ready_to_attack = true
  else:
    Logger.trace("BasicTurret", "No target detected.")
    ready_to_attack = false
    #animation_player.play(idle_animation)