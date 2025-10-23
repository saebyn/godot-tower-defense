extends GutTest

## Unit tests for Level timer functionality
## Tests accurate time tracking, pause handling, and integration with level completion

# Mock EnemySpawner for testing
class MockEnemySpawner extends EnemySpawner:
  var _mock_wave_number: int = 1
  
  func get_current_wave_number() -> int:
    return _mock_wave_number
  
  # Override to prevent actual spawner logic
  func _ready() -> void:
    pass

# Test-specific Level class that allows controlling pause state  
class TestLevel extends Level:
  var _test_is_paused: bool = false
  
  func _is_paused() -> bool:
    return _test_is_paused
  
  func set_test_paused(paused: bool) -> void:
    _test_is_paused = paused

var level_instance: TestLevel
var mock_spawner: MockEnemySpawner

func before_each():
  # Create a test Level instance with controllable pause state
  level_instance = TestLevel.new()
  
  # Add a mock enemy spawner
  mock_spawner = MockEnemySpawner.new()
  level_instance.enemy_spawner = mock_spawner
  
  add_child_autofree(level_instance)
  level_instance._ready()
  
  # Set up the level
  LevelManager.set_current_level_id("level_1")
  GameManager.set_game_state(GameManager.GameState.PLAYING)

func after_each():
  LevelManager.clear_current_level()
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)

## Basic Timer Functionality Tests

func test_timer_starts_at_zero():
  # Assert
  assert_eq(level_instance.level_elapsed_time, 0.0, "Timer should start at 0")
  assert_false(level_instance.is_timing, "Timer should not be running initially")
  assert_false(level_instance.timer_started, "Timer should not have started yet")

func test_timer_starts_on_first_wave():
  # Arrange
  assert_false(level_instance.timer_started, "Timer not started initially")
  
  # Act - Simulate first wave starting
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  
  # Assert
  assert_true(level_instance.timer_started, "Timer should be started after first wave")
  assert_true(level_instance.is_timing, "Timer should be running")
  assert_eq(level_instance.level_elapsed_time, 0.0, "Elapsed time should start at 0")

func test_timer_accumulates_time():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  
  # Act - Simulate time passing via _process
  level_instance._process(1.0) # 1 second
  level_instance._process(0.5) # 0.5 seconds
  level_instance._process(0.5) # 0.5 seconds
  
  # Assert
  assert_almost_eq(level_instance.level_elapsed_time, 2.0, 0.01, "Timer should accumulate 2 seconds")
  assert_true(level_instance.is_timing, "Timer should still be running")

func test_timer_stops_on_level_completion():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  level_instance._process(5.0) # Simulate 5 seconds passing
  
  # Act
  var elapsed = level_instance._stop_timer()
  
  # Assert
  assert_almost_eq(elapsed, 5.0, 0.01, "Should return elapsed time")
  assert_false(level_instance.is_timing, "Timer should be stopped")
  assert_almost_eq(level_instance.level_elapsed_time, 5.0, 0.01, "Elapsed time should be preserved")

func test_timer_doesnt_accumulate_when_stopped():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  level_instance._process(3.0)
  level_instance._stop_timer()
  
  # Act - Process more time after stopping
  level_instance._process(10.0)
  
  # Assert
  assert_almost_eq(level_instance.level_elapsed_time, 3.0, 0.01, "Time should not accumulate after stopping")

## Pause Handling Tests

func test_timer_pauses_when_game_paused():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  level_instance._process(2.0) # 2 seconds
  
  # Act - Pause the game using test control
  level_instance.set_test_paused(true)
  level_instance._process(5.0) # This time should NOT count
  
  # Assert
  assert_almost_eq(level_instance.level_elapsed_time, 2.0, 0.01, "Time should not accumulate while paused")
  assert_true(level_instance.is_timing, "Timer should still be marked as 'timing'")

func test_timer_resumes_when_game_unpaused():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  level_instance._process(2.0)
  
  # Act - Pause using test control
  level_instance.set_test_paused(true)
  level_instance._process(5.0) # Should not accumulate
  
  # Resume
  level_instance.set_test_paused(false)
  level_instance._process(3.0) # Should accumulate
  
  # Assert
  assert_almost_eq(level_instance.level_elapsed_time, 5.0, 0.01, "Should accumulate 2 + 3 seconds (not the paused 5)")

func test_timer_handles_multiple_pause_resume_cycles():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  
  # Act - Use test pause control for multiple pause/resume cycles
  level_instance._process(1.0) # +1 = 1
  level_instance.set_test_paused(true)
  level_instance._process(10.0) # Ignored
  level_instance.set_test_paused(false)
  level_instance._process(2.0) # +2 = 3
  level_instance.set_test_paused(true)
  level_instance._process(20.0) # Ignored
  level_instance.set_test_paused(false)
  level_instance._process(1.5) # +1.5 = 4.5
  
  # Assert
  assert_almost_eq(level_instance.level_elapsed_time, 4.5, 0.01, "Should only count time when not paused")

## Integration Tests

func test_get_elapsed_time_returns_current_time():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  level_instance._process(7.3)
  
  # Act
  var elapsed = level_instance.get_elapsed_time()
  
  # Assert
  assert_almost_eq(elapsed, 7.3, 0.01, "Should return current elapsed time")
  assert_true(level_instance.is_timing, "Timer should still be running")

func test_timer_only_starts_once():
  # Arrange
  var mock_wave = Wave.new()
  
  # Act - Try to start timer multiple times
  level_instance._on_wave_started(mock_wave)
  level_instance._process(2.0)
  level_instance._on_wave_started(mock_wave) # Second wave
  level_instance._process(1.0)
  level_instance._on_wave_started(mock_wave) # Third wave
  level_instance._process(1.0)
  
  # Assert
  assert_almost_eq(level_instance.level_elapsed_time, 4.0, 0.01, "Should accumulate all time from first start")

func test_timer_stops_on_game_over():
  # Arrange
  var mock_wave = Wave.new()
  level_instance._on_wave_started(mock_wave)
  level_instance._process(3.0)
  
  # Act - Trigger game over
  level_instance.survivor_count = 1
  level_instance.on_target_died(null, "test")
  
  # Assert
  assert_false(level_instance.is_timing, "Timer should stop on game over")
  assert_almost_eq(level_instance.level_elapsed_time, 3.0, 0.01, "Time should be preserved")
