extends PlaceableObstacle
class_name ShootingObstacle

@export var enemy_group: String = "enemies"
@export var attack_range: float = 15.0
@export var detection_interval: float = 0.5

var attack: Attack
@onready var detection_timer: Timer = $DetectionTimer

func _ready():
  # Call parent _ready first
  super._ready()
  
  # Find Attack component via metadata
  if has_meta("attack_component"):
    attack = get_meta("attack_component")
  
  # Set damage source for obstacle attacks
  if attack:
    attack.damage_source = "obstacle"
  
  # Set up detection timer
  if detection_timer:
    detection_timer.wait_time = detection_interval
    detection_timer.timeout.connect(_detect_and_attack_enemies)
    detection_timer.start()
  
  Logger.info("ShootingObstacle", "Shooting obstacle initialized with attack range: %f" % attack_range)

func _detect_and_attack_enemies():
  var nearest_enemy = find_nearest_enemy_in_range()
  if nearest_enemy:
    Logger.debug("ShootingObstacle", "Attacking enemy at distance: %f" % global_position.distance_to(nearest_enemy.global_position))
    attack.perform_attack(nearest_enemy)

func find_nearest_enemy_in_range() -> Node3D:
  var enemies := get_tree().get_nodes_in_group(enemy_group)
  var nearest_enemy: Node3D = null
  var nearest_distance: float = attack_range + 1.0 # Start beyond max range
  
  for enemy in enemies:
    if not enemy or not is_instance_valid(enemy):
      continue
      
    var distance := global_position.distance_to(enemy.global_position)
    if distance <= attack_range and distance < nearest_distance:
      nearest_distance = distance
      nearest_enemy = enemy
  
  return nearest_enemy

func _on_died(damage_source: String = "unknown") -> void:
  Logger.info("ShootingObstacle", "Shooting obstacle destroyed by: %s" % damage_source)
  # Stop detection timer before destruction
  if detection_timer:
    detection_timer.stop()
  queue_free()