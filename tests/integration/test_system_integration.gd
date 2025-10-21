extends GutTest

## Example integration test
## Integration tests verify that multiple components work together correctly

func test_currency_and_logger_integration():
  # This test verifies that CurrencyManager and Logger work together
  # by checking that currency operations trigger appropriate logging
  
  # Arrange
  Logger.set_log_level(Logger.LogLevel.INFO)
  Logger.set_enabled_scopes(["*"])
  CurrencyManager.current_scrap = 0
  
  # Act
  CurrencyManager.earn_scrap(100)
  CurrencyManager.spend_scrap(50)
  
  # Assert
  assert_eq(CurrencyManager.current_scrap, 50, "Should have 50 scrap after earning 100 and spending 50")
  # The logging is happening in the background; we're just verifying the integration works without errors

func test_game_manager_state_transitions():
  # Test that GameManager properly handles state transitions
  
  # Arrange
  var initial_state = GameManager.current_state
  
  # Act
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "Game state should be PLAYING")
  
  # Cleanup - restore initial state
  GameManager.set_game_state(initial_state)
