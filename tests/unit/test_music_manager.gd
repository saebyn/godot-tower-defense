extends GutTest

## Unit tests for MusicManager functionality
## Tests music pause/resume logic based on game state and settings

var music_manager: Node
var mock_music_player: AudioStreamPlayer

func before_each():
  # Get reference to the MusicManager autoload
  music_manager = MusicManager
  
  # Create a mock AudioStreamPlayer
  mock_music_player = AudioStreamPlayer.new()
  add_child(mock_music_player)
  
  # Set up the music player in MusicManager
  music_manager.set_music_player(mock_music_player)
  
  # Reset game state
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Ensure music is not paused initially
  mock_music_player.stream_paused = false
  
  # Set default setting
  SettingsManager.pause_music_on_pause = true

func after_each():
  # Clean up
  if mock_music_player:
    mock_music_player.queue_free()
  
  # Reset state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  SettingsManager.pause_music_on_pause = true

func test_music_pauses_when_game_enters_in_game_menu_with_setting_enabled():
  # Arrange
  SettingsManager.pause_music_on_pause = true
  mock_music_player.stream_paused = false
  
  # Act
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  
  # Assert
  assert_true(mock_music_player.stream_paused, "Music should be paused when entering IN_GAME_MENU with setting enabled")

func test_music_does_not_pause_when_game_enters_in_game_menu_with_setting_disabled():
  # Arrange
  SettingsManager.pause_music_on_pause = false
  mock_music_player.stream_paused = false
  
  # Act
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  
  # Assert
  assert_false(mock_music_player.stream_paused, "Music should not be paused when entering IN_GAME_MENU with setting disabled")

func test_music_resumes_when_returning_to_playing_state():
  # Arrange
  SettingsManager.pause_music_on_pause = true
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  assert_true(mock_music_player.stream_paused, "Music should be paused in IN_GAME_MENU")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert
  assert_false(mock_music_player.stream_paused, "Music should resume when returning to PLAYING state")

func test_music_manager_handles_no_music_player_gracefully():
  # Arrange
  music_manager.set_music_player(null)
  
  # Act - should not crash
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert - test passes if no crash occurred
  assert_true(true, "MusicManager should handle null music player gracefully")

func test_music_manager_only_affects_stream_paused_property():
  # Arrange
  SettingsManager.pause_music_on_pause = true
  mock_music_player.stream_paused = false
  var initial_volume = mock_music_player.volume_db
  
  # Act
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  
  # Assert
  assert_true(mock_music_player.stream_paused, "stream_paused should be true")
  assert_eq(mock_music_player.volume_db, initial_volume, "Volume should not change when pausing")

func test_setting_music_player_multiple_times():
  # Arrange
  var second_player = AudioStreamPlayer.new()
  add_child(second_player)
  
  # Act
  music_manager.set_music_player(second_player)
  SettingsManager.pause_music_on_pause = true
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  
  # Assert
  assert_true(second_player.stream_paused, "Second player should be controlled after being set")
  assert_false(mock_music_player.stream_paused, "First player should not be affected")
  
  # Cleanup
  second_player.queue_free()

func test_music_does_not_resume_if_already_paused_before_game_pause():
  # Arrange - Music is already paused for some other reason
  SettingsManager.pause_music_on_pause = true
  mock_music_player.stream_paused = true
  
  # Act - Enter and exit IN_GAME_MENU
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Assert - Music should still be paused (we didn't pause it, so we shouldn't resume it)
  assert_true(mock_music_player.stream_paused, "Music should remain paused if it was paused before entering IN_GAME_MENU")
