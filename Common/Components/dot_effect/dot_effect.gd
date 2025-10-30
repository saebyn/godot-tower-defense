@tool
extends Area3D
class_name DotEffect

## Applies damage over time to enemies within the area.
## Useful for electric fences, poison clouds, fire zones, acid pools, etc.
##
## Usage: Add as child node to an obstacle, configure DoT settings,
## and add a CollisionShape3D child to define the effect area.

signal dot_applied(target: Node, damage: int)
signal target_entered(target: Node)
signal target_exited(target: Node)

@export_group("DoT Settings")
@export var damage_per_tick: int = 5 ## Damage dealt per tick
@export var tick_interval: float = 0.5 ## Time between damage ticks (in seconds)
@export var damage_source: String = "dot_effect" ## Source identifier for tracking
@export var target_group: String = "enemies" ## Which group to affect

@export_group("Audio")
@export var enable_sound: bool = false ## Enable DoT tick sound effects
@export var tick_sound: AudioManager.SoundEffect = AudioManager.SoundEffect.PLAYER_ATTACK_HIT
@export var audio_player: AudioStreamPlayer

var _active_targets: Dictionary = {} ## Maps target -> bool (just tracking presence)
var _tick_timer: Timer


func _ready():
	# Configure area to detect bodies on layer 4 (enemies)
	collision_mask = 4
	monitoring = true
	monitorable = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Setup tick timer
	_tick_timer = Timer.new()
	_tick_timer.wait_time = tick_interval
	_tick_timer.timeout.connect(_on_tick)
	_tick_timer.autostart = true
	add_child(_tick_timer)
	
	# Register in parent metadata for discovery
	if get_parent():
		get_parent().set_meta("dot_effect_component", self)
	
	Logger.debug("DotEffect", "DotEffect component initialized (tick interval: %fs)" % tick_interval)


func _on_body_entered(body: Node):
	if Engine.is_editor_hint():
		return
	
	if body.is_in_group(target_group):
		_active_targets[body] = true
		target_entered.emit(body)
		Logger.debug("DotEffect", "Target entered DoT area: %s" % body.name)


func _on_body_exited(body: Node):
	if Engine.is_editor_hint():
		return
	
	if body in _active_targets:
		_active_targets.erase(body)
		target_exited.emit(body)
		Logger.debug("DotEffect", "Target exited DoT area: %s" % body.name)


func _on_tick():
	if Engine.is_editor_hint():
		return
	
	var targets_to_remove = []
	
	for target in _active_targets.keys():
		if not is_instance_valid(target):
			targets_to_remove.append(target)
			continue
		
		# Deal damage via Health component
		var health = null
		if target.has_meta("health_component"):
			health = target.get_meta("health_component")
		
		if health and health is Health:
			health.take_damage(damage_per_tick, damage_source)
			dot_applied.emit(target, damage_per_tick)
			Logger.trace("DotEffect", "Applied %d DoT damage to %s" % [damage_per_tick, target.name])
			
			if enable_sound and audio_player:
				AudioManager.play_sound(audio_player, tick_sound)
		else:
			# Target has no health component, remove from tracking
			targets_to_remove.append(target)
	
	# Cleanup invalid targets
	for target in targets_to_remove:
		_active_targets.erase(target)


func get_active_target_count() -> int:
	return _active_targets.size()


func get_active_targets() -> Array:
	return _active_targets.keys()


func is_target_active(target: Node) -> bool:
	return target in _active_targets
