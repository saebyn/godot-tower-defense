extends Control
class_name SpawnIndicator

## A UI component that displays a notification when enemies spawn

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var notification_duration: float = 2.0

func _ready() -> void:
	# Start hidden
	modulate.a = 0.0

### Show a notification that an enemy has spawned
func show_spawn_notification(enemy: Node3D) -> void:
	if label:
		label.text = "⚠️ Enemy Spawning!"
	
	# Play fade in/out animation
	if animation_player and animation_player.has_animation("spawn_notification"):
		animation_player.play("spawn_notification")
	else:
		# Fallback: simple tween animation
		_simple_fade_animation()

### Simple fade in/out animation as fallback
func _simple_fade_animation() -> void:
	var tween = create_tween()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	# Hold
	tween.tween_interval(notification_duration - 0.6)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3)