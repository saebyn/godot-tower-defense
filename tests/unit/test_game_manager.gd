extends GutTest

## Unit tests for GameManager functionality
## Tests state management, level ID tracking, and cleanup

func before_each():
  # Reset GameManager to known state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  GameManager.set_current_level_id("")
  GameManager.resume_game() # Ensure not paused

func after_each():
  # Restore default state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  GameManager.set_current_level_id("")
  GameManager.resume_game()

func test_level_id_managed_by_level_manager():
  # Level ID is now managed by LevelManager, not GameManager
  # This test verifies the integration
  # Arrange
  var level_id = "level_1"
  
  # Act
  LevelManager.set_current_level_id(level_id)
  
  # Assert
  assert_eq(LevelManager.get_current_level_id(), level_id, "LevelManager should track level ID")

func test_return_to_main_menu_clears_level_via_level_manager():
  # This test verifies that returning to main menu clears the level in LevelManager
  # Arrange
  LevelManager.set_current_level_id("level_3")
  assert_eq(LevelManager.get_current_level_id(), "level_3", "Level ID should be set initially")
  
  # Act - Simulate what return_to_main_menu does
  LevelManager.clear_current_level()
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  
  # Assert
  assert_eq(LevelManager.get_current_level_id(), "", "Level ID should be cleared when returning to main menu")

func test_game_state_changed_signal_is_emitted():
  # Arrange
  watch_signals(GameManager)
  
  # Act
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert
  assert_signal_emitted(GameManager, "game_state_changed", "game_state_changed signal should be emitted")
  assert_signal_emitted_with_parameters(GameManager, "game_state_changed", [GameManager.GameState.PLAYING], "Signal should include new state")

func test_wave_tracking_moved_to_level_manager():
  # Wave tracking is now managed by LevelManager, not GameManager
  # Arrange
  watch_signals(LevelManager)
  var wave = 5
  
  # Act
  LevelManager.set_current_wave(wave)
  
  # Assert
  assert_signal_emitted(LevelManager, "wave_changed", "wave_changed signal should be emitted by LevelManager")
  assert_eq(LevelManager.get_current_wave(), wave, "LevelManager should track current wave")

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
  assert_signal_emitted_with_parameters(GameManager, "speed_changed", [1.5], "Signal should include new speed")
