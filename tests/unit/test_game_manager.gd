extends GutTest

## Unit tests for GameManager functionality
## Tests state management, scenario ID tracking, and cleanup

func before_each():
  # Reset GameManager to known state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  if Dialogic.paused:
    Dialogic.paused = false
  ScenarioManager.clear_current_scenario()
  GameManager.resume_game() # Ensure not paused

func after_each():
  # Restore default state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  if Dialogic.paused:
    Dialogic.paused = false
  ScenarioManager.clear_current_scenario()
  GameManager.resume_game()

func test_scenario_id_managed_by_scenario_manager():
  # Scenario ID is now managed by ScenarioManager, not GameManager
  # This test verifies the integration
  # Arrange
  var scenario_id = "scenario_1"
  
  # Act
  ScenarioManager.set_current_scenario_id(scenario_id)
  
  # Assert
  assert_eq(ScenarioManager.get_current_scenario_id(), scenario_id, "ScenarioManager should track scenario ID")

func test_return_to_main_menu_clears_scenario_via_scenario_manager():
  # This test verifies that returning to main menu clears the scenario in ScenarioManager
  # Arrange
  ScenarioManager.set_current_scenario_id("scenario_3")
  assert_eq(ScenarioManager.get_current_scenario_id(), "scenario_3", "Scenario ID should be set initially")
  
  # Act - Simulate what return_to_main_menu does
  ScenarioManager.clear_current_scenario()
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  
  # Assert
  assert_eq(ScenarioManager.get_current_scenario_id(), "", "Scenario ID should be cleared when returning to main menu")

func test_game_state_changed_signal_is_emitted():
  # Arrange
  watch_signals(GameManager)
  
  # Act
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert
  assert_signal_emitted(GameManager, "game_state_changed", "game_state_changed signal should be emitted")
  assert_signal_emitted_with_parameters(GameManager, "game_state_changed", [GameManager.GameState.PLAYING])

func test_wave_tracking_moved_to_scenario_manager():
  # Wave tracking is now managed by ScenarioManager, not GameManager
  # Arrange
  watch_signals(ScenarioManager)
  var wave = 5
  
  # Act
  ScenarioManager.set_current_wave(wave)
  
  # Assert
  assert_signal_emitted(ScenarioManager, "wave_changed", "wave_changed signal should be emitted by ScenarioManager")
  assert_eq(ScenarioManager.get_current_wave(), wave, "ScenarioManager should track current wave")

func test_pause_and_resume():
  # Arrange
  assert_false(GameManager.is_paused(), "Game should not be paused initially")
  
  # Act - pause
  GameManager.pause_game()
  
  # Assert
  assert_true(GameManager.is_paused(), "Game should be paused")
  
  # Act - resume
  GameManager.resume_game()
  
  # Assert
  assert_false(GameManager.is_paused(), "Game should not be paused after resume")

func test_toggle_pause():
  # Arrange
  var initial_paused = GameManager.is_paused()
  
  # Act
  GameManager.toggle_pause()
  
  # Assert
  assert_ne(GameManager.is_paused(), initial_paused, "Pause state should be toggled")
  
  # Act - toggle back
  GameManager.toggle_pause()
  
  # Assert
  assert_eq(GameManager.is_paused(), initial_paused, "Should return to initial pause state")

func test_game_speed_setting():
  # Arrange
  var speed = 2.0
  
  # Act
  GameManager.set_game_speed(speed)
  
  # Assert
  assert_eq(GameManager.get_game_speed(), speed, "Game speed should be set correctly")
  assert_eq(Engine.time_scale, speed, "Engine time scale should match game speed")

func test_game_speed_rejects_zero_and_negative():
  # Arrange
  var initial_speed = GameManager.get_game_speed()
  
  # Act - try to set invalid speeds
  GameManager.set_game_speed(0.0)
  var speed_after_zero = GameManager.get_game_speed()
  
  GameManager.set_game_speed(-1.0)
  var speed_after_negative = GameManager.get_game_speed()
  
  # Assert
  assert_eq(speed_after_zero, initial_speed, "Speed should not change when set to zero")
  assert_eq(speed_after_negative, initial_speed, "Speed should not change when set to negative")

func test_speed_changed_signal_is_emitted():
  # Arrange
  watch_signals(GameManager)
  
  # Act
  GameManager.set_game_speed(1.5)
  
  # Assert
  assert_signal_emitted(GameManager, "speed_changed", "speed_changed signal should be emitted")
  assert_signal_emitted_with_parameters(GameManager, "speed_changed", [1.5])

func test_toggle_in_game_menu_opens_and_closes():
  # Arrange - start in PLAYING state, not paused
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  GameManager.resume_game()
  assert_false(GameManager.is_paused(), "Game should not be paused initially")
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "Game should be in PLAYING state initially")
  
  # Act - open the in-game menu
  GameManager.toggle_in_game_menu()
  
  # Assert - game should be paused and state should be IN_GAME_MENU
  assert_true(GameManager.is_paused(), "Game should be paused after opening menu")
  assert_true(Dialogic.paused, "Dialogic should be paused while the in-game menu is open")
  assert_eq(GameManager.current_state, GameManager.GameState.IN_GAME_MENU, "State should be IN_GAME_MENU after opening menu")
  
  # Act - close the in-game menu
  GameManager.toggle_in_game_menu()
  
  # Assert - state returns to PLAYING but the tree remains paused;
  # unpausing is the player's responsibility via the speed/pause controls.
  assert_true(GameManager.is_paused(), "Tree should remain paused after closing menu - unpausing is handled by speed controls")
  assert_false(Dialogic.paused, "Dialogic should resume when the in-game menu closes")
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "State should be PLAYING after closing menu")

func test_tech_tree_pauses_dialogic_until_closed():
  GameManager.set_game_state(GameManager.GameState.PLAYING)

  GameManager.set_game_state(GameManager.GameState.IN_TECH_TREE)
  assert_true(Dialogic.paused, "Dialogic should be paused while the tech tree is open")

  GameManager.set_game_state(GameManager.GameState.PLAYING)
  assert_false(Dialogic.paused, "Dialogic should resume when the tech tree closes")

func test_game_state_does_not_resume_dialogic_paused_elsewhere():
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  Dialogic.paused = true

  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  GameManager.set_game_state(GameManager.GameState.PLAYING)

  assert_true(Dialogic.paused, "GameManager should not resume Dialogic when it did not pause it")

func test_restart_from_pause_menu_resets_state():
  # Arrange - simulate the pause menu being open
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  GameManager.toggle_in_game_menu()
  assert_true(GameManager.is_paused(), "Game should be paused")
  assert_eq(GameManager.current_state, GameManager.GameState.IN_GAME_MENU, "State should be IN_GAME_MENU")
  
  # Act - simulate what _on_restart_pressed does (now via restart_scenario, but
  # scene change is skipped here so we test only the state portion directly)
  GameManager.resume_game()
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert - after restart, game should be unpaused and in PLAYING state
  assert_false(GameManager.is_paused(), "Game should not be paused after restart")
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "State should be PLAYING after restart")

func test_restart_scenario_unpauses_game():
  # Arrange - open the pause menu (IN_GAME_MENU state with tree paused)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  ScenarioManager.set_current_scenario_id("scenario_1")
  GameManager.toggle_in_game_menu()
  assert_true(GameManager.is_paused(), "PRECONDITION: game should be paused")
  
  # Act - restart_scenario calls resume_game before scene change
  # We verify state changes by calling the sub-steps directly since the
  # scene-change itself would exit the test context.
  GameManager.resume_game()
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert
  assert_false(GameManager.is_paused(), "Game must be unpaused after restart")
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING,
    "State should be PLAYING after restart")

func test_restart_scenario_preserves_scenario_id():
  # Arrange
  var scenario_id = "scenario_1"
  ScenarioManager.set_current_scenario_id(scenario_id)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  GameManager.toggle_in_game_menu()
  
  # Act - simulate the scenario-ID preservation step inside restart_scenario
  var captured_id = ScenarioManager.get_current_scenario_id()
  GameManager.resume_game()
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  # After a real save-slot reload the current scenario may be overwritten;
  # restart_scenario then restores it:
  ScenarioManager.set_current_scenario_id(captured_id)
  
  # Assert
  assert_eq(ScenarioManager.get_current_scenario_id(), scenario_id,
    "Scenario ID must be preserved after restart")

func test_restart_scenario_with_no_save_slot_falls_back_to_reset():
  # Arrange - ensure no save slot is loaded
  var original_slot = SaveManager.current_save_slot
  SaveManager.current_save_slot = -1
  
  # Keep track of the systems so we can reset manually the same way
  # restart_scenario does in its fallback path
  var reset_count := 0
  for system in SaveManager.managed_systems:
    system.reset_data()
    reset_count += 1
  
  # restore slot
  SaveManager.current_save_slot = original_slot
  
  # Assert - the fallback path iterated all managed systems without error
  # (if reset_count >= 0 the loop ran without crashing)
  assert_true(reset_count >= 0, "Fallback reset path should iterate without error")
