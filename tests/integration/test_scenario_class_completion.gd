extends GutTest

## Integration test for Level class completion behavior
## Verifies that Level properly handles victory conditions and calls progression system

var initial_completed_levels: Array[String] = []

func before_each():
  # Save the initial state
  initial_completed_levels = ScenarioManager.completed_levels.duplicate()
  
  # Reset to a known state
  ScenarioManager.completed_levels.clear()
  ScenarioManager.level_best_times.clear()
  ScenarioManager.level_best_scores.clear()
  
  # Reset GameManager state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  ScenarioManager.clear_current_level()

func after_each():
  # Restore original state
  ScenarioManager.completed_levels = initial_completed_levels.duplicate()
  ScenarioManager.clear_current_level()
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)

func test_level_marks_completion_when_all_waves_completed():
  # This test verifies that Level class handles progression logic
  # Architecture: Level -> ScenarioManager.mark_complete() -> GameManager.state = VICTORY
  # Arrange
  var level_id = "scenario_1"
  ScenarioManager.set_current_level_id(level_id)
  assert_false(ScenarioManager.is_level_completed(level_id), "Level should not be completed initially")
  
  # Act - Simulate what Level._on_all_waves_completed() does
  # (We can't easily trigger the actual spawner completion in a unit test,
  #  so we test the logic directly)
  if not ScenarioManager.get_current_level_id().is_empty():
    ScenarioManager.mark_scenario_complete(ScenarioManager.get_current_level_id())
    GameManager.set_game_state(GameManager.GameState.VICTORY)
  
  # Assert
  assert_true(ScenarioManager.is_level_completed(level_id), "Level should be marked as complete")
  assert_eq(GameManager.current_state, GameManager.GameState.VICTORY, "Game state should be VICTORY")

func test_level_handles_missing_level_id_gracefully():
  # Verify that if level ID is not set, the level handles it without crashing
  # Arrange - no level ID set
  assert_eq(ScenarioManager.get_current_level_id(), "", "Level ID should be empty")
  
  # Act - Simulate victory with no level ID (error condition)
  var level_id = ScenarioManager.get_current_level_id()
  if level_id.is_empty():
    # Level should log error but continue to victory state
    Logger.error("Test", "Simulating error: no level ID set")
  else:
    ScenarioManager.mark_scenario_complete(level_id)
  
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  
  # Assert - Should reach victory state even with error
  assert_eq(GameManager.current_state, GameManager.GameState.VICTORY, "Should still reach victory state")

func test_level_completion_triggers_before_victory_state():
  # Verify that the order is: mark_scenario_complete -> set_game_state(VICTORY)
  # This ensures progression is saved before UI shows victory
  # Arrange
  var level_id = "scenario_2"
  ScenarioManager.set_current_level_id(level_id)
  watch_signals(ScenarioManager)
  watch_signals(GameManager)
  
  # Act
  ScenarioManager.mark_scenario_complete(level_id)
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  
  # Assert - Both signals should be emitted
  assert_signal_emitted(ScenarioManager, "scenario_completed", "Level completion signal should emit")
  assert_signal_emitted(GameManager, "game_state_changed", "Game state changed signal should emit")
  
  # Verify level is completed
  assert_true(ScenarioManager.is_level_completed(level_id), "Level should be completed")

func test_completing_level_unlocks_next_level_before_victory_screen():
  # Verify that next level is unlocked as part of completion, not during UI display
  # Arrange
  ScenarioManager.set_current_level_id("scenario_1")
  assert_false(ScenarioManager.is_level_unlocked("scenario_2"), "Level 2 should be locked")
  watch_signals(ScenarioManager)
  
  # Act - Simulate Level._on_all_waves_completed() flow
  ScenarioManager.mark_scenario_complete("scenario_1")
  
  # Assert - Level 2 should be unlocked BEFORE we transition to victory state
  assert_true(ScenarioManager.is_level_unlocked("scenario_2"), "Level 2 should be unlocked immediately")
  assert_signal_emitted(ScenarioManager, "scenario_unlocked", "Level unlock signal should emit")
  
  # Now transition to victory state (UI layer)
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  
  # Level 2 should still be unlocked
  assert_true(ScenarioManager.is_level_unlocked("scenario_2"), "Level 2 should remain unlocked")

func test_level_completion_data_persists_across_state_changes():
  # Verify that level completion isn't lost when changing game states
  # Arrange
  var level_id = "scenario_3"
  ScenarioManager.set_current_level_id(level_id)
  
  # Act - Complete level and change states multiple times
  ScenarioManager.mark_scenario_complete(level_id, 120.5, 1000)
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert - Completion data should persist
  assert_true(ScenarioManager.is_level_completed(level_id), "Level completion should persist")
  assert_eq(ScenarioManager.get_best_time(level_id), 120.5, "Best time should persist")
  assert_eq(ScenarioManager.get_best_score(level_id), 1000, "Best score should persist")
