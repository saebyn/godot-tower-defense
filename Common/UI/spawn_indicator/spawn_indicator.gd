extends Control
class_name SpawnIndicator

## A UI component that displays information about wave spawning and progress

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var notification_duration: float = 3.0 # Increased duration for more info
var current_wave: Wave
var wave_number: int = 0
var is_showing_wave_info: bool = false

func _ready() -> void:
  # Start hidden
  modulate.a = 0.0

func _process(_delta: float) -> void:
  # Update wave display continuously when showing wave info
  if is_showing_wave_info and current_wave and current_wave.is_active():
    _update_wave_display()

### Show a notification that an enemy has spawned (legacy support)
func show_spawn_notification(enemy: Node3D) -> void:
  if label:
    label.text = "⚠️ Enemy Spawning!"
  
  # Play fade in/out animation
  if animation_player and animation_player.has_animation("spawn_notification"):
    animation_player.play("spawn_notification")
  else:
    # Fallback: simple tween animation
    _simple_fade_animation()

### Show wave start notification with detailed information
func show_wave_started(wave: Wave, wave_num: int) -> void:
  current_wave = wave
  wave_number = wave_num
  is_showing_wave_info = true
  _update_wave_display()
  
  # Show the indicator and keep it visible during the wave
  modulate.a = 1.0

### Show wave completed notification
func show_wave_completed(wave: Wave, wave_num: int) -> void:
  is_showing_wave_info = false
  if label:
    var total_enemies = 0
    for count in wave.enemy_counts:
      total_enemies += count
    label.text = "✅ Wave %d Complete!\n%d enemies defeated" % [wave_num, total_enemies]
  
  # Play fade in/out animation
  if animation_player and animation_player.has_animation("spawn_notification"):
    animation_player.play("spawn_notification")
  else:
    # Fallback: simple tween animation
    _simple_fade_animation()

### Update display with current wave information
func _update_wave_display() -> void:
  if not label or not current_wave:
    return
  
  # Calculate total enemies in this wave
  var total_enemies = 0
  for count in current_wave.enemy_counts:
    total_enemies += count
  
  # Get remaining enemies
  var remaining = current_wave.get_remaining_enemies()
  var spawned = total_enemies - remaining
  
  # Create informative display text
  var display_text = "🌊 Wave %d\n" % wave_number
  display_text += "Duration: %.1fs\n" % current_wave.duration
  display_text += "Progress: %d/%d enemies\n" % [spawned, total_enemies]
  display_text += "Remaining: %d" % remaining
  
  label.text = display_text

### Simple fade in/out animation as fallback
func _simple_fade_animation() -> void:
  var tween = create_tween()
  tween.set_ease(Tween.EASE_OUT)
  tween.set_trans(Tween.TRANS_QUART)
  
  # Fade in
  tween.tween_property(self, "modulate:a", 1.0, 0.3)
  # Hold
  tween.tween_interval(notification_duration - 0.6)
  # Fade out
  tween.tween_property(self, "modulate:a", 0.0, 0.3)

### Show a notification that an obstacle was removed
func show_obstacle_removed(refund_amount: int) -> void:
  if label:
    label.text = "🗑️ Obstacle Removed!\n💰 Refund: %d currency" % refund_amount
  
  # Play fade in/out animation
  if animation_player and animation_player.has_animation("spawn_notification"):
    animation_player.play("spawn_notification")
  else:
    # Fallback: simple tween animation
    _simple_fade_animation()