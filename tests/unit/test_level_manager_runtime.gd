extends GutTest

## Unit tests for LevelManager runtime state management
## Tests level ID tracking, wave tracking, and their integration with persistent progression

var initial_completed_levels: Array[String] = []

func before_each():
  # Save the initial state
  initial_completed_levels = LevelManager.completed_levels.duplicate()
  
  # Reset to a known state
  LevelManager.clear_current_level()
  LevelManager.completed_levels.clear()
  LevelManager.level_best_times.clear()
  LevelManager.level_best_scores.clear()

func after_each():
  # Restore original state
  LevelManager.completed_levels = initial_completed_levels.duplicate()
  LevelManager.clear_current_level()

## Runtime State Tests

func test_set_and_get_current_level_id():
  # Arrange
  var level_id = "level_1"
  
  # Act
  LevelManager.set_current_level_id(level_id)
  
  # Assert
  assert_eq(LevelManager.get_current_level_id(), level_id, "Should return the level ID that was set")

func test_level_id_starts_empty():
  # Assert
  assert_eq(LevelManager.get_current_level_id(), "", "Level ID should start empty")

func test_set_current_level_emits_signal():
  # Arrange
  watch_signals(LevelManager)
  var level_id = "level_2"
  
  # Act
  LevelManager.set_current_level_id(level_id)
  
  # Assert
  assert_signal_emitted(LevelManager, "level_started", "level_started signal should be emitted")
  assert_signal_emitted_with_parameters(LevelManager, "level_started", [level_id], "Signal should include level ID")

func test_clear_current_level():
  # Arrange
  LevelManager.set_current_level_id("level_3")
  assert_eq(LevelManager.get_current_level_id(), "level_3", "Level should be set")
  watch_signals(LevelManager)
  
  # Act
  LevelManager.clear_current_level()
  
  # Assert
  assert_eq(LevelManager.get_current_level_id(), "", "Level ID should be cleared")
  assert_signal_emitted(LevelManager, "level_ended", "level_ended signal should be emitted")

func test_wave_tracking():
  # Arrange
  LevelManager.set_current_level_id("level_1")
  
  # Act
  LevelManager.set_current_wave(5)
  
  # Assert
  assert_eq(LevelManager.get_current_wave(), 5, "Should track current wave")

func test_wave_changed_signal():
  # Arrange
  LevelManager.set_current_level_id("level_1")
  watch_signals(LevelManager)
  
  # Act
  LevelManager.set_current_wave(3)
  
  # Assert
  assert_signal_emitted(LevelManager, "wave_changed", "wave_changed signal should be emitted")
  assert_signal_emitted_with_parameters(LevelManager, "wave_changed", ["level_1", 3], "Signal should include level ID and wave")

func test_changing_level_resets_wave():
  # Arrange
  LevelManager.set_current_level_id("level_1")
  LevelManager.set_current_wave(5)
  assert_eq(LevelManager.get_current_wave(), 5, "Wave should be 5")
  
  # Act - Change to different level
  LevelManager.set_current_level_id("level_2")
  
  # Assert
  assert_eq(LevelManager.get_current_wave(), 0, "Wave should reset to 0 when changing levels")

func test_clearing_level_resets_wave():
  # Arrange
  LevelManager.set_current_level_id("level_1")
  LevelManager.set_current_wave(7)
  
  # Act
  LevelManager.clear_current_level()
  
  # Assert
  assert_eq(LevelManager.get_current_wave(), 0, "Wave should reset to 0 when clearing level")

## Integration Tests - Runtime + Persistent State

func test_completing_current_level():
  # Test that you can complete the currently active level
  # Arrange
  var level_id = "level_1"
  LevelManager.set_current_level_id(level_id)
  
  # Act
  LevelManager.mark_level_complete(level_id)
  
  # Assert
  assert_true(LevelManager.is_level_completed(level_id), "Level should be marked complete")
  assert_eq(LevelManager.get_current_level_id(), level_id, "Current level ID should remain set")

func test_runtime_state_independent_of_completion():
  # Verify that completion status doesn't affect current level tracking
  # Arrange
  LevelManager.set_current_level_id("level_1")
  LevelManager.mark_level_complete("level_1")
  
  # Act - Play the same level again
  LevelManager.clear_current_level()
  LevelManager.set_current_level_id("level_1")
  
  # Assert
  assert_eq(LevelManager.get_current_level_id(), "level_1", "Can replay completed level")
  assert_true(LevelManager.is_level_completed("level_1"), "Completion status persists")

func test_wave_progress_during_level_replay():
  # Verify wave tracking works correctly when replaying levels
  # Arrange
  LevelManager.mark_level_complete("level_1") # Complete it once
  
  # Act - Play it again
  LevelManager.set_current_level_id("level_1")
  LevelManager.set_current_wave(3)
  
  # Assert
  assert_eq(LevelManager.get_current_wave(), 3, "Wave tracking should work in replay")
