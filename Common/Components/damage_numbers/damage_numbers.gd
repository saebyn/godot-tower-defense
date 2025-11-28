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
## Speed at which numbers float upward
@export var float_speed: float = 1.0
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
# Active numbers being animated
var _active_numbers: Array[Dictionary] = []


func _ready():
	# Register this component in parent's metadata for discovery
	if get_parent():
		get_parent().set_meta("damage_numbers_component", self)


func _process(delta: float):
	# Animate active numbers
	var to_remove: Array[int] = []
	
	for i in range(_active_numbers.size()):
		var data = _active_numbers[i]
		data.elapsed_time += delta
		
		var progress = data.elapsed_time / fade_duration
		
		if progress >= 1.0:
			# Animation complete, deactivate
			_deactivate_number(data.label)
			to_remove.append(i)
		else:
			# Float upward
			data.label.global_position = data.start_position + Vector3.UP * (float_distance * progress)
			
			# Fade out
			var alpha = 1.0 - progress
			var current_color = data.label.modulate
			data.label.modulate = Color(current_color.r, current_color.g, current_color.b, alpha)
	
	# Remove completed animations (in reverse order to maintain indices)
	for i in range(to_remove.size() - 1, -1, -1):
		_active_numbers.remove_at(to_remove[i])


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
	
	# Position and activate
	label.global_position = world_position
	label.visible = true
	
	# Add to active list for animation
	_active_numbers.append({
		"label": label,
		"start_position": world_position,
		"elapsed_time": 0.0,
		"number_type": number_type
	})
	
	Logger.trace("DamageNumbers", "Displaying %s at position %v" % [label.text, world_position])


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
	
	# Pool full - reuse oldest active one
	if not _active_numbers.is_empty():
		var oldest_data = _active_numbers[0]
		_active_numbers.remove_at(0)
		_deactivate_number(oldest_data.label)
		return oldest_data.label
	
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
	label.pixel_size = 1.0 / fixed_size_pixels
	
	# Start invisible
	label.visible = false
	
	return label


## Deactivate a label and return it to the pool
func _deactivate_number(label: Label3D):
	label.visible = false
	label.font_size = font_size  # Reset font size


## Clean up pool when component is removed
func _exit_tree():
	for label in _number_pool:
		if is_instance_valid(label):
			label.queue_free()
	_number_pool.clear()
	_active_numbers.clear()
