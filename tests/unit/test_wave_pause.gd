extends GutTest

## Unit tests for System_Wave pause behavior
## Tests that wave timers have correct process_mode configuration
##
## Note: We only test process_mode configuration, not actual pause behavior.
## Pausing the scene tree in unit tests can cause GUT to hang since GUT itself
## runs with ignore_pause=true but nodes may not process correctly when paused.
## The process_mode configuration is what actually matters - Godot's engine
## will handle the pause behavior correctly at runtime.

var wave_instance: System_Wave
var spawner_instance: System_EnemySpawner

func before_each():
  # Create a spawner to act as parent
  spawner_instance = System_EnemySpawner.new()
  add_child_autofree(spawner_instance)
  
  # Create a wave instance as child of spawner
  wave_instance = System_Wave.new()
  wave_instance.duration = 10.0
  wave_instance.spawn_interval = 1.0
  wave_instance.start_delay = 0.0
  spawner_instance.add_child(wave_instance)

func after_each():
  # Clean up
  pass

## Timer Process Mode Configuration Tests
## These tests verify that timers are configured to respect pause state

func test_spawn_timer_is_pausable():
  # Assert
  assert_not_null(wave_instance._spawn_timer, "Spawn timer should exist after _ready")
  assert_eq(wave_instance._spawn_timer.process_mode, Node.PROCESS_MODE_PAUSABLE, 
    "Spawn timer should be set to PROCESS_MODE_PAUSABLE")

func test_wave_timer_is_pausable():
  # Assert
  assert_not_null(wave_instance._wave_timer, "Wave timer should exist after _ready")
  assert_eq(wave_instance._wave_timer.process_mode, Node.PROCESS_MODE_PAUSABLE,
    "Wave timer should be set to PROCESS_MODE_PAUSABLE")

func test_spawn_timer_properties():
  # Verify spawn timer is properly configured
  assert_not_null(wave_instance._spawn_timer, "Spawn timer should exist")
  assert_eq(wave_instance._spawn_timer.wait_time, wave_instance.spawn_interval,
    "Spawn timer wait_time should match spawn_interval")
  assert_false(wave_instance._spawn_timer.one_shot, "Spawn timer should not be one-shot")

func test_wave_timer_properties():
  # Verify wave timer is properly configured
  assert_not_null(wave_instance._wave_timer, "Wave timer should exist")
  assert_true(wave_instance._wave_timer.one_shot, "Wave timer should be one-shot")
