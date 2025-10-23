extends GutTest

## Unit tests for LevelManager autoload
## Tests level completion tracking, unlock logic, and persistence

var test_save_path = "user://test_level_progression.save"

func before_each():
  # Reset the LevelManager state before each test
  LevelManager.completed_levels.clear()
  LevelManager.level_best_times.clear()
  LevelManager.level_best_scores.clear()
  
  # Clean up any test save file
  if FileAccess.file_exists(test_save_path):
    var dir = DirAccess.open("user://")
    if dir:
      dir.remove(test_save_path.replace("user://", ""))

func after_each():
  # Clean up test save file
  if FileAccess.file_exists(test_save_path):
    var dir = DirAccess.open("user://")
    if dir:
      dir.remove(test_save_path.replace("user://", ""))

func test_level_1_is_always_unlocked():
  # Act & Assert
  assert_true(LevelManager.is_level_unlocked("level_1"), "Level 1 should always be unlocked")

func test_level_2_locked_by_default():
  # Act & Assert
  assert_false(LevelManager.is_level_unlocked("level_2"), "Level 2 should be locked initially")

func test_completing_level_1_unlocks_level_2():
  # Arrange - Level 2 should be locked initially
  assert_false(LevelManager.is_level_unlocked("level_2"), "Level 2 should be locked initially")
  
  # Act - Complete level 1
  LevelManager.mark_level_complete("level_1")
  
  # Assert - Level 2 should now be unlocked
  assert_true(LevelManager.is_level_unlocked("level_2"), "Level 2 should be unlocked after completing level 1")

func test_mark_level_complete_adds_to_completed_list():
  # Arrange
  var initial_count = LevelManager.completed_levels.size()
  
  # Act
  LevelManager.mark_level_complete("level_1")
  
  # Assert
  assert_eq(LevelManager.completed_levels.size(), initial_count + 1, "Completed levels should increase by 1")
  assert_true(LevelManager.completed_levels.has("level_1"), "Level 1 should be in completed list")

func test_is_level_completed_returns_correct_status():
  # Arrange - Level not completed
  assert_false(LevelManager.is_level_completed("level_1"), "Level 1 should not be completed initially")
  
  # Act - Complete level
  LevelManager.mark_level_complete("level_1")
  
  # Assert - Level is completed
  assert_true(LevelManager.is_level_completed("level_1"), "Level 1 should be completed")

func test_best_time_tracking():
  # Arrange - No best time initially
  assert_eq(LevelManager.get_best_time("level_1"), 0.0, "Best time should be 0.0 initially")
  
  # Act - Complete with a time
  LevelManager.mark_level_complete("level_1", 120.5)
  
  # Assert - Best time is recorded
  assert_eq(LevelManager.get_best_time("level_1"), 120.5, "Best time should be recorded")

func test_best_time_only_updates_when_better():
  # Arrange - Set initial best time
  LevelManager.mark_level_complete("level_1", 120.5)
  
  # Act - Complete with worse time
  LevelManager.mark_level_complete("level_1", 150.0)
  
  # Assert - Best time should still be 120.5
  assert_eq(LevelManager.get_best_time("level_1"), 120.5, "Best time should not update with worse time")
  
  # Act - Complete with better time
  LevelManager.mark_level_complete("level_1", 100.0)
  
  # Assert - Best time should update to 100.0
  assert_eq(LevelManager.get_best_time("level_1"), 100.0, "Best time should update with better time")

func test_best_score_tracking():
  # Arrange - No best score initially
  assert_eq(LevelManager.get_best_score("level_1"), 0, "Best score should be 0 initially")
  
  # Act - Complete with a score
  LevelManager.mark_level_complete("level_1", 0.0, 1000)
  
  # Assert - Best score is recorded
  assert_eq(LevelManager.get_best_score("level_1"), 1000, "Best score should be recorded")

func test_best_score_only_updates_when_higher():
  # Arrange - Set initial best score
  LevelManager.mark_level_complete("level_1", 0.0, 1000)
  
  # Act - Complete with lower score
  LevelManager.mark_level_complete("level_1", 0.0, 500)
  
  # Assert - Best score should still be 1000
  assert_eq(LevelManager.get_best_score("level_1"), 1000, "Best score should not update with lower score")
  
  # Act - Complete with higher score
  LevelManager.mark_level_complete("level_1", 0.0, 1500)
  
  # Assert - Best score should update to 1500
  assert_eq(LevelManager.get_best_score("level_1"), 1500, "Best score should update with higher score")

func test_get_level_metadata_returns_correct_data():
  # Act
  var metadata = LevelManager.get_level_metadata("level_1")
  
  # Assert
  assert_true(metadata.has("name"), "Metadata should have name field")
  assert_true(metadata.has("scene_path"), "Metadata should have scene_path field")
  assert_true(metadata.has("description"), "Metadata should have description field")
  assert_eq(metadata.get("name"), "Bridge Defense", "Level 1 should have correct name")

func test_get_all_level_ids_returns_sorted_list():
  # Act
  var level_ids = LevelManager.get_all_level_ids()
  
  # Assert
  assert_gt(level_ids.size(), 0, "Should have at least one level")
  assert_true(level_ids.has("level_1"), "Should include level_1")
  assert_true(level_ids.has("level_2"), "Should include level_2")
  # Check if sorted
  for i in range(level_ids.size() - 1):
    assert_true(level_ids[i] <= level_ids[i + 1], "Level IDs should be sorted")

func test_get_unlock_requirement_returns_previous_level():
  # Act & Assert
  assert_eq(LevelManager.get_unlock_requirement("level_1"), "", "Level 1 has no requirement")
  assert_eq(LevelManager.get_unlock_requirement("level_2"), "level_1", "Level 2 requires level 1")
  assert_eq(LevelManager.get_unlock_requirement("level_3"), "level_2", "Level 3 requires level 2")

func test_completing_same_level_twice_doesnt_duplicate():
  # Act
  LevelManager.mark_level_complete("level_1")
  LevelManager.mark_level_complete("level_1")
  
  # Assert - Should only appear once
  var count = 0
  for level in LevelManager.completed_levels:
    if level == "level_1":
      count += 1
  assert_eq(count, 1, "Level 1 should only appear once in completed list")

func test_unlock_progression_chain():
  # Start with all levels locked except level 1
  assert_true(LevelManager.is_level_unlocked("level_1"), "Level 1 should be unlocked")
  assert_false(LevelManager.is_level_unlocked("level_2"), "Level 2 should be locked")
  assert_false(LevelManager.is_level_unlocked("level_3"), "Level 3 should be locked")
  assert_false(LevelManager.is_level_unlocked("level_4"), "Level 4 should be locked")
  
  # Complete level 1 - should unlock level 2
  LevelManager.mark_level_complete("level_1")
  assert_true(LevelManager.is_level_unlocked("level_2"), "Level 2 should be unlocked")
  assert_false(LevelManager.is_level_unlocked("level_3"), "Level 3 should still be locked")
  
  # Complete level 2 - should unlock level 3
  LevelManager.mark_level_complete("level_2")
  assert_true(LevelManager.is_level_unlocked("level_3"), "Level 3 should be unlocked")
  assert_false(LevelManager.is_level_unlocked("level_4"), "Level 4 should still be locked")
  
  # Complete level 3 - should unlock level 4
  LevelManager.mark_level_complete("level_3")
  assert_true(LevelManager.is_level_unlocked("level_4"), "Level 4 should be unlocked")
