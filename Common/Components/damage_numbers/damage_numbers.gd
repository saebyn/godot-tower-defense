# Component_DamageNumbers
# A component that displays floating damage numbers and scrap gain feedback above entities.
# Add this component to entities that need visual damage/currency feedback.
# Creates its own Label3D nodes dynamically - no scene file needed.
extends Node
class_name Component_DamageNumbers

## Types of numbers that can be displayed
enum NumberType {
	DAMAGE_NORMAL,
	DAMAGE_CRITICAL,
	DAMAGE_FIRE,
	DAMAGE_ICE,
	DAMAGE_POISON,
	SCRAP_GAIN
}

## Maximum number of damage numbers in the pool
@export var max_pool_size: int = 10
## Duration of the fade out animation in seconds
@export var fade_duration: float = 1.5
## Distance the number travels upward
@export var float_distance: float = 2.0
## Vertical offset above the entity
@export var vertical_offset: float = 2.0
## Whether damage numbers are enabled
@export var show_damage_numbers: bool = true
## Whether scrap gain numbers are enabled  
@export var show_scrap_gain: bool = true
## Font size for numbers
@export var font_size: int = 32
## Fixed size in pixels for Label3D (ensures visibility at any zoom)
@export var fixed_size_pixels: float = 48.0

# Pool of damage number Label3D nodes
var _number_pool: Array[Label3D] = []
# Track active tweens for cleanup
var _active_tweens: Dictionary = {}  # Label3D -> Tween


func _ready():
	# Register this component in parent's metadata for discovery
	if get_parent():
		get_parent().set_meta("damage_numbers_component", self)


## Display a damage number at the entity's position
func show_damage(amount: int, damage_source: String = "unknown"):
	if not show_damage_numbers or amount <= 0:
		return
	
	var parent = get_parent()
	if not parent or not parent is Node3D:
		return
	
	# Determine damage type based on source
	var damage_type = NumberType.DAMAGE_NORMAL
	match damage_source:
		"fire", "flame":
			damage_type = NumberType.DAMAGE_FIRE
		"ice", "frost", "cold":
			damage_type = NumberType.DAMAGE_ICE
		"poison", "toxic":
			damage_type = NumberType.DAMAGE_POISON
		"critical", "crit":
			damage_type = NumberType.DAMAGE_CRITICAL
	
	var world_pos = parent.global_position + Vector3.UP * vertical_offset
	_display_number(amount, world_pos, damage_type)


## Display a scrap gain number at the entity's position
func show_scrap(amount: int):
	if not show_scrap_gain or amount <= 0:
		return
	
	var parent = get_parent()
	if not parent or not parent is Node3D:
		return
	
	var world_pos = parent.global_position + Vector3.UP * (vertical_offset + 0.5)
	_display_number(amount, world_pos, NumberType.SCRAP_GAIN)


## Internal method to display a number
func _display_number(amount: int, world_position: Vector3, number_type: NumberType):
	var label = _get_or_create_label()
	if not label:
		return
	
	# Set up the label text
	if number_type == NumberType.SCRAP_GAIN:
		label.text = "+%d" % amount
	else:
		label.text = str(amount)
	
	# Set color based on type
	var label_font_size = font_size
	match number_type:
		NumberType.DAMAGE_NORMAL:
			label.modulate = Color.WHITE
		NumberType.DAMAGE_CRITICAL:
			label.modulate = Color.RED
			label_font_size = font_size + 8  # Slightly larger for crits
		NumberType.DAMAGE_FIRE:
			label.modulate = Color.ORANGE
		NumberType.DAMAGE_ICE:
			label.modulate = Color.CYAN
		NumberType.DAMAGE_POISON:
			label.modulate = Color.PURPLE
		NumberType.SCRAP_GAIN:
			label.modulate = Color.GOLD
	
	label.font_size = label_font_size
	
	# Store the base color for the fade animation
	var base_color = label.modulate
	
	# Position and activate
	label.global_position = world_position
	label.visible = true
	
	# Kill any existing tween for this label
	if _active_tweens.has(label) and is_instance_valid(_active_tweens[label]):
		_active_tweens[label].kill()
	
	# Create tween for animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Float upward
	var end_position = world_position + Vector3.UP * float_distance
	tween.tween_property(label, "global_position", end_position, fade_duration).set_ease(Tween.EASE_OUT)
	
	# Fade out (animate modulate alpha)
	var end_color = Color(base_color.r, base_color.g, base_color.b, 0.0)
	tween.tween_property(label, "modulate", end_color, fade_duration).set_ease(Tween.EASE_IN)
	
	# Track tween and deactivate when complete
	_active_tweens[label] = tween
	tween.finished.connect(_on_tween_finished.bind(label))
	
	Logger.trace("DamageNumbers", "Displaying %s at position %v" % [label.text, world_position])


## Called when a tween animation finishes
func _on_tween_finished(label: Label3D):
	_deactivate_number(label)
	if _active_tweens.has(label):
		_active_tweens.erase(label)


## Get an available label from pool or create a new one
func _get_or_create_label() -> Label3D:
	# Try to find an inactive label in the pool
	for label in _number_pool:
		if not label.visible:
			return label
	
	# Create new if pool not full
	if _number_pool.size() < max_pool_size:
		var new_label = _create_label()
		_number_pool.append(new_label)
		return new_label
	
	# Pool full - find and recycle the oldest
	if not _number_pool.is_empty():
		# Find any label and force-deactivate it for reuse
		for label in _number_pool:
			# Kill the tween if active
			if _active_tweens.has(label) and is_instance_valid(_active_tweens[label]):
				_active_tweens[label].kill()
				_active_tweens.erase(label)
			_deactivate_number(label)
			return label
	
	return null


## Create a new Label3D with the correct settings
func _create_label() -> Label3D:
	var label = Label3D.new()
	
	# Add to scene tree (at current scene level)
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(label)
	else:
		get_tree().root.add_child(label)
	
	# Configure label appearance
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color.WHITE
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.font_size = font_size
	
	# Use fixed_size so it's visible regardless of zoom level
	label.fixed_size = true
	if fixed_size_pixels > 0:
		label.pixel_size = 1.0 / fixed_size_pixels
	else:
		label.pixel_size = 0.02  # Default fallback
	
	# Start invisible
	label.visible = false
	
	return label


## Deactivate a label and return it to the pool
func _deactivate_number(label: Label3D):
	label.visible = false
	label.font_size = font_size  # Reset font size


## Clean up pool when component is removed
func _exit_tree():
	# Kill all active tweens
	for tween in _active_tweens.values():
		if is_instance_valid(tween):
			tween.kill()
	_active_tweens.clear()
	
	# Free all pooled labels
	for label in _number_pool:
		if is_instance_valid(label):
			label.queue_free()
	_number_pool.clear()
