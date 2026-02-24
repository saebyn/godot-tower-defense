class_name Component_PanicBehavior
extends Node

## Component that makes survivors panic and run around when enemies are nearby
##
## This component detects nearby enemies and causes the survivor to move erratically
## within a constrained area, never leaving the designated focus zone.
##
## [b]IMPORTANT:[/b] This component must be attached to a Node3D parent node (the survivor).
## It will automatically disable itself if the parent is not a Node3D.

@export_category("Panic Settings")
@export var panic_detection_radius: float = 10.0 ## Distance at which enemies trigger panic
@export var panic_move_radius: float = 3.0 ## Maximum distance survivor can move from spawn point
@export var panic_move_speed: float = 3.0 ## Movement speed when panicking
@export var panic_move_interval: float = 1.5 ## Time between choosing new panic destinations
@export var enemy_group: String = "enemies" ## Group name for enemies to detect
@export var minimum_move_threshold: float = 0.1 ## Minimum distance to move towards destination to avoid jittering

@export_category("Audio")
@export var yelp_sound_chance: float = 0.33 ## Chance per second to play a yelp sound when we are panicking

@export_category("Animation")
@export var animation_player_path: NodePath = "../AnimationPlayer" ## Path to AnimationPlayer node

var is_panicking: bool = false
var spawn_position: Vector3
var current_panic_destination: Vector3
var panic_timer: float = 0.0
var animation_player: AnimationPlayer
var target: Node3D # Reference to the parent target node

func _ready() -> void:
  # Get reference to parent target
  target = get_parent() as Node3D
  if not target:
    MyLogger.error("PanicBehavior", "Parent must be a Node3D! PanicBehavior disabled.")
    set_process(false) # Disable processing if parent is invalid
    return
  
  # Store the initial position as the center point for panic movement
  spawn_position = target.position
  current_panic_destination = spawn_position
  
  # Get animation player reference
  if not animation_player_path.is_empty():
    animation_player = get_node_or_null(animation_player_path)
    if not animation_player:
      MyLogger.warn("PanicBehavior", "AnimationPlayer not found at path: %s" % animation_player_path)
  
  MyLogger.debug("PanicBehavior", "PanicBehavior initialized successfully for target: %s" % target.name)

func _process(delta: float) -> void:
  # Check for nearby enemies
  var should_panic = _check_for_nearby_enemies()
  
  if should_panic != is_panicking:
    is_panicking = should_panic
    if is_panicking:
      _start_panic()
    else:
      _stop_panic()
  
  if is_panicking:
    _update_panic_movement(delta)
    # Randomly play yelp sounds while panicking
    if randi() % 1000 < int(yelp_sound_chance * 1000 * delta):
      _play_yelp_sound()

func _play_yelp_sound() -> void:
  if target and "audio_player" in target and target.audio_player:
    var pitch_override = target.voice_pitch if target.voice_pitch != null else null
    AudioManager.play_sound(target.audio_player, Resource_SoundEffect.SoundEffect.SURVIVOR_YELP, pitch_override)

func _check_for_nearby_enemies() -> bool:
  if not target:
    return false
  
  # Note: For large numbers of enemies, consider using Area3D with collision layers
  # or spatial partitioning for better performance. Current implementation is
  # acceptable for typical tower defense enemy counts (< 100 enemies).
  var enemies = get_tree().get_nodes_in_group(enemy_group)
  
  for enemy in enemies:
    if not is_instance_valid(enemy):
      continue
    
    # Ensure enemy is a Node3D before accessing position
    if not enemy is Node3D:
      continue
    
    var distance = target.position.distance_to(enemy.position)
    if distance <= panic_detection_radius:
      return true
  
  return false

func _start_panic() -> void:
  MyLogger.trace("PanicBehavior", "Survivor started panicking!")
  _choose_new_panic_destination()
  panic_timer = 0.0

func _stop_panic() -> void:
  MyLogger.trace("PanicBehavior", "Survivor stopped panicking")
  current_panic_destination = spawn_position
  
  # Play idle animation
  if animation_player and animation_player.has_animation("Idle"):
    animation_player.play("Idle")

func _update_panic_movement(delta: float) -> void:
  if not target:
    return
  
  panic_timer += delta
  
  # Choose a new destination periodically
  if panic_timer >= panic_move_interval:
    _choose_new_panic_destination()
    panic_timer = 0.0
  
  # Move towards the panic destination
  var move := current_panic_destination - target.position
  move.y = 0 # Keep movement on the horizontal plane
  var direction = move.normalized()

  if move.length() > minimum_move_threshold:
    var move_amount = min(panic_move_speed * delta, move.length())
    target.position += direction * move_amount
    
    # Face the direction of movement
    var target_look_position = target.position + direction
    target.look_at(target_look_position, Vector3.UP, true)
    
    # Play run animation
    if animation_player and animation_player.has_animation("Run"):
      if animation_player.current_animation != "Run":
        animation_player.play("Run")
  else:
    # Reached destination, play idle while waiting for next move
    if animation_player and animation_player.has_animation("Idle"):
      if animation_player.current_animation != "Idle":
        animation_player.play("Idle")

func _choose_new_panic_destination() -> void:
  # Choose a random point within panic_move_radius of spawn_position
  var random_angle = randf() * TAU
  var random_distance = randf() * panic_move_radius
  
  var offset = Vector3(
    cos(random_angle) * random_distance,
    0.0,
    sin(random_angle) * random_distance
  )
  
  current_panic_destination = spawn_position + offset
  MyLogger.debug("PanicBehavior", "Chose new panic destination: %v" % current_panic_destination)
