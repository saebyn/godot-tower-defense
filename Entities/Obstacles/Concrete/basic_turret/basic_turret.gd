@tool
class_name Entity_BasicTurret
extends Entity_ShootingObstacle

## A turret obstacle that rotates to track and attack enemies.
## The turret smoothly rotates its top mesh towards the nearest enemy target
## and only attacks when properly aligned within the aim_margin threshold.

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var rotation_speed: float = 360 # Degrees per second
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

    var rotation_amount: float = get_angle_difference(turret_yaw_angle, aim_yaw_angle)
    var rotation_amount_delta = clampf(rotation_amount, -rotation_delta, rotation_delta)

    if abs(rotation_amount) > aim_margin:
      Logger.trace("BasicTurret", "Rotating turret by %f radians towards target (clamped from %f)" % [rotation_amount_delta, rotation_amount])
      ready_to_attack = false
      turret_top_mesh.rotate_y(rotation_amount_delta)
    else:
      Logger.trace("BasicTurret", "Turret aligned with target.")
      ready_to_attack = true
  else:
    Logger.trace("BasicTurret", "No target detected.")
    ready_to_attack = false
    #animation_player.play(idle_animation)


func get_angle_difference(angle1: float, angle2: float) -> float:
  var diff: float = fmod(angle2 - angle1 + PI, TAU) - PI
  return diff
