extends CharacterBody3D

@export var movement_speed: float = 2.0
@export var target_desired_distance: float = 4.0
@export var damage_amount: int = 10
@export var damage_cooldown: float = 1.0
@export var target_group: String = "targets"

var current_target: Node3D = null
var attacking: bool = false

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var attack_timer: Timer = $AttackTimer

func _ready():
  # These values need to be adjusted for the actor's speed
  # and the navigation layout.
  navigation_agent.path_desired_distance = 0.5
  navigation_agent.target_desired_distance = target_desired_distance

  # Make sure to not await during _ready.
  actor_setup.call_deferred()


func choose_target():
  var targets := get_tree().get_nodes_in_group(target_group)
  if targets.size() == 0:
    current_target = null
    # No targets available, stop the agent.
    navigation_agent.set_target_position(global_position)
    print("No targets available.")
  else:
    # TODO : Implement logic to choose a target based on some criteria.
    current_target = targets[0]
    navigation_agent.set_target_position(current_target.global_position)


func actor_setup():
  # Wait for the first physics frame so the NavigationServer can sync.
  await get_tree().physics_frame

  # Now that the navigation map is no longer empty, set the movement target.
  choose_target()

func _on_AttackTimer_timeout():
  print("Attack timer timed out, attacking target.")
  if current_target:
    current_target.hit(damage_amount)
  attacking = false

func attack_target():
  if not current_target:
    print("No current target to attack.")
    choose_target()
    if not current_target:
      return
  
  if not current_target.is_in_group(target_group):
    print("Current target is not in the target group.")
    choose_target()
    if not current_target:
      return

  # check if the target is in range
  var distance_to_target := global_position.distance_to(current_target.global_position)
  if distance_to_target <= target_desired_distance:
    if not attacking:
      print("Target is in range, attacking.")
      # Attack the target
      attacking = true
      attack_timer.start(damage_cooldown)

func _process(_delta: float) -> void:
  attack_target()


func _physics_process(_delta):
  # Do not query when the map has never synchronized and is empty.
  if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
    return
  if navigation_agent.is_navigation_finished():
    return

  var current_agent_position: Vector3 = global_position
  var next_path_position: Vector3 = navigation_agent.get_next_path_position()

  var direction := current_agent_position.direction_to(next_path_position)

  # face towards the direction of movement
  look_at(next_path_position, Vector3.UP, true)

  # Move directly without avoidance
  velocity = direction * movement_speed
  move_and_slide()
