"""
HealthDisplay.gd

A reusable UI component that displays health bars above entities.
This component automatically follows its parent's position and shows current HP.
"""
extends Control
class_name HealthDisplay

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel

var target_health: Health
var camera: Camera3D
var world_offset: Vector3 = Vector3(0, 3, 0)  # Offset above the entity

func setup(health_component: Health, main_camera: Camera3D):
	target_health = health_component
	camera = main_camera
	
	# Connect to health signals
	if target_health:
		target_health.damaged.connect(_on_health_damaged)
		target_health.died.connect(_on_health_died)
		_update_display()

func _process(_delta: float):
	if target_health and camera and is_inside_tree():
		# Convert world position to screen position
		var world_pos = get_parent().global_position + world_offset
		var screen_pos = camera.unproject_position(world_pos)
		
		# Update position
		global_position = screen_pos - size / 2
		
		# Hide if behind camera
		var is_behind = camera.is_position_behind(world_pos)
		visible = not is_behind

func _update_display():
	if not target_health:
		return
		
	var max_hp = target_health.max_hitpoints
	var current_hp = target_health.hitpoints
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	
	if health_label:
		health_label.text = str(current_hp) + "/" + str(max_hp)

func _on_health_damaged(amount: int, hitpoints: int):
	_update_display()
	
	# Create floating damage number
	_show_damage_number(amount)

func _on_health_died():
	_update_display()
	# Could add death animation here
	# For now, just hide after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _show_damage_number(damage: int):
	# Create a floating damage number effect
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.add_theme_font_size_override("font_size", 24)
	
	# Add to the same UI parent as this health display
	get_parent().add_child(damage_label)
	
	# Position near the health bar but offset
	damage_label.global_position = global_position + Vector2(20, -10)
	
	# Animate the damage number
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "global_position", damage_label.global_position + Vector2(0, -50), 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
	
	# Remove after animation
	await tween.finished
	damage_label.queue_free()