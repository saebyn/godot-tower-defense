extends GutTest

## Unit tests for AchievementNotificationManager

var manager: AchievementNotificationManager = null

func before_each():
  # Create manager instance
  manager = AchievementNotificationManager.new()
  add_child(manager)
  await wait_frames(2) # Allow ready to be called

func after_each():
  # Clean up manager after each test
  if manager:
    manager.queue_free()
    manager = null

func test_manager_queues_achievements():
  # Arrange
  var achievement1 = AchievementResource.new()
  achievement1.id = "test1"
  achievement1.name = "Achievement 1"
  achievement1.description = "First achievement"
  
  var achievement2 = AchievementResource.new()
  achievement2.id = "test2"
  achievement2.name = "Achievement 2"
  achievement2.description = "Second achievement"
  
  # Act
  manager._on_achievement_unlocked(achievement1)
  manager._on_achievement_unlocked(achievement2)
  
  # Assert - One should be showing, one should be queued
  assert_eq(manager.notification_queue.size(), 1, "One achievement should be queued")
  assert_true(manager.is_showing_notification, "Should be showing a notification")

func test_manager_handles_null_achievement():
  # Act
  manager._on_achievement_unlocked(null)
  
  # Assert
  assert_eq(manager.notification_queue.size(), 0, "Queue should be empty for null achievement")
  assert_false(manager.is_showing_notification, "Should not be showing notification")

func test_clear_queue_removes_all_notifications():
  # Arrange
  var achievement1 = AchievementResource.new()
  achievement1.id = "test1"
  achievement1.name = "Achievement 1"
  achievement1.description = "First achievement"
  
  var achievement2 = AchievementResource.new()
  achievement2.id = "test2"
  achievement2.name = "Achievement 2"
  achievement2.description = "Second achievement"
  
  manager._on_achievement_unlocked(achievement1)
  manager._on_achievement_unlocked(achievement2)
  
  # Act
  manager.clear_queue()
  
  # Assert
  assert_eq(manager.notification_queue.size(), 0, "Queue should be empty after clear")

func test_manager_shows_next_after_current_finishes():
  # Arrange
  var achievement1 = AchievementResource.new()
  achievement1.id = "test1"
  achievement1.name = "Achievement 1"
  achievement1.description = "First achievement"
  
  var achievement2 = AchievementResource.new()
  achievement2.id = "test2"
  achievement2.name = "Achievement 2"
  achievement2.description = "Second achievement"
  
  # Act
  manager._on_achievement_unlocked(achievement1)
  manager._on_achievement_unlocked(achievement2)
  
  # Simulate notification finished
  var initial_queue_size = manager.notification_queue.size()
  manager._on_notification_finished()
  await wait_frames(2)
  
  # Assert
  assert_lt(manager.notification_queue.size(), initial_queue_size, "Queue size should decrease after showing next")
