extends CharacterBody3D

@export var movement_speed: float = 2.0
@export var target_desired_distance: float = 4.0
@export var target_group: String = "targets"
@export var currency_reward: int = 10

@onready var attack: Attack = $Attack
@onready var health: Health = $Health
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_target: Node3D = null

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D


func _ready():
  # These values need to be adjusted for the actor's speed
  # and the navigation layout.
  navigation_agent.path_desired_distance = 0.5
  navigation_agent.target_desired_distance = target_desired_distance

  # Connect the death signal from Health component
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

  # Make sure to not await during _ready.
  actor_setup.call_deferred()


func choose_target():
  var targets := get_tree().get_nodes_in_group(target_group)
  if targets.size() == 0:
    current_target = null
    attack.cancel()
    # No targets available, stop the agent.
    navigation_agent.set_target_position(global_position)
    Logger.debug("Enemy", "No targets available.")
  else:
    # TODO : Implement logic to choose a target based on some criteria.
    current_target = targets[0]
    navigation_agent.set_target_position(current_target.global_position)


func actor_setup():
  # Wait for the first physics frame so the NavigationServer can sync.
  await get_tree().physics_frame

  # Now that the navigation map is no longer empty, set the movement target.
  choose_target()


func attack_target():
  if not current_target:
    Logger.debug("Enemy", "No current target to attack.")
    choose_target()
    if not current_target:
      return

  if not current_target.is_in_group(target_group):
    Logger.warn("Enemy", "Current target is not in the target group.")
    choose_target()
    if not current_target:
      return

  # check if the target is in range
  var distance_to_target := global_position.distance_to(current_target.global_position)
  if distance_to_target <= target_desired_distance:
    attack.perform_attack(current_target)


func _process(_delta: float) -> void:
  attack_target()

  # play animation based on movement speed
  if velocity.length() > 0.1:
    Logger.debug("Enemy.Animation", "Playing Run animation")
    animation_player.play("Run")
  else:
    Logger.debug("Enemy.Animation", "Playing Idle animation")
    animation_player.play("Idle")


func _physics_process(_delta):
  # Do not query when the map has never synchronized and is empty.
  if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
    Logger.debug("Enemy.Navigation", "Navigation map is empty, cannot navigate.")
    return
  if navigation_agent.is_navigation_finished():
    Logger.debug("Enemy.Navigation", "Navigation finished.")
    velocity = Vector3.ZERO
    move_and_slide()
    return

  var current_agent_position: Vector3 = global_position
  var next_path_position: Vector3 = navigation_agent.get_next_path_position()

  var direction := current_agent_position.direction_to(next_path_position)

  # face towards the direction of movement
  look_at(next_path_position, Vector3.UP, true)

  # Move directly without avoidance
  velocity = direction * movement_speed
  move_and_slide()


func _on_died():
  Logger.info("Enemy", "Enemy died, removing from scene")
  # Award currency to the player
  CurrencyManager.earn_currency(currency_reward)
  queue_free()


func _on_health_damaged(amount: int, hitpoints: int) -> void:
  Logger.debug("Enemy.Combat", "Enemy took %d damage. Remaining HP: %d" % [amount, hitpoints])
