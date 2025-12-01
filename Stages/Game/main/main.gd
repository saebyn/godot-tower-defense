extends Node3D

@export_group("Attack Settings")
@export var raycast_length: float = 1000.0
@export var attack_waiting_cursor_image: Texture2D

@export_group("Navigation")
@export var navigation_rebake_interval: float = 5.0 # Seconds between rebakes

@onready var camera: Camera3D = $Camera3D
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D
@onready var enemy_raycast: RayCast3D = $EnemyRayCast3D
var attack: Component_Attack
@onready var ui: Control = $UI

@onready var obstacle_placement: Utility_ObstaclePlacement = $ObstaclePlacement

var obstacle_raycast: RayCast3D
var current_scenario: Stage_Scenario = null
## Currently hovered shooting obstacle for range preview
var _hovered_shooting_obstacle: Entity_ShootingObstacle = null
## Raycast for detecting shooting obstacles on hover
var _hover_raycast: RayCast3D

func _ready() -> void:
  # Find Attack component via metadata
  if has_meta("attack_component"):
    attack = get_meta("attack_component")
  
  # Create obstacle detection raycast
  obstacle_raycast = RayCast3D.new()
  obstacle_raycast.enabled = false
  obstacle_raycast.collision_mask = 2 # Only detect obstacles (layer 2)
  add_child(obstacle_raycast)
  
  # Create hover detection raycast
  _hover_raycast = RayCast3D.new()
  _hover_raycast.enabled = false
  _hover_raycast.collision_mask = 2 # Only detect obstacles (layer 2)
  add_child(_hover_raycast)
  
  # Set player attack damage source
  if attack:
    attack.damage_source = "player"
  
  # Connect to obstacle placement signals for showing all shooting obstacle ranges
  obstacle_placement.placement_mode_entered.connect(_on_placement_mode_entered)
  obstacle_placement.placement_mode_exited.connect(_on_placement_mode_exited)

  # Load the appropriate scenario dynamically
  _load_scenario()

  # Rebake navigation mesh periodically
  _start_navigation_rebake_timer()


func _load_scenario() -> void:
  # Get the current scenario from ScenarioManager
  var scenario_id = ScenarioManager.get_current_scenario_id()
  
  if scenario_id.is_empty():
    # Default to scenario_1 if no scenario is set
    scenario_id = "scenario_1"
    ScenarioManager.set_current_scenario_id(scenario_id)
    MyLogger.info("Main", "No scenario set, defaulting to: %s" % scenario_id)
  
  # Get scenario metadata
  var metadata = ScenarioManager.get_scenario_metadata(scenario_id)
  var scene_path = metadata.get("scene_path", "")
  
  if scene_path.is_empty():
    MyLogger.error("Main", "Scenario %s has no scene path configured" % scenario_id)
    return
  
  # Check if there's already a scenario loaded (from the editor)
  # Look for any existing child that's a Stage_Scenario
  for child in get_children():
    if child is Stage_Scenario:
      MyLogger.info("Main", "Removing existing scenario: %s" % child.name)
      remove_child(child)
      child.queue_free()
  
  # Load the scenario scene
  MyLogger.info("Main", "Loading scenario: %s from %s" % [scenario_id, scene_path])
  var scenario_scene = load(scene_path)
  
  if scenario_scene == null:
    MyLogger.error("Main", "Failed to load scenario scene: %s" % scene_path)
    return
  
  # Instantiate and add the scenario
  current_scenario = scenario_scene.instantiate()
  add_child(current_scenario)
  
  # Apply the 45-degree rotation to align with isometric camera view
  # This matches the rotation applied in the editor to the hardcoded scenario
  current_scenario.rotation.y = - PI / 4 # 45 degrees in radians
  
  # Configure the scenario with the UI reference
  current_scenario.ui = ui

  # Rebake navigation mesh after loading scenario
  rebake_navigation_mesh()
  
  MyLogger.info("Main", "Scenario loaded successfully: %s" % scenario_id)


func rebake_navigation_mesh():
  MyLogger.info("Navigation", "Rebaking navigation mesh...")
  if navigation_region and navigation_region.navigation_mesh:
    if navigation_region.is_baking():
      # Wait and retry if already baking
      MyLogger.debug("Navigation", "Navigation mesh is already baking, waiting...")
      await navigation_region.bake_finished

    navigation_region.bake_navigation_mesh()
    MyLogger.info("Navigation", "Navigation mesh rebaked!")

func _start_navigation_rebake_timer() -> void:
  var timer = Timer.new()
  timer.wait_time = navigation_rebake_interval
  timer.autostart = true
  timer.one_shot = false
  add_child(timer)
  timer.timeout.connect(rebake_navigation_mesh)

func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton and not obstacle_placement.busy and event.pressed:
    if event.button_index == MOUSE_BUTTON_LEFT:
      _handle_enemy_click(event.position)
    elif event.button_index == MOUSE_BUTTON_RIGHT:
      _handle_obstacle_remove_click(event.position)
  elif event is InputEventMouseMotion and not obstacle_placement.busy:
    _handle_shooting_obstacle_hover(event.position)


func _handle_enemy_click(click_position: Vector2):
  # Create a raycast from the camera to detect what was clicked
  var ray_origin = camera.project_ray_origin(click_position)
  var ray_direction = camera.project_ray_normal(click_position)
  
  # Use the dedicated enemy raycast
  enemy_raycast.enabled = true
  enemy_raycast.position = ray_origin
  enemy_raycast.target_position = ray_direction * raycast_length
  
  # Force the raycast to update
  enemy_raycast.force_raycast_update()
  
  if enemy_raycast.is_colliding():
    var collider = enemy_raycast.get_collider()
    MyLogger.debug("Player", "Clicked on: %s" % collider.name)
    # If the collider is an enemy, perform an attack
    attack.perform_attack(collider)
  
  # Disable the enemy raycast after use
  enemy_raycast.enabled = false


func _handle_obstacle_remove_click(click_position: Vector2):
  # Create a raycast from the camera to detect what was clicked
  var ray_origin = camera.project_ray_origin(click_position)
  var ray_direction = camera.project_ray_normal(click_position)
  
  # Use the dedicated obstacle raycast (layer 2 for obstacles)
  obstacle_raycast.enabled = true
  obstacle_raycast.collision_mask = 2 # Only detect obstacles
  obstacle_raycast.position = ray_origin
  obstacle_raycast.target_position = ray_direction * raycast_length
  
  # Force the raycast to update
  obstacle_raycast.force_raycast_update()
  
  if obstacle_raycast.is_colliding():
    var collider = obstacle_raycast.get_collider()
    MyLogger.info("Player", "Right-clicked on: %s (type: %s)" % [collider.name, collider.get_class()])
    
    # Check if the collider is a Entity_PlaceableObstacle
    if collider is Entity_PlaceableObstacle:
      var obstacle = collider as Entity_PlaceableObstacle
      MyLogger.info("Player", "Confirmed Entity_PlaceableObstacle, calling remove()")
      var refund = obstacle.remove()
      MyLogger.info("Player", "Removed obstacle and recovered %d scrap" % refund)
      
      # Show UI feedback
      if ui and ui.has_method("show_obstacle_removed"):
        ui.show_obstacle_removed(refund)
      
      # Rebake navigation mesh after removal
      rebake_navigation_mesh()
    else:
      MyLogger.info("Player", "Clicked object is not a removable obstacle")
  else:
    MyLogger.info("Player", "Right-click raycast did not hit anything")
  
  # Disable the obstacle raycast after use
  obstacle_raycast.enabled = false


func _on_obstacle_spawn_requested(obstacle: Resource_ObstacleType) -> void:
  # Forward the signal to the obstacle placement system
  obstacle_placement._on_obstacle_spawn_requested(obstacle)

func _on_attack_cooldown_started():
  if attack_waiting_cursor_image:
    Input.set_custom_mouse_cursor(attack_waiting_cursor_image)

func _on_attack_cooldown_ended():
  Input.set_custom_mouse_cursor(null)


## Shows range indicators on all shooting obstacles when placement mode is entered.
func _on_placement_mode_entered() -> void:
  var shooting_obstacles = get_tree().get_nodes_in_group(Entity_ShootingObstacle.SHOOTING_OBSTACLES_GROUP)
  for obstacle in shooting_obstacles:
    if obstacle is Entity_ShootingObstacle:
      obstacle.show_range_indicator()


## Hides range indicators on all shooting obstacles when placement mode is exited.
func _on_placement_mode_exited() -> void:
  var shooting_obstacles = get_tree().get_nodes_in_group(Entity_ShootingObstacle.SHOOTING_OBSTACLES_GROUP)
  for obstacle in shooting_obstacles:
    if obstacle is Entity_ShootingObstacle:
      obstacle.hide_range_indicator()


## Handles hover detection for shooting obstacles to show their range indicators.
func _handle_shooting_obstacle_hover(mouse_position: Vector2) -> void:
  var ray_origin = camera.project_ray_origin(mouse_position)
  var ray_direction = camera.project_ray_normal(mouse_position)
  
  _hover_raycast.enabled = true
  _hover_raycast.position = ray_origin
  _hover_raycast.target_position = ray_direction * raycast_length
  _hover_raycast.force_raycast_update()
  
  var new_hovered_obstacle: Entity_ShootingObstacle = null
  
  if _hover_raycast.is_colliding():
    var collider = _hover_raycast.get_collider()
    if collider is Entity_ShootingObstacle:
      new_hovered_obstacle = collider
  
  _hover_raycast.enabled = false
  
  # Update hover state if changed
  if new_hovered_obstacle != _hovered_shooting_obstacle:
    # Exit old hover
    if _hovered_shooting_obstacle and is_instance_valid(_hovered_shooting_obstacle):
      _hovered_shooting_obstacle.on_mouse_exit()
    
    # Enter new hover
    _hovered_shooting_obstacle = new_hovered_obstacle
    if _hovered_shooting_obstacle:
      _hovered_shooting_obstacle.on_mouse_enter()