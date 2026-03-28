extends Node3D

signal enemy_attacked ## Emitted when the player clicks to attack an enemy; re-emitted from PlayerInputController

@onready var camera: Camera3D = $Camera3D
@onready var ui: MainUI = $UI
@onready var building_placement: Utility_BuildingPlacement = $BuildingPlacement
@onready var navigation_controller: Main_NavigationController = $NavigationController
@onready var hover_controller: Main_HoverController = $HoverController
@onready var player_input_controller: Main_PlayerInputController = $PlayerInputController

var current_scenario: Stage_Scenario = null


func _ready() -> void:
  # Start background music for the game
  AudioManager.play_background_music()

  # Connect to building placement signals for showing all shooting building ranges
  building_placement.placement_mode_entered.connect(_on_placement_mode_entered)
  building_placement.placement_mode_exited.connect(_on_placement_mode_exited)

  # Re-emit enemy_attacked from PlayerInputController so scenarios can connect to it on main
  player_input_controller.enemy_attacked.connect(func(): enemy_attacked.emit())

  # Load the appropriate scenario dynamically
  _load_scenario()


func _exit_tree() -> void:
  # Stop background music when leaving the game scene
  AudioManager.stop_background_music()


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
  navigation_controller.rebake_navigation_mesh()

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


func _on_building_spawn_requested(building: Resource_BuildingType) -> void:
  # Forward the signal to the building placement system
  building_placement._on_building_spawn_requested(building)


## Shows range indicators on all shooting buildings when placement mode is entered.
func _on_placement_mode_entered() -> void:
  var shooting_buildings = get_tree().get_nodes_in_group(Entity_RangedBuilding.RANGED_BUILDINGS_GROUP)
  for building in shooting_buildings:
    if building is Entity_RangedBuilding:
      building.show_range_indicator()


## Hides range indicators on all shooting buildings when placement mode is exited.
func _on_placement_mode_exited() -> void:
  var shooting_buildings = get_tree().get_nodes_in_group(Entity_RangedBuilding.RANGED_BUILDINGS_GROUP)
  for building in shooting_buildings:
    if building is Entity_RangedBuilding:
      building.hide_range_indicator(true) # Force hide even if hovered
