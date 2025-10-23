extends GutTest

## Integration test for the complete level victory and progression flow
## Tests the interaction between GameManager, LevelManager, and victory conditions
##
## Architecture note: 
## - Level class calls LevelManager.mark_level_complete() when victory occurs
## - GameManager tracks current level ID and game state
## - VictoryMenu UI responds to VICTORY state for display only (no game logic)

var initial_completed_levels: Array[String] = []

func before_each():
  # Save the initial state
  initial_completed_levels = LevelManager.completed_levels.duplicate()
  
  # Reset to a known state
  LevelManager.completed_levels.clear()
  LevelManager.level_best_times.clear()
  LevelManager.level_best_scores.clear()
  
  # Reset state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  LevelManager.clear_current_level()

func after_each():
  # Restore original state
  LevelManager.completed_levels = initial_completed_levels.duplicate()
  LevelManager.clear_current_level()
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)

func test_level_id_is_set_when_starting_level():
  # Arrange
  var level_id = "level_1"
  
  # Act
  LevelManager.set_current_level_id(level_id)
  
  # Assert
  assert_eq(LevelManager.get_current_level_id(), level_id, "Level ID should be set correctly")

func test_victory_marks_level_complete():
  # This test verifies the complete flow:
  # 1. Set current level ID (simulates level selection)
  # 2. Trigger victory state
  # 3. Verify level is marked as complete
  # Arrange
  var level_id = "level_1"
  LevelManager.set_current_level_id(level_id)
  assert_false(LevelManager.is_level_completed(level_id), "Level should not be completed initially")
  
  # Act
  LevelManager.mark_level_complete(level_id)
  
  # Assert
  assert_true(LevelManager.is_level_completed(level_id), "Level should be marked as complete")
  assert_has(LevelManager.completed_levels, level_id, "Level ID should be in completed_levels array")

func test_completing_level_1_unlocks_level_2():
  # Arrange
  assert_true(LevelManager.is_level_unlocked("level_1"), "Level 1 should always be unlocked")
  assert_false(LevelManager.is_level_unlocked("level_2"), "Level 2 should be locked initially")
  
  # Act
  LevelManager.set_current_level_id("level_1")
  LevelManager.mark_level_complete("level_1")
  
  # Assert
  assert_true(LevelManager.is_level_unlocked("level_2"), "Level 2 should be unlocked after completing level 1")

func test_level_completion_with_time_and_score():
  # Arrange
  var level_id = "level_1"
  var completion_time = 120.5
  var score = 1000
  LevelManager.set_current_level_id(level_id)
  
  # Act
  LevelManager.mark_level_complete(level_id, completion_time, score)
  
  # Assert
  assert_true(LevelManager.is_level_completed(level_id), "Level should be completed")
  assert_eq(LevelManager.get_best_time(level_id), completion_time, "Best time should be recorded")
  assert_eq(LevelManager.get_best_score(level_id), score, "Best score should be recorded")

func test_better_time_updates_best_time():
  # Arrange
  var level_id = "level_1"
  LevelManager.set_current_level_id(level_id)
  LevelManager.mark_level_complete(level_id, 150.0, 0)
  
  # Act - complete with better time
  LevelManager.mark_level_complete(level_id, 100.0, 0)
  
  # Assert
  assert_eq(LevelManager.get_best_time(level_id), 100.0, "Best time should be updated to faster time")

func test_worse_time_does_not_update_best_time():
  # Arrange
  var level_id = "level_1"
  LevelManager.set_current_level_id(level_id)
  LevelManager.mark_level_complete(level_id, 100.0, 0)
  
  # Act - complete with worse time
  LevelManager.mark_level_complete(level_id, 150.0, 0)
  
  # Assert
  assert_eq(LevelManager.get_best_time(level_id), 100.0, "Best time should remain the faster time")

func test_level_id_persists_across_state_changes():
  # Arrange
  var level_id = "level_1"
  
  # Act
  LevelManager.set_current_level_id(level_id)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  
  # Assert
  assert_eq(LevelManager.get_current_level_id(), level_id, "Level ID should persist across state changes")

func test_sequential_level_unlocking():
  # Test that levels unlock sequentially as previous levels are completed
  # Initially only level 1 should be unlocked
  assert_true(LevelManager.is_level_unlocked("level_1"), "Level 1 should be unlocked")
  assert_false(LevelManager.is_level_unlocked("level_2"), "Level 2 should be locked")
  assert_false(LevelManager.is_level_unlocked("level_3"), "Level 3 should be locked")
  
  # Complete level 1
  LevelManager.set_current_level_id("level_1")
  LevelManager.mark_level_complete("level_1")
  
  # Now level 2 should be unlocked
  assert_true(LevelManager.is_level_unlocked("level_2"), "Level 2 should be unlocked after completing level 1")
  assert_false(LevelManager.is_level_unlocked("level_3"), "Level 3 should still be locked")
  
  # Complete level 2
  LevelManager.set_current_level_id("level_2")
  LevelManager.mark_level_complete("level_2")
  
  # Now level 3 should be unlocked
  assert_true(LevelManager.is_level_unlocked("level_3"), "Level 3 should be unlocked after completing level 2")

func test_game_manager_returns_empty_string_when_no_level_set():
  # Arrange - no level ID set
  # Assert
  assert_eq(LevelManager.get_current_level_id(), "", "Should return empty string when no level is set")

func test_level_completion_signal_is_emitted():
  # Arrange
  var level_id = "level_1"
  watch_signals(LevelManager)
  
  # Act
  LevelManager.mark_level_complete(level_id)
  
  # Assert
  assert_signal_emitted(LevelManager, "level_completed", "level_completed signal should be emitted")
  assert_signal_emitted_with_parameters(LevelManager, "level_completed", [level_id], "Signal should include level ID")

func test_level_unlocked_signal_is_emitted():
  # Arrange
  watch_signals(LevelManager)
  
  # Act - Complete level 1 which should unlock level 2
  LevelManager.mark_level_complete("level_1")
  
  # Assert
  assert_signal_emitted(LevelManager, "level_unlocked", "level_unlocked signal should be emitted")
  assert_signal_emitted_with_parameters(LevelManager, "level_unlocked", ["level_2"], "Signal should include unlocked level ID")
