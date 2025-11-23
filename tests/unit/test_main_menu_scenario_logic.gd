extends GutTest

## Unit tests for main menu scenario logic
## Tests that the main menu properly clears scenario state and handles scenario selection
## 
## BUG FIX: Main menu now calls initialize_default_slot() BEFORE checking unlocked scenarios
## to prevent the save load from modifying state after the check.
## 
## NOTE: We test the logic directly without instantiating the UI scene
## to avoid dependencies on asset imports (audio files, etc.)

var initial_completed_scenarios: Array[String] = []
var initial_current_scenario: String = ""

func before_each():
  # Save the initial state
  initial_completed_scenarios = ScenarioManager.completed_scenarios.duplicate()
  initial_current_scenario = ScenarioManager.get_current_scenario_id()

func after_each():
  # Restore original state
  ScenarioManager.completed_scenarios = initial_completed_scenarios.duplicate()
  if initial_current_scenario.is_empty():
    ScenarioManager.clear_current_scenario()
  else:
    ScenarioManager.set_current_scenario_id(initial_current_scenario)

## Test that scenario manager clear_current_scenario works correctly
func test_scenario_manager_clears_current_scenario():
  # Arrange - Set a scenario (as would happen when loading a save)
  ScenarioManager.set_current_scenario_id("scenario_1")
  assert_eq(ScenarioManager.get_current_scenario_id(), "scenario_1", "Scenario should be set before test")
  
  # Act - Clear the scenario (as main menu _ready() does)
  ScenarioManager.clear_current_scenario()
  
  # Assert - Scenario should be cleared
  assert_eq(ScenarioManager.get_current_scenario_id(), "", "clear_current_scenario() should clear current scenario")

## Test that clearing scenario works even after loading from save
func test_clear_scenario_after_simulated_save_load():
  # Arrange - Simulate loading a save that sets a scenario (like SaveManager does)
  ScenarioManager.set_current_scenario_id("scenario_2")
  assert_eq(ScenarioManager.get_current_scenario_id(), "scenario_2", "Scenario should be set to simulate save load")
  
  # Act - Clear scenario (simulating what main menu _ready() does)
  ScenarioManager.clear_current_scenario()
  
  # Assert - Scenario should be cleared
  assert_eq(ScenarioManager.get_current_scenario_id(), "", "Should clear scenario even after simulated save load")

## Test that unlocked scenarios logic works with cleared current scenario
func test_unlocked_scenarios_with_cleared_current_scenario():
  # Arrange - Set up a state where multiple scenarios are unlocked
  ScenarioManager.completed_scenarios.clear()
  ScenarioManager.mark_scenario_complete("scenario_1")
  
  # Verify scenario 2 is now unlocked
  assert_true(ScenarioManager.is_scenario_unlocked("scenario_1"), "Scenario 1 should be unlocked")
  assert_true(ScenarioManager.is_scenario_unlocked("scenario_2"), "Scenario 2 should be unlocked after completing scenario 1")
  
  # Set a current scenario (simulating save load)
  ScenarioManager.set_current_scenario_id("scenario_1")
  assert_eq(ScenarioManager.get_current_scenario_id(), "scenario_1", "Current scenario should be set")
  
  # Act - Clear the scenario (simulating main menu _ready())
  ScenarioManager.clear_current_scenario()
  
  # Assert - Current scenario should be empty
  assert_eq(ScenarioManager.get_current_scenario_id(), "", "Current scenario should be cleared")
  
  # Verify the unlocked scenarios check still works correctly with empty current scenario
  var unlocked_scenarios: Array[String] = []
  var scenario_ids = ScenarioManager.get_all_scenario_ids()
  for scenario_id in scenario_ids:
    if ScenarioManager.is_scenario_unlocked(scenario_id):
      unlocked_scenarios.append(scenario_id)
  
  assert_gt(unlocked_scenarios.size(), 1, "Should have multiple unlocked scenarios")
  assert_true(unlocked_scenarios.has("scenario_1"), "Should include scenario_1")
  assert_true(unlocked_scenarios.has("scenario_2"), "Should include scenario_2")

## Test that only scenario_1 is unlocked for new game
func test_only_scenario_1_unlocked_for_new_game():
  # Arrange - Clear all completion data (simulating new game)
  ScenarioManager.completed_scenarios.clear()
  ScenarioManager.clear_current_scenario()
  
  # Assert - Current scenario should be empty
  assert_eq(ScenarioManager.get_current_scenario_id(), "", "Current scenario should be empty")
  
  # Verify only scenario_1 is unlocked
  var unlocked_scenarios: Array[String] = []
  var scenario_ids = ScenarioManager.get_all_scenario_ids()
  for scenario_id in scenario_ids:
    if ScenarioManager.is_scenario_unlocked(scenario_id):
      if scenario_id != "scenario_test": # Exclude test scenarios
        unlocked_scenarios.append(scenario_id)
  
  assert_eq(unlocked_scenarios.size(), 1, "Should have only one unlocked scenario")
  assert_eq(unlocked_scenarios[0], "scenario_1", "Only scenario_1 should be unlocked for new game")

## Test that is_scenario_unlocked doesn't depend on current_scenario_id
func test_is_scenario_unlocked_independent_of_current_scenario():
  # Arrange - Complete scenario 1 to unlock scenario 2
  ScenarioManager.completed_scenarios.clear()
  ScenarioManager.mark_scenario_complete("scenario_1")
  
  # Set current scenario to something
  ScenarioManager.set_current_scenario_id("scenario_1")
  assert_eq(ScenarioManager.get_current_scenario_id(), "scenario_1", "Current scenario should be set")
  
  # Act - Check unlocked status before clearing
  var unlocked_before_clear = ScenarioManager.is_scenario_unlocked("scenario_2")
  
  # Clear current scenario
  ScenarioManager.clear_current_scenario()
  
  # Check unlocked status after clearing
  var unlocked_after_clear = ScenarioManager.is_scenario_unlocked("scenario_2")
  
  # Assert - Unlock status should be the same regardless of current_scenario_id
  assert_true(unlocked_before_clear, "Scenario 2 should be unlocked before clearing current scenario")
  assert_true(unlocked_after_clear, "Scenario 2 should still be unlocked after clearing current scenario")
  assert_eq(unlocked_before_clear, unlocked_after_clear, "Unlock status should not depend on current_scenario_id")
