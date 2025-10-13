extends Node3D

@export_group("Attack Settings")
@export var raycast_length: float = 1000.0
@export var attack_waiting_cursor_image: Texture2D

@onready var camera: Camera3D = $Camera3D
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D
@onready var enemy_raycast: RayCast3D = $EnemyRayCast3D
var attack: Attack
@onready var ui: Control = $UI

@onready var obstacle_placement: ObstaclePlacement = $ObstaclePlacement

var obstacle_raycast: RayCast3D

func _ready() -> void:
  # Find Attack component via metadata
  if has_meta("attack_component"):
    attack = get_meta("attack_component")
  
  # Create obstacle detection raycast
  obstacle_raycast = RayCast3D.new()
  obstacle_raycast.enabled = false
  obstacle_raycast.collision_mask = 2 # Only detect obstacles (layer 2)
  add_child(obstacle_raycast)
  
  # Set player attack damage source
  if attack:
    attack.damage_source = "player"


func rebake_navigation_mesh():
  Logger.info("Navigation", "Rebaking navigation mesh...")
  if navigation_region and navigation_region.navigation_mesh:
    if navigation_region.is_baking():
      # Wait and retry if already baking
      Logger.debug("Navigation", "Navigation mesh is already baking, waiting...")
      await navigation_region.bake_finished

    navigation_region.bake_navigation_mesh()
    Logger.info("Navigation", "Navigation mesh rebaked!")


func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton and not obstacle_placement.busy and event.pressed:
    if event.button_index == MOUSE_BUTTON_LEFT:
      _handle_enemy_click(event.position)
    elif event.button_index == MOUSE_BUTTON_RIGHT:
      _handle_obstacle_remove_click(event.position)


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
    Logger.debug("Player", "Clicked on: %s" % collider.name)
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
    Logger.info("Player", "Right-clicked on: %s (type: %s)" % [collider.name, collider.get_class()])
    
    # Check if the collider is a PlaceableObstacle
    if collider is PlaceableObstacle:
      var obstacle = collider as PlaceableObstacle
      Logger.info("Player", "Confirmed PlaceableObstacle, calling remove()")
      var refund = obstacle.remove()
      Logger.info("Player", "Removed obstacle and recovered %d scrap" % refund)
      
      # Show UI feedback
      if ui and ui.has_method("show_obstacle_removed"):
        ui.show_obstacle_removed(refund)
      
      # Rebake navigation mesh after removal
      rebake_navigation_mesh()
    else:
      Logger.info("Player", "Clicked object is not a removable obstacle")
  else:
    Logger.info("Player", "Right-click raycast did not hit anything")
  
  # Disable the obstacle raycast after use
  obstacle_raycast.enabled = false


func _on_obstacle_spawn_requested(obstacle: ObstacleTypeResource) -> void:
  # Forward the signal to the obstacle placement system
  obstacle_placement._on_obstacle_spawn_requested(obstacle)

func _on_attack_cooldown_started():
  if attack_waiting_cursor_image:
    Input.set_custom_mouse_cursor(attack_waiting_cursor_image)

func _on_attack_cooldown_ended():
  Input.set_custom_mouse_cursor(null)