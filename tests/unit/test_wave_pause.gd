extends GutTest

## Unit tests for System_Wave pause behavior
## Tests that wave timers respect game pause state

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
  
  # Ensure game is not paused initially
  get_tree().paused = false

func after_each():
  # Clean up - ensure game is not paused
  get_tree().paused = false

## Timer Process Mode Tests

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

## Functional Pause Behavior Tests

func test_wave_timer_stops_during_pause():
  # Arrange
  var initial_time_left: float
  wave_instance.start_wave()
  await wait_frames(2) # Wait for wave to start
  
  # Record initial time left on wave timer
  initial_time_left = wave_instance._wave_timer.time_left
  assert_gt(initial_time_left, 0.0, "Wave timer should be running")
  
  # Act - Pause the game
  get_tree().paused = true
  await wait_seconds(0.5) # Wait while paused
  
  # Assert - Timer should not have progressed
  var time_left_after_pause = wave_instance._wave_timer.time_left
  assert_almost_eq(time_left_after_pause, initial_time_left, 0.1,
    "Wave timer should not progress while paused")

func test_spawn_timer_stops_during_pause():
  # Arrange - Create a simple enemy type for spawning
  var enemy_type = Resource_EnemyType.new()
  enemy_type.scene = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  wave_instance.enemy_types = [enemy_type]
  wave_instance.enemy_counts = [5]
  
  wave_instance.start_wave()
  await wait_frames(2) # Wait for wave to start
  
  # Record initial time left on spawn timer
  var initial_time_left = wave_instance._spawn_timer.time_left
  assert_gt(initial_time_left, 0.0, "Spawn timer should be running")
  
  # Act - Pause the game
  get_tree().paused = true
  await wait_seconds(0.5) # Wait while paused
  
  # Assert - Timer should not have progressed
  var time_left_after_pause = wave_instance._spawn_timer.time_left
  assert_almost_eq(time_left_after_pause, initial_time_left, 0.1,
    "Spawn timer should not progress while paused")

func test_timers_resume_after_unpause():
  # Arrange - Create a simple enemy type for spawning
  var enemy_type = Resource_EnemyType.new()
  enemy_type.scene = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  wave_instance.enemy_types = [enemy_type]
  wave_instance.enemy_counts = [5]
  
  wave_instance.start_wave()
  await wait_frames(2) # Wait for wave to start
  
  var initial_wave_time = wave_instance._wave_timer.time_left
  var initial_spawn_time = wave_instance._spawn_timer.time_left
  
  # Act - Pause then unpause
  get_tree().paused = true
  await wait_seconds(0.5)
  get_tree().paused = false
  await wait_seconds(0.5)
  
  # Assert - Timers should have progressed after unpause
  var final_wave_time = wave_instance._wave_timer.time_left
  var final_spawn_time = wave_instance._spawn_timer.time_left
  
  assert_lt(final_wave_time, initial_wave_time,
    "Wave timer should progress after unpause")
  assert_lt(final_spawn_time, initial_spawn_time,
    "Spawn timer should progress after unpause")

func test_spawn_callbacks_dont_fire_during_pause():
  # Arrange - Create enemy type
  var enemy_type = Resource_EnemyType.new()
  enemy_type.scene = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  wave_instance.enemy_types = [enemy_type]
  wave_instance.enemy_counts = [10]
  wave_instance.spawn_interval = 0.1 # Fast spawning for test
  
  # Watch for enemy spawns
  watch_signals(wave_instance)
  
  # Start wave
  wave_instance.start_wave()
  await wait_frames(2)
  
  # Clear any spawns that happened during start
  var initial_spawn_count = get_signal_emit_count(wave_instance, "enemy_spawned")
  
  # Act - Pause and wait
  get_tree().paused = true
  await wait_seconds(1.0) # Long enough for multiple spawns if not paused
  
  # Assert - No new spawns should occur during pause
  var spawn_count_during_pause = get_signal_emit_count(wave_instance, "enemy_spawned")
  assert_eq(spawn_count_during_pause, initial_spawn_count,
    "No enemy_spawned signals should fire during pause")
  
  # Cleanup
  get_tree().paused = false
