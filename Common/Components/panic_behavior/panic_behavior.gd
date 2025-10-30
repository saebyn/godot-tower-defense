class_name PanicBehavior
extends Node3D

## Component that makes survivors panic and run around when enemies are nearby
##
## This component detects nearby enemies and causes the survivor to move erratically
## within a constrained area, never leaving the designated focus zone.

@export_category("Panic Settings")
@export var panic_detection_radius: float = 10.0 ## Distance at which enemies trigger panic
@export var panic_move_radius: float = 3.0 ## Maximum distance survivor can move from spawn point
@export var panic_move_speed: float = 3.0 ## Movement speed when panicking
@export var panic_move_interval: float = 1.5 ## Time between choosing new panic destinations
@export var enemy_group: String = "enemies" ## Group name for enemies to detect

@export_category("Animation")
@export var animation_player_path: NodePath = "../AnimationPlayer" ## Path to AnimationPlayer node

var is_panicking: bool = false
var spawn_position: Vector3
var current_panic_destination: Vector3
var panic_timer: float = 0.0
var animation_player: AnimationPlayer

func _ready() -> void:
	# Store the initial position as the center point for panic movement
	spawn_position = global_position
	current_panic_destination = spawn_position
	
	# Get animation player reference
	if not animation_player_path.is_empty():
		animation_player = get_node_or_null(animation_player_path)
		if not animation_player:
			Logger.warning("PanicBehavior", "AnimationPlayer not found at path: %s" % animation_player_path)

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

func _check_for_nearby_enemies() -> bool:
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= panic_detection_radius:
			return true
	
	return false

func _start_panic() -> void:
	Logger.trace("PanicBehavior", "Survivor started panicking!")
	_choose_new_panic_destination()
	panic_timer = 0.0

func _stop_panic() -> void:
	Logger.trace("PanicBehavior", "Survivor stopped panicking")
	current_panic_destination = spawn_position
	
	# Play idle animation
	if animation_player and animation_player.has_animation("Idle"):
		animation_player.play("Idle")

func _update_panic_movement(delta: float) -> void:
	panic_timer += delta
	
	# Choose a new destination periodically
	if panic_timer >= panic_move_interval:
		_choose_new_panic_destination()
		panic_timer = 0.0
	
	# Move towards the panic destination
	var direction = (current_panic_destination - global_position)
	var distance = direction.length()
	
	if distance > 0.1:
		direction = direction.normalized()
		var move_amount = panic_move_speed * delta
		
		# Don't overshoot the destination
		if move_amount > distance:
			move_amount = distance
		
		global_position += direction * move_amount
		
		# Face the direction of movement
		var target_position = global_position + direction
		look_at(target_position, Vector3.UP, true)
		
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
	Logger.trace("PanicBehavior", "Chose new panic destination: %v" % current_panic_destination)
