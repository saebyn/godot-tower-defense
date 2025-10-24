extends GutTest

## Unit tests for AchievementNotification component

var notification_scene = preload("res://Common/UI/achievement_notification/achievement_notification.tscn")
var notification: AchievementNotification = null

func before_each():
  # Instantiate notification for each test
  notification = notification_scene.instantiate()
  add_child(notification)

func after_each():
  # Clean up notification after each test
  if notification:
    notification.queue_free()
    notification = null

func test_notification_starts_hidden():
  # Assert
  assert_false(notification.visible, "Notification should start hidden")
  assert_eq(notification.modulate.a, 0.0, "Notification should start transparent")

func test_notification_shows_achievement_data():
  # Arrange
  var achievement = AchievementResource.new()
  achievement.id = "test_achievement"
  achievement.name = "Test Achievement"
  achievement.description = "This is a test achievement"
  
  # Act
  notification.show_notification(achievement)
  await wait_frames(2) # Wait for scene tree processing
  
  # Assert
  assert_true(notification.visible, "Notification should become visible")
  assert_eq(notification.name_label.text, "Test Achievement", "Name should be set correctly")
  assert_eq(notification.description_label.text, "This is a test achievement", "Description should be set correctly")

func test_notification_handles_null_achievement():
  # Act
  notification.show_notification(null)
  
  # Assert
  assert_false(notification.is_showing, "Should not show for null achievement")

func test_notification_emits_finished_signal():
  # Arrange
  var achievement = AchievementResource.new()
  achievement.id = "test_achievement"
  achievement.name = "Test Achievement"
  achievement.description = "Test description"
  
  var signal_watcher = watch_signals(notification)
  
  # Act
  notification.show_notification(achievement)
  notification.force_hide()
  
  # Assert
  assert_signal_emitted(notification, "notification_finished", "Should emit notification_finished signal")

func test_force_hide_stops_timers():
  # Arrange
  var achievement = AchievementResource.new()
  achievement.id = "test_achievement"
  achievement.name = "Test Achievement"
  achievement.description = "Test description"
  
  notification.show_notification(achievement)
  
  # Act
  notification.force_hide()
  
  # Assert
  assert_false(notification.auto_hide_timer.is_stopped(), "Timer should be stopped")
  assert_false(notification.is_showing, "Should not be showing after force hide")
