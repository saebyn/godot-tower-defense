extends CharacterBody3D

const CMP_EPSILON = 0.001

@export var movement_speed: float = 2.0
@export var rotation_speed: float = PI / 3.0 # Radians per second, adjust for faster/slower turning. This is independent of movement speed to ensure the enemy can always turn towards the target effectively.
@export var path_desired_distance: float = 0.5
@export var target_desired_distance: float = 4.0
@export var target_attack_range: float = 2.0
@export var survivor_group: String = "survivors"
@export var building_group: String = "buildings"
@export var building_attack_range: float = 6.0
@export var scrap_reward: int = 10 ## Scrap awarded when enemy dies (can be 0)
@export var xp_reward: int = 10 ## XP awarded when enemy dies (always given)
@export var enemy_type: String = "base_enemy" ## Type identifier for stats tracking

@export_group("Animations")
@export var idle_animation: String = "zombie_library/zombie_idle"
@export var run_animation: String = "zombie_library/zombie_running"

var attack: Component_Attack
var health: Component_Health
var damage_numbers: Component_DamageNumbers

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var mesh_instance: MeshInstance3D = $characterMedium

var current_target: Node3D = null
var fallback_building_target: Node3D = null # Used when direct path to target is blocked

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
  # Find components via metadata
  if has_meta("attack_component"):
    attack = get_meta("attack_component")
  if has_meta("health_component"):
    health = get_meta("health_component")
  if has_meta("damage_numbers_component"):
    damage_numbers = get_meta("damage_numbers_component")
  
  # These values need to be adjusted for the actor's speed
  # and the navigation layout.
  navigation_agent.path_desired_distance = path_desired_distance
  navigation_agent.target_desired_distance = target_desired_distance

  # Sync NavigationAgent3D debug display with the project setting
  navigation_agent.debug_enabled = ProjectSettings.get_setting("zom_nom_defense/debug/show_navigation_paths", false)

  # Connect the death signal from Health component
  if health:
    health.died.connect(_on_died)
    health.damaged.connect(_on_health_damaged)

  # Make sure to not await during _ready.
  _actor_setup.call_deferred()

# Resource_EnemyType
func load_resource(resource: Resource_EnemyType) -> void:
  ready.connect(func() -> void:
    MyLogger.debug("Enemy", "Loading enemy resource: %s" % resource.name)
    # Override properties from resource
    movement_speed = resource.speed
    target_desired_distance = resource.target_desired_distance
    target_attack_range = resource.target_attack_range
    building_attack_range = resource.building_attack_range
    scrap_reward = resource.scrap_reward
    xp_reward = resource.xp_reward
    enemy_type = resource.enemy_type

    # Update skin material if specified
    if resource.skin_material and mesh_instance:
      mesh_instance.set_surface_override_material(0, resource.skin_material)

    # Update navigation agent desired distance
    navigation_agent.target_desired_distance = target_desired_distance

    # Update scale
    scale = Vector3.ONE * resource.scale_multiplier

    # Update health
    if health:
      health.hitpoints = resource.hitpoints
      health.max_hitpoints = resource.hitpoints
      health._update_display()

    # Update attack component
    if attack:
      attack.damage_amount = resource.damage_amount
      attack.attack_speed = resource.attack_speed
      attack.damage_source = resource.enemy_type

      if resource.attack_effect:
        attack.attack_effect = resource.attack_effect

  , Object.CONNECT_ONE_SHOT)

func _choose_target():
  var targets := get_tree().get_nodes_in_group(survivor_group)
  if targets.size() == 0:
    current_target = null
    attack.cancel()
    # No targets available, stop the agent.
    navigation_agent.set_target_position(global_position)
    MyLogger.trace("Enemy", "No targets available.")
  else:
    # TODO : Implement logic to choose a target based on some criteria.
    current_target = targets.pick_random()
    MyLogger.debug("Enemy", "Chose new target: %s" % current_target.name)
    navigation_agent.set_target_position(current_target.global_position)


func _find_nearest_building_in_range() -> Node3D:
  var buildings := get_tree().get_nodes_in_group(building_group)
  var nearest_building: Node3D = null
  var nearest_distance: float = building_attack_range + 1.0 # Start beyond max range
  
  for building in buildings:
    if not building or not is_instance_valid(building):
      continue
      
    var distance := global_position.distance_to(building.global_position)
    if distance <= building_attack_range and distance < nearest_distance:
      nearest_distance = distance
      nearest_building = building
  
  return nearest_building


func _find_building_closest_to_target() -> Node3D:
  """Find the building that is closest to the current target.
  This is used as a fallback when the zombie cannot path directly to the target."""
  if not current_target:
    return null
  
  var buildings := get_tree().get_nodes_in_group(building_group)
  if buildings.is_empty():
    return null
  
  var closest_building: Node3D = null
  var closest_distance: float = INF
  
  for building in buildings:
    if not building or not is_instance_valid(building):
      continue
    
    var distance_to_target: float = building.global_position.distance_to(current_target.global_position)
    if distance_to_target < closest_distance:
      closest_distance = distance_to_target
      closest_building = building
  
  return closest_building


func _actor_setup():
  # Wait for the first physics frame so the NavigationServer can sync.
  await get_tree().physics_frame

  # Now that the navigation map is no longer empty, set the movement target.
  _choose_target()
  
  # Check if we need fallback pathfinding
  _check_and_set_fallback_target()


func _check_and_set_fallback_target() -> void:
  """Check if the enemy can reach the target. If not, find a building to attack."""
  if not current_target:
    return
  
  # Wait for navigation to calculate path
  await get_tree().physics_frame
  
  # Check if the path is valid/reachable
  if navigation_agent.is_target_reachable():
    # Path is fine, clear any fallback
    fallback_building_target = null
    MyLogger.trace("Enemy.Navigation", "Path to target is reachable")
  else:
    # Path is blocked, find building to attack
    MyLogger.info("Enemy.Navigation", "Cannot reach target, searching for blocking building")
    var blocking_building = _find_building_closest_to_target()
    
    if blocking_building:
      fallback_building_target = blocking_building
      navigation_agent.set_target_position(blocking_building.global_position)
      MyLogger.info("Enemy.Navigation", "Found blocking building, switching to fallback target")
    else:
      MyLogger.warn("Enemy.Navigation", "No path to target and no buildings found to attack!")


func _attack_target():
  MyLogger.debug("Enemy", "Attempting to attack target. Current target: %s, Fallback building: %s" % [current_target, fallback_building_target])

  if not current_target:
    MyLogger.trace("Enemy", "No current target to attack.")
    _choose_target()
    if not current_target:
      return
  
  if not current_target.is_in_group(survivor_group):
    MyLogger.warn("Enemy", "Current target is not in the survivor group.")
    _choose_target()
    if not current_target:
      return

  # If we have a fallback building target, prioritize it
  if fallback_building_target and is_instance_valid(fallback_building_target):
    MyLogger.debug("Enemy", "Fallback building target is valid, checking distance to attack.")
    var distance_to_fallback: float = global_position.distance_to(fallback_building_target.global_position)
    
    # Attack the fallback building if in range
    if distance_to_fallback <= building_attack_range:
      MyLogger.debug("Enemy", "Attacking fallback building at distance: %f" % distance_to_fallback)
      attack.perform_attack(fallback_building_target)
      return
  else:
    MyLogger.debug("Enemy", "No valid fallback building target currently set.")
    navigation_agent.set_target_position(current_target.global_position)
    _check_and_set_fallback_target()

  # Attack primary target if in range (higher priority)
  var distance_to_target: float = global_position.distance_to(current_target.global_position)
  MyLogger.debug("Enemy", "Distance to primary target: %f. Minimum attack range: %f" % [distance_to_target, target_attack_range])
  if distance_to_target <= target_attack_range:
      attack.perform_attack(current_target)
      return

  # If no targets in range, check for nearby buildings to attack
  var nearby_building = _find_nearest_building_in_range()
  if nearby_building:
    MyLogger.trace("Enemy", "Attacking nearby building at distance: %f" % global_position.distance_to(nearby_building.global_position))
    attack.perform_attack(nearby_building)
    return


func _process(_delta: float) -> void:
  _attack_target()

  # play animation based on movement speed
  if velocity.length() > 0.1:
    animation_player.play(run_animation)
  else:
    animation_player.play(idle_animation)


func _physics_process(delta: float):
  # Do not query when the map has never synchronized and is empty.
  if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
    MyLogger.debug("Enemy.Navigation", "Navigation map is empty, cannot navigate.")
    return

  _update_navigation(delta)

  move_and_slide()

func _update_navigation(delta: float):
  if navigation_agent.is_navigation_finished():
    # Check if we reached the fallback building or if we need to recheck path
    if fallback_building_target and is_instance_valid(fallback_building_target):
      # We've reached the fallback building, stay here and attack it
      MyLogger.trace("Enemy.Navigation", "Reached fallback building target.")
    else:
      # Check if we can now reach the main target
      if current_target:
        navigation_agent.set_target_position(current_target.global_position)
        _check_and_set_fallback_target()
    
    velocity = Vector3.ZERO
  else:
    var next_path_position := navigation_agent.get_next_path_position()

    var local_current_look_position := Vector3.MODEL_FRONT

    # Move directly without avoidance
    var direction := global_position.direction_to(next_path_position)
    velocity = direction * movement_speed

    var global_target_look_position := Vector3(next_path_position)
    global_target_look_position.y = global_position.y # Keep the look direction horizontal
    var local_target_look_position := to_local(global_target_look_position)

    # If the target look vector is effectively zero, we are already aligned for this frame.
    if local_target_look_position.length_squared() <= CMP_EPSILON * CMP_EPSILON:
      return

    local_target_look_position = local_target_look_position.normalized()

    var radians_to_target := local_current_look_position.angle_to(local_target_look_position)

    # Avoid division by zero and unnecessary interpolation when already facing the target.
    if radians_to_target <= CMP_EPSILON:
      return
    var elapsed_rotation := rotation_speed * delta
    var rotation_fraction := clampf(elapsed_rotation / radians_to_target, 0, 1)

    var interpolated_look_position := to_global(local_current_look_position.slerp(local_target_look_position, rotation_fraction))

    look_at(interpolated_look_position, Vector3.UP, true)

    
func _on_died(damage_source: String = "unknown"):
  MyLogger.info("Enemy", "Enemy (%s) died from %s, removing from scene" % [enemy_type, damage_source])
  
  # Track the defeat in stats system
  if StatsManager:
    var defeated_by_hand = (damage_source == "player")
    StatsManager.track_enemy_defeated(enemy_type, defeated_by_hand)
  
  # Always award XP to the player
  CurrencyManager.earn_xp(xp_reward)
  
  # Award scrap if the enemy gives any
  if scrap_reward > 0:
    CurrencyManager.earn_scrap(scrap_reward)
    # Show floating scrap gain feedback via damage numbers component
    if damage_numbers:
        damage_numbers.show_scrap(scrap_reward)
  
  queue_free()


func _on_health_damaged(amount: int, hitpoints: int, damage_source: String = "unknown") -> void:
  MyLogger.debug("Enemy.Combat", "Enemy (%s) took %d damage from %s. Remaining HP: %d" % [enemy_type, amount, damage_source, hitpoints])
