extends CharacterBody3D

@export var movement_speed: float = 2.0
@export var target_desired_distance: float = 4.0
@export var target_group: String = "targets"
@export var obstacle_group: String = "obstacles"
@export var obstacle_attack_range: float = 6.0
@export var scrap_reward: int = 10 ## Scrap awarded when enemy dies (can be 0)
@export var xp_reward: int = 10 ## XP awarded when enemy dies (always given)
@export var enemy_type: String = "base_enemy" ## Type identifier for stats tracking

var attack: Attack
var health: Health

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_target: Node3D = null

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
  # Find components via metadata
  if has_meta("attack_component"):
    attack = get_meta("attack_component")
  if has_meta("health_component"):
    health = get_meta("health_component")
  
  # These values need to be adjusted for the actor's speed
  # and the navigation layout.
  navigation_agent.path_desired_distance = 0.5
  navigation_agent.target_desired_distance = target_desired_distance

  # Connect the death signal from Health component
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

  # Make sure to not await during _ready.
  _actor_setup.call_deferred()

# EnemyTypeResource
func load_resource(resource: EnemyTypeResource) -> void:
  ready.connect(func() -> void:
    Logger.debug("Enemy", "Loading enemy resource: %s" % resource.name)
    # Override properties from resource
    movement_speed = resource.speed
    target_desired_distance = resource.target_desired_distance
    obstacle_attack_range = resource.obstacle_attack_range
    scrap_reward = resource.scrap_reward
    xp_reward = resource.xp_reward
    enemy_type = resource.enemy_type

    # Update navigation agent desired distance
    navigation_agent.target_desired_distance = target_desired_distance

    # Update scale
    scale = Vector3.ONE * resource.scale_multiplier

    # Update health
    if health:
      health.hitpoints = resource.hitpoints
      health.max_hitpoints = resource.hitpoints

    # Update attack component
    if attack:
      attack.damage_amount = resource.damage_amount
      attack.damage_cooldown = resource.damage_cooldown
      attack.damage_source = resource.enemy_type
  )

func _choose_target():
  var targets := get_tree().get_nodes_in_group(target_group)
  if targets.size() == 0:
    current_target = null
    attack.cancel()
    # No targets available, stop the agent.
    navigation_agent.set_target_position(global_position)
    Logger.trace("Enemy", "No targets available.")
  else:
    # TODO : Implement logic to choose a target based on some criteria.
    current_target = targets[0]
    navigation_agent.set_target_position(current_target.global_position)


func _find_nearest_obstacle_in_range() -> Node3D:
  var obstacles := get_tree().get_nodes_in_group(obstacle_group)
  var nearest_obstacle: Node3D = null
  var nearest_distance: float = obstacle_attack_range + 1.0 # Start beyond max range
  
  for obstacle in obstacles:
    if not obstacle or not is_instance_valid(obstacle):
      continue
      
    var distance := global_position.distance_to(obstacle.global_position)
    if distance <= obstacle_attack_range and distance < nearest_distance:
      nearest_distance = distance
      nearest_obstacle = obstacle
  
  return nearest_obstacle


func _actor_setup():
  # Wait for the first physics frame so the NavigationServer can sync.
  await get_tree().physics_frame

  # Now that the navigation map is no longer empty, set the movement target.
  _choose_target()


func _attack_target():
  if not current_target:
    Logger.trace("Enemy", "No current target to attack.")
    _choose_target()
    if not current_target:
      return
  
  if not current_target.is_in_group(target_group):
    Logger.warn("Enemy", "Current target is not in the target group.")
    _choose_target()
    if not current_target:
      return

  # Attack primary target if in range (higher priority)
  var distance_to_target := global_position.distance_to(current_target.global_position)
  if distance_to_target <= target_desired_distance:
      attack.perform_attack(current_target)
      return

  # If no targets in range, check for nearby obstacles to attack
  var nearby_obstacle = _find_nearest_obstacle_in_range()
  if nearby_obstacle:
    Logger.debug("Enemy", "Attacking nearby obstacle at distance: %f" % global_position.distance_to(nearby_obstacle.global_position))
    attack.perform_attack(nearby_obstacle)
    return


func _process(_delta: float) -> void:
  _attack_target()

  # play animation based on movement speed
  if velocity.length() > 0.1:
    animation_player.play("Run")
  else:
    animation_player.play("Idle")


func _physics_process(_delta):
  # Do not query when the map has never synchronized and is empty.
  if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
    Logger.debug("Enemy.Navigation", "Navigation map is empty, cannot navigate.")
    return
  if navigation_agent.is_navigation_finished():
    Logger.trace("Enemy.Navigation", "Navigation finished.")
    velocity = Vector3.ZERO
    move_and_slide()
    return

  var next_path_position: Vector3 = navigation_agent.get_next_path_position()

  # Move directly without avoidance
  var direction := global_position.direction_to(next_path_position)
  velocity = direction * movement_speed

  # if we are moving, face the direction we are moving
  if velocity.length() > 0.01:
    look_at(next_path_position, Vector3.UP, true)

  move_and_slide()


func _on_died(damage_source: String = "unknown"):
  Logger.info("Enemy", "Enemy (%s) died from %s, removing from scene" % [enemy_type, damage_source])
  
  # Track the defeat in stats system
  if StatsManager:
    var defeated_by_hand = (damage_source == "player")
    StatsManager.track_enemy_defeated(enemy_type, defeated_by_hand)
  
  # Always award XP to the player
  CurrencyManager.earn_xp(xp_reward)
  
  # Award scrap if the enemy gives any
  if scrap_reward > 0:
    CurrencyManager.earn_scrap(scrap_reward)
  
  queue_free()

func _on_health_damaged(amount: int, hitpoints: int, damage_source: String = "unknown") -> void:
  Logger.debug("Enemy.Combat", "Enemy (%s) took %d damage from %s. Remaining HP: %d" % [enemy_type, amount, damage_source, hitpoints])
