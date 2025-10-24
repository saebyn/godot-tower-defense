extends CanvasLayer
class_name AchievementNotificationManager

## Manages the queue and display of achievement notifications
## Ensures only one notification is displayed at a time

const AchievementNotificationScene = preload("res://Common/UI/achievement_notification/achievement_notification.tscn")

var notification_queue: Array[AchievementResource] = []
var current_notification: AchievementNotification = null
var is_showing_notification: bool = false

func _ready() -> void:
  # Connect to AchievementManager
  if AchievementManager:
    AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
    Logger.info("AchievementNotificationManager", "Connected to AchievementManager")
  else:
    Logger.error("AchievementNotificationManager", "AchievementManager not found!")

## Handle achievement unlock events
func _on_achievement_unlocked(achievement: AchievementResource) -> void:
  if not achievement:
    return
  
  # Add to queue
  notification_queue.append(achievement)
  Logger.debug("AchievementNotificationManager", "Queued achievement: %s" % achievement.name)
  
  # Try to show next notification
  _show_next_notification()

## Show the next notification in the queue
func _show_next_notification() -> void:
  # Don't show if already showing or queue is empty
  if is_showing_notification or notification_queue.is_empty():
    return
  
  # Get next achievement from queue
  var achievement = notification_queue.pop_front()
  
  # Create notification instance
  current_notification = AchievementNotificationScene.instantiate()
  add_child(current_notification)
  current_notification.notification_finished.connect(_on_notification_finished)
  
  # Show notification
  is_showing_notification = true
  current_notification.show_notification(achievement)

## Handle notification finished
func _on_notification_finished() -> void:
  is_showing_notification = false
  
  # Clean up current notification
  if current_notification:
    current_notification.queue_free()
    current_notification = null
  
  # Show next notification if any
  _show_next_notification()

## Clear all queued notifications (useful for cleanup)
func clear_queue() -> void:
  notification_queue.clear()
  
  if current_notification and is_showing_notification:
    current_notification.force_hide()
