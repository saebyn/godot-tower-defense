extends GutTest

## Unit tests for System_Wave pause behavior
## Tests that wave timers respect pause state by verifying both configuration
## and actual pause behavior using controllable test nodes.

# Test configuration constants
const PAUSE_WAIT_FRAMES = 20  # Frames to wait during pause to verify timers don't progress
const UNPAUSE_WAIT_FRAMES = 10  # Frames to wait after unpause to verify timers resume
const SPAWN_TEST_WAIT_FRAMES = 60  # Frames to wait during pause spawn test (~1 sec @ 60fps)

# Mock spawner that tracks spawn calls
class MockEnemySpawner extends System_EnemySpawner:
  var spawn_calls: int = 0
  
  func spawn_enemy(enemy_type: Resource_EnemyType) -> Node3D:
    spawn_calls += 1
    var enemy = Node3D.new()
    enemy.set_meta("enemy_type", enemy_type)
    return enemy
  
  func get_spawned_enemy_count() -> int:
    return 0
  
  # Override to prevent actual spawner logic
  func _ready() -> void:
    pass

var wave_instance: System_Wave
var spawner_instance: MockEnemySpawner

func before_each():
  # Create a mock spawner to act as parent
  spawner_instance = MockEnemySpawner.new()
  add_child_autofree(spawner_instance)
  
  # Create a wave instance as child of spawner
  wave_instance = System_Wave.new()
  wave_instance.duration = 10.0
  wave_instance.spawn_interval = 0.5
  wave_instance.start_delay = 0.0
  spawner_instance.add_child(wave_instance)

func after_each():
  # Ensure game is not paused after tests
  get_tree().paused = false

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

## Timer and Spawn Behavior Tests
## These tests verify actual pause behavior by checking timer state and spawn activity

func test_timers_pause_when_tree_paused():
  # Arrange - Create a simple enemy type
  var enemy_type = Resource_EnemyType.new()
  enemy_type.scene = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  wave_instance.enemy_types = [enemy_type]
  wave_instance.enemy_counts = [5]
  
  # Start wave and wait for timers to begin
  wave_instance.start_wave()
  await wait_frames(2)
  
  # Record initial timer states
  var initial_wave_time = wave_instance._wave_timer.time_left
  var initial_spawn_time = wave_instance._spawn_timer.time_left
  assert_gt(initial_wave_time, 0.0, "Wave timer should be running")
  assert_gt(initial_spawn_time, 0.0, "Spawn timer should be running")
  
  # Act - Pause the scene tree
  get_tree().paused = true
  # Wait several frames with GUT's process continuing (GUT has ignore_pause=true)
  for i in range(PAUSE_WAIT_FRAMES):
    await wait_frames(1)
  
  # Assert - Timer values should not have changed while paused
  var paused_wave_time = wave_instance._wave_timer.time_left
  var paused_spawn_time = wave_instance._spawn_timer.time_left
  assert_almost_eq(paused_wave_time, initial_wave_time, 0.1,
    "Wave timer should not progress while paused")
  assert_almost_eq(paused_spawn_time, initial_spawn_time, 0.1,
    "Spawn timer should not progress while paused")
  
  # Cleanup
  get_tree().paused = false

func test_timers_resume_after_unpause():
  # Arrange - Create a simple enemy type
  var enemy_type = Resource_EnemyType.new()
  enemy_type.scene = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  wave_instance.enemy_types = [enemy_type]
  wave_instance.enemy_counts = [5]
  
  # Start wave
  wave_instance.start_wave()
  await wait_frames(2)
  
  var initial_wave_time = wave_instance._wave_timer.time_left
  var initial_spawn_time = wave_instance._spawn_timer.time_left
  
  # Act - Pause then unpause
  get_tree().paused = true
  for i in range(UNPAUSE_WAIT_FRAMES):
    await wait_frames(1)
  get_tree().paused = false
  for i in range(UNPAUSE_WAIT_FRAMES):
    await wait_frames(1)
  
  # Assert - Timers should have progressed after unpause
  var final_wave_time = wave_instance._wave_timer.time_left
  var final_spawn_time = wave_instance._spawn_timer.time_left
  
  assert_lt(final_wave_time, initial_wave_time,
    "Wave timer should progress after unpause")
  assert_lt(final_spawn_time, initial_spawn_time,
    "Spawn timer should progress after unpause")

func test_spawn_callbacks_dont_fire_during_pause():
  # Arrange - Create enemy type with fast spawning
  var enemy_type = Resource_EnemyType.new()
  enemy_type.scene = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  wave_instance.enemy_types = [enemy_type]
  wave_instance.enemy_counts = [10]
  # Set fast spawn interval before starting wave
  wave_instance.spawn_interval = 0.1
  wave_instance._spawn_timer.wait_time = 0.1
  
  # Start wave
  wave_instance.start_wave()
  await wait_frames(2)
  
  # Record initial spawn count
  var initial_spawns = spawner_instance.spawn_calls
  
  # Act - Pause and wait long enough for multiple spawns if not paused
  get_tree().paused = true
  # Wait multiple frames (would allow many spawns if not paused)
  for i in range(SPAWN_TEST_WAIT_FRAMES):
    await wait_frames(1)
  
  # Assert - No new spawns should have occurred
  var spawns_during_pause = spawner_instance.spawn_calls
  assert_eq(spawns_during_pause, initial_spawns,
    "No spawns should occur while paused")
  
  # Cleanup
  get_tree().paused = false
