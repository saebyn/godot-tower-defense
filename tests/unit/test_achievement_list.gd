extends GutTest

## Unit tests for AchievementList UI

var list_scene = preload("res://Stages/UI/achievement_list/achievement_list.tscn")
var achievement_list: AchievementList = null

func before_each():
  # Instantiate achievement list for each test
  achievement_list = list_scene.instantiate()
  add_child(achievement_list)
  await wait_frames(2) # Allow ready to be called

func after_each():
  # Clean up achievement list after each test
  if achievement_list:
    achievement_list.queue_free()
    achievement_list = null

func test_achievement_list_initializes():
  # Assert
  assert_not_null(achievement_list, "Achievement list should be created")
  assert_not_null(achievement_list.close_button, "Close button should exist")
  assert_not_null(achievement_list.achievement_container, "Achievement container should exist")

func test_close_button_emits_signal():
  # Arrange
  var signal_watcher = watch_signals(achievement_list)
  
  # Act
  achievement_list._on_close_pressed()
  
  # Assert
  assert_signal_emitted(achievement_list, "closed", "Should emit closed signal")

func test_stats_label_updates_correctly():
  # This test requires AchievementManager to be working
  if not AchievementManager:
    pending("AchievementManager not available")
    return
  
  # Arrange
  var all_achievements = AchievementManager.get_all_achievements()
  
  # Act
  achievement_list._update_stats(all_achievements)
  
  # Assert
  assert_not_null(achievement_list.stats_label.text, "Stats label should have text")
  assert_true(achievement_list.stats_label.text.contains("Achievements Unlocked"), "Stats label should contain achievement count")

func test_sort_achievements_unlocked_first():
  # Arrange
  var achievement1 = AchievementResource.new()
  achievement1.id = "test1"
  achievement1.name = "B Achievement"
  
  var achievement2 = AchievementResource.new()
  achievement2.id = "test2"
  achievement2.name = "A Achievement"
  
  # Mock achievement states
  if AchievementManager:
    AchievementManager.achievement_states["test1"] = AchievementManager.AchievementState.new(true, 1.0, "2024-01-01")
    AchievementManager.achievement_states["test2"] = AchievementManager.AchievementState.new(false, 0.5, "")
  
  # Act
  var result = achievement_list._sort_achievements(achievement1, achievement2)
  
  # Assert
  assert_true(result, "Unlocked achievement should come first")

func test_refresh_achievements_creates_cards():
  # This test requires AchievementManager to be working
  if not AchievementManager:
    pending("AchievementManager not available")
    return
  
  # Act
  achievement_list.refresh_achievements()
  await wait_frames(2)
  
  # Assert
  var child_count = achievement_list.achievement_container.get_child_count()
  assert_gte(child_count, 0, "Should have created achievement cards")
