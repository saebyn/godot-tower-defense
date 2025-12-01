extends Entity_PlaceableObstacle
class_name Entity_ShootingObstacle

const SHOOTING_OBSTACLES_GROUP: String = "shooting_obstacles"

@export var enemy_group: String = "enemies"
@export var attack_range: float = 15.0
@export var detection_range: float = 25.0
@export var detection_interval: float = 0.5

## The currently tracked target enemy, updated by detection timer
var current_target: Node3D = null
## Whether the obstacle is ready to attack (e.g., turret is aimed at target)
var ready_to_attack: bool = true
## Whether the current target is within attack range (updated by detection logic)
var can_attack_current_target: bool = false
var attack: Component_Attack
## Whether this obstacle is currently being hovered over by the mouse
var _is_hovered: bool = false
@onready var detection_timer: Timer = $DetectionTimer
@onready var attack_range_indicator: MeshInstance3D = $RangePreview

func _ready():
  # Call parent _ready first
  super._ready()
  
  # Add to shooting obstacles group for range preview coordination
  add_to_group(SHOOTING_OBSTACLES_GROUP)
  
  # Find Attack component via metadata
  if has_meta("attack_component"):
    attack = get_meta("attack_component")
  
  # Set damage source for obstacle attacks
  if attack:
    attack.damage_source = "obstacle"

  # Validate ranges
  if detection_range < attack_range:
    MyLogger.warn("ShootingObstacle", "detection_range (%f) is less than attack_range (%f), adjusting detection_range" % [detection_range, attack_range])
    detection_range = attack_range

  # Set up detection timer
  if detection_timer:
    detection_timer.wait_time = detection_interval
    detection_timer.timeout.connect(_detect_and_attack_enemies)
    detection_timer.start()

  # Scale the range indicator properly (do this once at ready)
  # SphereMesh has a default radius of 0.5. To get a sphere with radius = attack_range,
  # we need to scale it by attack_range / 0.5 = attack_range * 2.
  if attack_range_indicator:
    attack_range_indicator.scale = Vector3(attack_range * 2, attack_range * 2, attack_range * 2)

  MyLogger.info("ShootingObstacle", "Shooting obstacle initialized with attack range: %f" % attack_range)


## Overrides the parent method to set up the attack range indicator for placement preview.
## Scales and displays the attack_range_indicator mesh to show the attack range during placement.
func _enter_placement_mode() -> void:
  super._enter_placement_mode()

  # Show the range indicator during placement mode
  if attack_range_indicator:
    attack_range_indicator.visible = true

## Hides the range indicator when exiting placement mode.
func _exit_placement_mode() -> void:
  super._exit_placement_mode()

  if attack_range_indicator:
    attack_range_indicator.visible = false


## Shows the attack range indicator for this shooting obstacle.
## Used during placement mode to show all existing turret ranges, or on hover.
func show_range_indicator() -> void:
  if attack_range_indicator:
    attack_range_indicator.visible = true


## Hides the attack range indicator for this shooting obstacle.
## Used when exiting placement mode or when mouse stops hovering.
## @param force When true, hides the indicator even if currently being hovered (used for placement mode exit)
func hide_range_indicator(force: bool = false) -> void:
  # Don't hide if currently being hovered, unless forced
  if _is_hovered and not force:
    return
  if attack_range_indicator:
    attack_range_indicator.visible = false


## Called when mouse enters this obstacle's collision shape.
func on_mouse_enter() -> void:
  _is_hovered = true
  show_range_indicator()


## Called when mouse exits this obstacle's collision shape.
func on_mouse_exit() -> void:
  _is_hovered = false
  hide_range_indicator()


func _detect_and_attack_enemies():
  var result = find_nearest_enemy_in_range()
  current_target = result[0]
  can_attack_current_target = result[1]
  if current_target and can_attack_current_target and ready_to_attack:
    MyLogger.debug("ShootingObstacle", "Attacking enemy at distance: %f" % global_position.distance_to(current_target.global_position))
    attack.perform_attack(current_target)

func find_nearest_enemy_in_range() -> Array:
  var enemies := get_tree().get_nodes_in_group(enemy_group)
  var nearest_enemy: Node3D = null
  var nearest_distance: float = detection_range
  var can_attack := false
  
  for enemy in enemies:
    if not enemy or not is_instance_valid(enemy):
      continue
      
    var distance := global_position.distance_to(enemy.global_position)
    if distance < nearest_distance:
      nearest_distance = distance
      nearest_enemy = enemy
      if distance <= attack_range:
        can_attack = true
  
  return [nearest_enemy, can_attack]

func _on_died(damage_source: String = "unknown") -> void:
  MyLogger.info("ShootingObstacle", "Shooting obstacle destroyed by: %s" % damage_source)
  # Stop detection timer before destruction
  if detection_timer:
    detection_timer.stop()
  queue_free()