extends GutTest

## Integration tests for GameManager.restart_scenario()
## Verifies that restarting a scenario from the pause menu fully reloads all
## managed-system state (currency, tech tree, scenarios, etc.) from the save
## slot, so the player starts the level fresh rather than carrying over any
## in-session changes.

const TEST_SLOT = 6

func before_all():
  _cleanup_test_slot()

func after_all():
  _cleanup_test_slot()

func before_each():
  # Put the game in a known PLAYING state
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  await get_tree().process_frame
  assert_true(GameManager.is_playing(), "PRECONDITION: GameManager must be in PLAYING state")

func after_each():
  _cleanup_test_slot()
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  GameManager.resume_game()

func _cleanup_test_slot():
  SaveManager.delete_save_slot(TEST_SLOT)
  SaveManager.current_save_slot = -1
  for system in SaveManager.managed_systems:
    system.reset_data()

# ---------------------------------------------------------------------------
# Helpers that simulate the save-slot reload portion of restart_scenario()
# without triggering the actual scene change (which would exit the test).
# ---------------------------------------------------------------------------

## Simulate restart_scenario() save-state reload for the given slot,
## then restore the supplied scenario ID (mirroring what the real method does).
func _simulate_restart(slot: int, scenario_id: String) -> void:
  GameManager.resume_game()
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  if slot > 0:
    SaveManager.load_save_slot(slot)
  else:
    for system in SaveManager.managed_systems:
      system.reset_data()
  if not scenario_id.is_empty():
    ScenarioManager.set_current_scenario_id(scenario_id)

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_restart_resets_scrap_to_saved_value():
  # File operations may generate engine errors in headless mode - ignore them
  # Arrange - create a save with a known scrap amount
  SaveManager.create_new_game(TEST_SLOT)
  var saved_scrap = CurrencyManager.get_scrap()

  # Earn extra scrap mid-session (simulates playing for a while)
  CurrencyManager.earn_scrap(999)
  assert_gt(CurrencyManager.get_scrap(), saved_scrap, "PRECONDITION: scrap should be higher mid-session")

  # Save the game (captures the original starting amount, not the mid-session amount,
  # because earn_scrap only fires while PLAYING and we saved right after create_new_game)
  SaveManager.save_current_slot()

  # Simulate the player earning more scrap after the last save
  CurrencyManager.earn_scrap(500)
  var pre_restart_scrap = CurrencyManager.get_scrap()
  assert_gt(pre_restart_scrap, saved_scrap + 999, "PRECONDITION: scrap should be even higher")

  # Act - simulate restart (reload the slot we saved)
  _simulate_restart(TEST_SLOT, "scenario_1")

  # Assert - scrap is back to the post-earn, pre-extra value that was saved
  assert_eq(CurrencyManager.get_scrap(), saved_scrap + 999,
    "Scrap should be restored to the saved value, not the mid-session value")

func test_restart_resets_scrap_to_starting_amount_for_new_game():
  # File operations may generate engine errors in headless mode - ignore them
  # Arrange - create a brand-new game (no prior save)
  SaveManager.create_new_game(TEST_SLOT)
  var starting_scrap = CurrencyManager.starting_scrap

  # Earn scrap during the session
  CurrencyManager.earn_scrap(300)
  assert_gt(CurrencyManager.get_scrap(), starting_scrap, "PRECONDITION: scrap should exceed starting amount")

  # Do NOT save - simulates a player who died before the auto-save
  # Act - simulate restart by reloading the slot (which only has the new-game state)
  _simulate_restart(TEST_SLOT, "scenario_1")

  # Assert - scrap should be back to starting amount because the slot was a fresh game
  assert_eq(CurrencyManager.get_scrap(), starting_scrap,
    "Scrap should be reset to the starting amount after restart with fresh save")

func test_restart_resets_tech_tree_unlocks():
  # File operations may generate engine errors in headless mode - ignore them
  # Arrange - fresh game, no techs unlocked
  SaveManager.create_new_game(TEST_SLOT)
  var initial_unlocked_count = TechTreeManager.unlocked_tech_ids.size()

  # Verify there are tech nodes available
  if TechTreeManager.tech_nodes.is_empty():
    gut.p("Skipping test - no tech nodes available")
    return

  # Simulate unlocking a tech mid-session (bypass normal prerequisites)
  var tech_id = TechTreeManager.tech_nodes.keys()[0]
  if not TechTreeManager.is_tech_unlocked(tech_id):
    TechTreeManager.unlocked_tech_ids.append(tech_id)
  assert_gt(TechTreeManager.unlocked_tech_ids.size(), initial_unlocked_count,
    "PRECONDITION: a tech should be unlocked mid-session")

  # Act - restart without saving (slot still has the fresh-game state)
  _simulate_restart(TEST_SLOT, "scenario_1")

  # Assert - tech unlocks should be reset to the fresh-game state
  assert_eq(TechTreeManager.unlocked_tech_ids.size(), initial_unlocked_count,
    "Tech tree unlocks should be reset to initial state after restart")

func test_restart_preserves_scenario_id():
  # File operations may generate engine errors in headless mode - ignore them
  # Arrange
  SaveManager.create_new_game(TEST_SLOT)
  var scenario_id = "scenario_1"
  ScenarioManager.set_current_scenario_id(scenario_id)

  # Act
  _simulate_restart(TEST_SLOT, scenario_id)

  # Assert
  assert_eq(ScenarioManager.get_current_scenario_id(), scenario_id,
    "Current scenario ID must be preserved after restart")

func test_restart_game_state_is_playing_and_unpaused():
  # Arrange - open pause menu (paused + IN_GAME_MENU state)
  SaveManager.create_new_game(TEST_SLOT)
  ScenarioManager.set_current_scenario_id("scenario_1")
  GameManager.toggle_in_game_menu()
  assert_true(GameManager.is_paused(), "PRECONDITION: game should be paused")
  assert_eq(GameManager.current_state, GameManager.GameState.IN_GAME_MENU,
    "PRECONDITION: state should be IN_GAME_MENU")

  # Act
  _simulate_restart(TEST_SLOT, "scenario_1")

  # Assert
  assert_false(GameManager.is_paused(), "Game must not be paused after restart")
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING,
    "Game state must be PLAYING after restart")

func test_restart_does_not_affect_completed_scenarios_that_were_saved():
  # File operations may generate engine errors in headless mode - ignore them
  # Restart should load exactly what was saved - completed scenario history included.
  # Arrange - complete scenario_1 and save
  SaveManager.create_new_game(TEST_SLOT)
  ScenarioManager.mark_scenario_complete("scenario_1", 90.0, 500)
  SaveManager.save_current_slot()
  var expected_completed = ScenarioManager.completed_scenarios.duplicate()

  # Simulate additional progress after the save that should be discarded
  ScenarioManager.mark_scenario_complete("scenario_2", 75.0, 800)
  assert_gt(ScenarioManager.completed_scenarios.size(), expected_completed.size(),
    "PRECONDITION: extra scenario should be completed mid-session")

  # Act - restart reloads the slot (which has only scenario_1 completed)
  _simulate_restart(TEST_SLOT, "scenario_1")

  # Assert
  assert_eq(ScenarioManager.completed_scenarios.size(), expected_completed.size(),
    "Completed scenario list should be restored from the saved state")
  assert_true(ScenarioManager.is_scenario_completed("scenario_1"),
    "scenario_1 should still be marked complete (it was in the save)")
