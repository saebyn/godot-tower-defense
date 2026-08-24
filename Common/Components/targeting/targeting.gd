extends Node3D
class_name Component_Targeting

enum TargetPreference {
  RANDOM_SURVIVOR,
  NEAREST_THREAT,
}

@export var target_preferences: Array[TargetPreference] = [TargetPreference.RANDOM_SURVIVOR]
@export var survivor_group: String = "survivors"
@export var building_group: String = "buildings"
@export var attack: Component_Attack
@export var navigation_agent: NavigationAgent3D

var current_target: Node3D = null
var fallback_building_target: Node3D = null # Used when direct path to target is blocked

var building_attack_range: float:
  get:
    return get_parent().building_attack_range if get_parent() else 0.0

var target_attack_range: float:
  get:
    return get_parent().target_attack_range if get_parent() else 0.0

func _ready() -> void:
  # Make sure to not await during _ready.
  _actor_setup.call_deferred()

func _actor_setup():
  # Wait for the first physics frame so the NavigationServer can sync.
  await get_tree().physics_frame

  # Now that the navigation map is no longer empty, set the movement target.
  _choose_target()
  
  # Check if we need fallback pathfinding
  _check_and_set_fallback_target()

func _process(_delta: float) -> void:
  _attack_target()

func _physics_process(_delta: float):
  if navigation_agent.is_navigation_finished():
    # Check if we reached the fallback building or if we need to recheck path
    if fallback_building_target and is_instance_valid(fallback_building_target):
      # We've reached the fallback building, stay here and attack it
      MyLogger.trace("Component_Targeting", "Reached fallback building target.")
    else:
      # Check if we can now reach the main target
      if current_target:
        navigation_agent.set_target_position(current_target.global_position)
        _check_and_set_fallback_target()


func _find_next_target() -> Node3D:
  for target_preference in target_preferences:
    match target_preference:
      TargetPreference.RANDOM_SURVIVOR:
        var targets := get_tree().get_nodes_in_group(survivor_group)
        if targets.size() > 0:
          return targets.pick_random()
      TargetPreference.NEAREST_THREAT:
        var targets: Array[Node3D] = []
        # Find all buildings with an attack component
        for node in get_tree().get_nodes_in_group(building_group):
          if node.has_method("can_hit_target") and node.can_hit_target(self):
            targets.append(node)

        if targets.size() > 0:
          # Sort by distance to this agent
          targets.sort_custom(_sort_by_distance_to_self)

          return targets[0]

  return null


func _choose_target():
  current_target = _find_next_target()

  if current_target:
    MyLogger.info("Component_Targeting", "Chose new target: %s" % current_target.name)
    navigation_agent.set_target_position(current_target.global_position)
  else:
    MyLogger.trace("Component_Targeting", "No targets available.")
    attack.cancel()
    # No targets available, stop the agent.
    navigation_agent.set_target_position(global_position)


func _sort_by_distance_to_self(a: Node3D, b: Node3D) -> bool:
  var dist_a := global_position.distance_to(a.global_position)
  var dist_b := global_position.distance_to(b.global_position)
  if dist_a < dist_b:
    return true
  else:
    return false

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
    MyLogger.trace("Component_Targeting", "Path to target is reachable")
  else:
    # Path is blocked, find building to attack
    MyLogger.info("Component_Targeting", "Cannot reach target, searching for blocking building")
    var blocking_building = _find_building_closest_to_target()
    
    if blocking_building:
      fallback_building_target = blocking_building
      navigation_agent.set_target_position(blocking_building.global_position)
      MyLogger.info("Component_Targeting", "Found blocking building, switching to fallback target")
    else:
      MyLogger.warn("Component_Targeting", "No path to target and no buildings found to attack!")


func _attack_target():
  MyLogger.debug("Component_Targeting", "Attempting to attack target. Current target: %s, Fallback building: %s" % [current_target, fallback_building_target])

  # TODO think about how we can change target to match
  # the targetting preferences, even if the current tartget is still valid.
  # For example, if the current target is a survivor, but a building is closer,
  # we might want to switch to the building.

  # TODO move the checks for an existing current_target into _choose_target().
  if not current_target:
    MyLogger.trace("Component_Targeting", "No current target to attack.")
    _choose_target()
    if not current_target:
      return
  
  # If we have a fallback building target, prioritize it
  if fallback_building_target and is_instance_valid(fallback_building_target):
    MyLogger.debug("Component_Targeting", "Fallback building target is valid, checking distance to attack.")
    var distance_to_fallback: float = global_position.distance_to(fallback_building_target.global_position)
    
    # Attack the fallback building if in range
    if distance_to_fallback <= building_attack_range:
      MyLogger.debug("Component_Targeting", "Attacking fallback building at distance: %f" % distance_to_fallback)
      attack.perform_attack(fallback_building_target)
      return
  else:
    MyLogger.debug("Component_Targeting", "No valid fallback building target currently set.")
    navigation_agent.set_target_position(current_target.global_position)
    _check_and_set_fallback_target()

  # Attack primary target if in range (higher priority)
  var distance_to_target: float = global_position.distance_to(current_target.global_position)
  MyLogger.debug("Component_Targeting", "Distance to primary target: %f. Minimum attack range: %f" % [distance_to_target, target_attack_range])
  if distance_to_target <= target_attack_range:
      attack.perform_attack(current_target)
      return

  # If no targets in range, check for nearby buildings to attack
  var nearby_building = _find_nearest_building_in_range()
  if nearby_building:
    MyLogger.trace("Component_Targeting", "Attacking nearby building at distance: %f" % global_position.distance_to(nearby_building.global_position))
    attack.perform_attack(nearby_building)
    return

