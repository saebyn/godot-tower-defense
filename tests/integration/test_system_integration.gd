extends GutTest

## Example integration test
## Integration tests verify that multiple components work together correctly
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
