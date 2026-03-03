extends Node3D

signal enemy_attacked ## Emitted when the player clicks to attack an enemy

@export_group("Attack Settings")
@export var raycast_length: float = 1000.0
@export var attack_waiting_cursor_image: Texture2D

@export_group("UI")
@export var obstacle_tooltip_scene: PackedScene

@export_group("Navigation")
@export var navigation_rebake_interval: float = 5.0 # Seconds between rebakes

@onready var camera: Camera3D = $Camera3D
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D
@onready var enemy_raycast: RayCast3D = $EnemyRayCast3D
var attack: Component_Attack
@onready var ui: MainUI = $UI
@onready var background_music_player: AudioStreamPlayer = $BgMusicAudioStreamPlayer

@onready var obstacle_placement: Utility_ObstaclePlacement = $ObstaclePlacement

@onready var twitch_eventsub: TwitchEventsub = $TwitchEventsub
@onready var joinqueue_command: TwitchCommand = $JoinQueueCommand

var obstacle_raycast: RayCast3D
var current_scenario: Stage_Scenario = null
## Currently hovered ranged obstacle for range preview
var _hovered_ranged_obstacle: Entity_RangedObstacle = null
## Any entity (enemy, obstacle, target) currently under the cursor — used for unit-frame hover
var _hovered_entity: Node3D = null
## Raycast for detecting ranged obstacles on hover
var _hover_raycast: RayCast3D
## Obstacle tooltip for displaying stats on hover
var _obstacle_tooltip = null # UI_ObstacleTooltip
## Last mouse position to avoid redundant hover checks
var _last_hover_check_position: Vector2 = Vector2(-1, -1)
## Minimum distance mouse must move before triggering hover check (in pixels)
const HOVER_CHECK_THRESHOLD: float = 5.0

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
  _hover_raycast.collision_mask = 1 | 2 | 4 # Targets/survivors (layer 1) + obstacles (layer 2) + enemies (layer 4)
  add_child(_hover_raycast)
  
  # Set player attack damage source
  if attack:
    attack.damage_source = "player"
  
  # Create obstacle tooltip if scene is assigned
  if obstacle_tooltip_scene and ui:
    _obstacle_tooltip = obstacle_tooltip_scene.instantiate()
    ui.add_child(_obstacle_tooltip)
    _obstacle_tooltip.visible = false
  
  # Connect to obstacle placement signals for showing all shooting obstacle ranges
  obstacle_placement.placement_mode_entered.connect(_on_placement_mode_entered)
  obstacle_placement.placement_mode_exited.connect(_on_placement_mode_exited)

  # Load the appropriate scenario dynamically
  _load_scenario()

  # Rebake navigation mesh periodically
  _start_navigation_rebake_timer()

  _on_settings_changed() # Apply initial music pause state
  SettingsManager.audio_settings_changed.connect(_on_settings_changed)
  background_music_player.play()

  # Check if twitch integration is enabled and then set it up if so
  if SettingsManager.twitch_enabled:
    MyLogger.info("Main", "Twitch integration enabled - setting up Twitch connection")
    var setup_successful: bool = await Twitch.setup()

    if setup_successful:
      MyLogger.info("Main", "Twitch setup successful")
      var me = await Twitch.get_current_user()
      MyLogger.info("Main", "Twitch authenticated as %s (ID: %s)" % [me.display_name, me.id])

      if SettingsManager.twitch_welcome_message != "":
        Twitch.chat(SettingsManager.twitch_welcome_message)

      Twitch.api.unauthenticated.connect(_on_twitch_unauthenticated)

      # Set up eventsub to listen to chat
      Twitch.eventsub.subscribe(
        TwitchEventsubConfig.create(TwitchEventsubDefinition.CHANNEL_CHAT_MESSAGE, {"broadcaster_user_id": me.id, "user_id": me.id}),
      )
    else:
      # display a message to the user if Twitch setup failed, but don't disable the game features since Twitch is optional
      MyLogger.error("Main", "Twitch setup failed - Twitch features will be unavailable")
      ui.call_deferred("show_problem_message", "Twitch integration failed to set up. Twitch features will be unavailable. Please check the logs for more details.")


func _on_twitch_unauthenticated() -> void:
  MyLogger.warn("Main", "Twitch token lost during gameplay - Twitch features will be unavailable until re-authenticated")
  ui.call_deferred("show_problem_message", "Twitch connection was lost. Open Settings to reconnect.")

func _on_settings_changed() -> void:
  print("Applying music pause setting: %s" % SettingsManager.music_pause)
  background_music_player.process_mode = Node.PROCESS_MODE_PAUSABLE if SettingsManager.music_pause else Node.PROCESS_MODE_ALWAYS

func _load_scenario() -> void:
  # Get the current scenario from ScenarioManager
  var scenario_id = ScenarioManager.get_current_scenario_id()
  
  
  # Check if there's already a scenario loaded (from the editor)
  # Look for any existing child that's a Stage_Scenario
  for child in get_children():
    if child is Stage_Scenario:
      MyLogger.info("Main", "Removing existing scenario: %s" % child.name)
      remove_child(child)
      child.queue_free()
  
  # Instantiate and add the scenario
  current_scenario = ScenarioManager.instantiate_scenario()
  if not current_scenario:
    MyLogger.error("Main", "Failed to instantiate scenario: %s" % scenario_id)
    return

  add_child(current_scenario)
  
  # Apply the 45-degree rotation to align with isometric camera view
  # This matches the rotation applied in the editor to the hardcoded scenario
  current_scenario.rotation.y = - PI / 4 # 45 degrees in radians
  
  # Configure the scenario with the UI reference
  current_scenario.ui = ui
  
  # Configure boundaries based on scenario settings
  _configure_boundaries_from_scenario()

  # Rebake navigation mesh after loading scenario
  rebake_navigation_mesh()

  # Configure camera max zoom/size from scenario settings
  camera.camera_max_size = current_scenario.camera_max_size
  
  MyLogger.info("Main", "Scenario loaded successfully: %s" % scenario_id)


func _configure_boundaries_from_scenario() -> void:
  if not current_scenario:
    MyLogger.warn("Main", "Cannot configure boundaries - no scenario loaded")
    return
  
  # Get boundary values from the scenario
  var min_x = current_scenario.boundary_min_x
  var max_x = current_scenario.boundary_max_x
  var min_z = current_scenario.boundary_min_z
  var max_z = current_scenario.boundary_max_z
  
  MyLogger.info("Main", "Configuring boundaries from scenario: X[%d, %d] Z[%d, %d]" % [int(min_x), int(max_x), int(min_z), int(max_z)])

  # Update camera boundary constraints
  if camera:
    camera.world_min_x = min_x
    camera.world_max_x = max_x
    camera.world_min_z = min_z
    camera.world_max_z = max_z


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
    _handle_hover(event.position)


func _handle_enemy_click(click_position: Vector2):
  # Track every enemy-attack click for achievement purposes
  StatsManager.track_click_performed()
  
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
    enemy_attacked.emit()
  
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
      
      # Check if we're removing the currently hovered obstacle
      # Currently only Entity_RangedObstacle types can be hovered (see _handle_ranged_obstacle_hover)
      if _hovered_ranged_obstacle == obstacle:
        # Clear hover state to prevent dangling tooltip/range indicator
        _hovered_ranged_obstacle.on_mouse_exit()
        _hovered_ranged_obstacle = null
        MyLogger.debug("Player", "Cleared hover state for removed obstacle")
      
      if _hovered_entity == obstacle:
        _hide_entity_unit_frame(_hovered_entity)
        _hovered_entity = null
      
      # Also check if the tooltip is showing this obstacle and hide it
      # This is a defensive check that handles both current and future cases
      # where non-ranged obstacles might show tooltips
      if _obstacle_tooltip and _obstacle_tooltip.visible and _obstacle_tooltip.current_obstacle == obstacle:
        _obstacle_tooltip.hide_tooltip()
        MyLogger.debug("Player", "Hid tooltip for removed obstacle")
      
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
  var shooting_obstacles = get_tree().get_nodes_in_group(Entity_RangedObstacle.RANGED_OBSTACLES_GROUP)
  for obstacle in shooting_obstacles:
    if obstacle is Entity_RangedObstacle:
      obstacle.show_range_indicator()


## Hides range indicators on all shooting obstacles when placement mode is exited.
func _on_placement_mode_exited() -> void:
  var shooting_obstacles = get_tree().get_nodes_in_group(Entity_RangedObstacle.RANGED_OBSTACLES_GROUP)
  for obstacle in shooting_obstacles:
    if obstacle is Entity_RangedObstacle:
      obstacle.hide_range_indicator(true) # Force hide even if hovered


## Walks up the parent chain from node to find a node with "health_component" metadata.
## Returns the Component_Health, or null if none is found.
func _find_health_component(node: Node) -> Component_Health:
  var current: Node = node
  while current != null:
    if current.has_meta("health_component"):
      return current.get_meta("health_component") as Component_Health
    current = current.get_parent()
  return null

## Show the unit frame on the health component of a node, if it has one.
## Searches the node and its ancestors for a health_component.
func _show_entity_unit_frame(entity: Node3D) -> void:
  if entity == null:
    return
  var health := _find_health_component(entity)
  if health:
    health.show_unit_frame()

## Hide the unit frame on the health component of a node, if it has one.
## Searches the node and its ancestors for a health_component.
func _hide_entity_unit_frame(entity: Node3D) -> void:
  if entity == null or not is_instance_valid(entity):
    return
  var health := _find_health_component(entity)
  if health:
    health.hide_unit_frame()

## Unified hover handler: drives ranged-obstacle range indicators, tooltips,
## and unit-frame visibility for any entity with a health component.
func _handle_hover(mouse_position: Vector2) -> void:
  # Skip if mouse hasn't moved enough to warrant a new raycast
  if _last_hover_check_position.distance_to(mouse_position) < HOVER_CHECK_THRESHOLD:
    return
  _last_hover_check_position = mouse_position

  var ray_origin = camera.project_ray_origin(mouse_position)
  var ray_direction = camera.project_ray_normal(mouse_position)

  _hover_raycast.enabled = true
  _hover_raycast.position = ray_origin
  _hover_raycast.target_position = ray_direction * raycast_length
  _hover_raycast.force_raycast_update()

  var new_hovered_obstacle: Entity_RangedObstacle = null
  var new_hovered_entity: Node3D = null

  if _hover_raycast.is_colliding():
    var collider = _hover_raycast.get_collider()
    if collider is Node3D:
      new_hovered_entity = collider as Node3D
    if collider is Entity_RangedObstacle:
      new_hovered_obstacle = collider as Entity_RangedObstacle

  _hover_raycast.enabled = false

  # ── Ranged-obstacle range indicator + tooltip ──────────────────────────────
  if new_hovered_obstacle != _hovered_ranged_obstacle:
    if _hovered_ranged_obstacle and is_instance_valid(_hovered_ranged_obstacle):
      _hovered_ranged_obstacle.on_mouse_exit()
      if _obstacle_tooltip:
        _obstacle_tooltip.hide_tooltip()
    _hovered_ranged_obstacle = new_hovered_obstacle
    if _hovered_ranged_obstacle:
      _hovered_ranged_obstacle.on_mouse_enter()
      if _obstacle_tooltip:
        _obstacle_tooltip.show_tooltip(_hovered_ranged_obstacle, mouse_position)

  # ── Unit-frame hover for any entity with a health component ────────────────
  # Clear stale reference if the previously hovered entity was freed (e.g. scrap collected)
  if _hovered_entity != null and not is_instance_valid(_hovered_entity):
    _hovered_entity = null
  if new_hovered_entity != _hovered_entity:
    if _hovered_entity != null:
      _hide_entity_unit_frame(_hovered_entity)
    _hovered_entity = new_hovered_entity
    _show_entity_unit_frame(_hovered_entity)


func _on_joinqueue_command_received(from_username: String, info: TwitchCommandInfo, _arguments: PackedStringArray) -> void:
  MyLogger.info("Main.Twitch", "Received !joinqueue command from %s" % from_username)
  var survivor_name := from_username

  if SurvivorNameManager.add_name_to_priority_pool(survivor_name):
    MyLogger.info("Main.Twitch", "Added survivor name '%s' to priority pool" % survivor_name)
    Twitch.chat("Thanks @%s! Your survivor name '%s' has been added to the priority pool for the next scenario." % [from_username, survivor_name])
  else:
    MyLogger.warn("Main.Twitch", "Survivor name '%s' is already in the priority pool" % survivor_name)
    Twitch.chat("@%s, the survivor name '%s' is already in the priority pool." % [from_username, survivor_name])