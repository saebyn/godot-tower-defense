@tool
extends Entity_ShootingObstacle
class_name Entity_BasicTurret

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var rotation_speed: float = 12.5 # Degrees per second
@onready var turret_top_mesh: MeshInstance3D = $turret/Top

func _process(delta: float) -> void:
  if current_target:
    # TODO animation handling causes us not to rotate properly - fix this
    #if animation_player.current_animation:
    #  animation_player.stop()
    #  animation_player.play("RESET")
    var target_direction: Vector3 = (current_target.global_position - turret_top_mesh.global_position).normalized()
    var target_yaw: float = atan2(-target_direction.x, -target_direction.z) + PI / 2
    var current_rotation: float = turret_top_mesh.rotation.y
    var rotation_to_target: float = target_yaw - current_rotation
    var max_rotation: float = deg_to_rad(rotation_speed) * delta

    var lerped_target_angle := lerp_angle(
      current_rotation,
      target_yaw,
      # TODO this shouldn't slow down as it gets closer - fix this
      clamp(max_rotation / abs(rotation_to_target), 0, 1)
    )

    var rotation_amount: float = lerped_target_angle - current_rotation

    if abs(rotation_amount) > 0.001:
      Logger.debug("BasicTurret", "Rotating turret by %f radians towards target." % rotation_amount)
      ready_to_attack = false
      turret_top_mesh.rotate_y(rotation_amount)
    else:
      Logger.debug("BasicTurret", "Turret aligned with target.")
      ready_to_attack = true
  else:
    Logger.debug("BasicTurret", "No target detected.")
    ready_to_attack = false
    #animation_player.play("idle_turret")