extends Control
class_name AchievementNotification

## Toast notification that slides in from top-right to show achievement unlocks
## Auto-hides after 5 seconds and supports queueing multiple notifications

signal notification_finished()

const SLIDE_DURATION = 0.5
const DISPLAY_DURATION = 5.0
const NOTIFICATION_OFFSET = Vector2(400, -100) # Start position offset

@onready var panel: PanelContainer = $PanelContainer
@onready var icon: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Icon
@onready var name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DescriptionLabel
@onready var auto_hide_timer: Timer = $AutoHideTimer
@onready var slide_in_tween: Tween = null
@onready var slide_out_tween: Tween = null

var target_position: Vector2 = Vector2.ZERO
var is_showing: bool = false

func _ready() -> void:
  # Start hidden off-screen
  visible = false
  modulate.a = 0.0
  
  # Setup timer
  auto_hide_timer.wait_time = DISPLAY_DURATION
  auto_hide_timer.timeout.connect(_on_auto_hide_timeout)

## Show notification with achievement data
func show_notification(achievement: AchievementResource) -> void:
  if not achievement:
    Logger.warn("AchievementNotification", "Attempted to show notification with null achievement")
    return
  
  # Set achievement data
  name_label.text = achievement.name
  description_label.text = achievement.description
  
  # Set icon if available
  if achievement.icon:
    icon.texture = achievement.icon
    icon.visible = true
  else:
    icon.visible = false
  
  is_showing = true
  
  # Play unlock sound effect
  if AudioManager:
    var audio_player = AudioStreamPlayer.new()
    add_child(audio_player)
    audio_player.finished.connect(audio_player.queue_free)
    AudioManager.play_sound(audio_player, AudioManager.SoundEffect.ACHIEVEMENT_UNLOCKED)
  
  # Animate slide in
  _slide_in()
  
  Logger.info("AchievementNotification", "Showing notification: %s" % achievement.name)

## Animate the notification sliding in from the top-right
func _slide_in() -> void:
  visible = true
  
  # Calculate target position (top-right corner with some padding)
  var viewport_size = get_viewport_rect().size
  target_position = Vector2(viewport_size.x - size.x - 20, 20)
  
  # Start position (off-screen to the right and up)
  position = target_position + NOTIFICATION_OFFSET
  modulate.a = 0.0
  
  # Create tween for smooth animation
  if slide_in_tween:
    slide_in_tween.kill()
  
  slide_in_tween = create_tween()
  slide_in_tween.set_parallel(true)
  slide_in_tween.set_ease(Tween.EASE_OUT)
  slide_in_tween.set_trans(Tween.TRANS_BACK)
  
  slide_in_tween.tween_property(self, "position", target_position, SLIDE_DURATION)
  slide_in_tween.tween_property(self, "modulate:a", 1.0, SLIDE_DURATION * 0.5)
  
  slide_in_tween.finished.connect(_on_slide_in_finished)

func _on_slide_in_finished() -> void:
  # Start auto-hide timer
  auto_hide_timer.start()

func _on_auto_hide_timeout() -> void:
  _slide_out()

## Animate the notification sliding out to the right
func _slide_out() -> void:
  if not is_showing:
    return
  
  is_showing = false
  
  # Create tween for smooth animation
  if slide_out_tween:
    slide_out_tween.kill()
  
  slide_out_tween = create_tween()
  slide_out_tween.set_parallel(true)
  slide_out_tween.set_ease(Tween.EASE_IN)
  slide_out_tween.set_trans(Tween.TRANS_BACK)
  
  var end_position = target_position + NOTIFICATION_OFFSET
  slide_out_tween.tween_property(self, "position", end_position, SLIDE_DURATION)
  slide_out_tween.tween_property(self, "modulate:a", 0.0, SLIDE_DURATION)
  
  slide_out_tween.finished.connect(_on_slide_out_finished)

func _on_slide_out_finished() -> void:
  visible = false
  notification_finished.emit()

## Force hide the notification immediately (for cleanup)
func force_hide() -> void:
  if slide_in_tween:
    slide_in_tween.kill()
  if slide_out_tween:
    slide_out_tween.kill()
  
  auto_hide_timer.stop()
  visible = false
  is_showing = false
  notification_finished.emit()
