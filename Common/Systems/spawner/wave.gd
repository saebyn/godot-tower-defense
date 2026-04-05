extends Node3D
class_name System_Wave

## A wave definition node that specifies enemies to spawn during a wave period
## Used as child nodes of EnemySpawner to define wave-based enemy spawning

@export_group("Wave Timing")
@export var duration: float = 10.0 ## Duration of the wave in seconds
@export var start_delay: float = 0.0 ## Optional delay before wave starts in seconds
@export var allow_overlap: bool = false ## If true, allows this wave to overlap with the next wave

@export_group("Enemy Configuration")
@export var enemy_types: Array[Resource_EnemyType] = [] ## Enemy types to spawn in this wave
@export var enemy_counts: Array[int] = [] ## Number of each enemy type to spawn
@export var spawn_interval: float = 2.0 ## Time between individual enemy spawns (used to auto-generate a flat spawn_rate_curve when none is set)
@export var spawn_rate_curve: Curve ## Enemies per second over wave progress (X: 0→1, Y: enemies/sec). Auto-generated from spawn_interval if null.

## Configuration
const WAVE_OVERLAP_RECHECK_TIME: float = 1.0 ## Time to wait before rechecking for overlap completion

## Internal state
var _is_active: bool = false ## True when the wave is active (between start_wave() and wave completion)
var _is_completed: bool = false
## True while enemies are still being spawned; false once duration of wave ends
## This may be false while the wave is active if there are still enemies spawned
## after the duration has ended. This will prevent new enemies from spawning until
## the next wave starts when `allow_overlap` is false.
var _is_spawning_active: bool = false
var _enemies_to_spawn: Array[Resource_EnemyType] = [] ## Queue of enemies to spawn
var _spawn_accumulator: float = 0.0 ## Fractional enemy spawn debt
var _wave_elapsed: float = 0.0 ## Elapsed time since wave started
var _wave_timer: Timer ## When to end the wave

## Signals
signal wave_started(wave: System_Wave)
signal wave_completed(wave: System_Wave)
signal enemy_spawned(enemy: Node3D, wave: System_Wave)

func _ready() -> void:
  process_mode = Node.PROCESS_MODE_PAUSABLE

  # Auto-generate a flat curve from spawn_interval when no curve is provided
  if spawn_rate_curve == null:
    if spawn_interval <= 0.0:
      push_error("Wave: spawn_interval must be greater than 0; defaulting to 1.0 second")
      spawn_interval = 1.0
    spawn_rate_curve = Curve.new()
    spawn_rate_curve.add_point(Vector2(0.0, 1.0 / spawn_interval))
    spawn_rate_curve.add_point(Vector2(1.0, 1.0 / spawn_interval))

  _wave_timer = Timer.new()
  _wave_timer.one_shot = true
  _wave_timer.timeout.connect(_end_wave)
  _wave_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
  add_child(_wave_timer)
  
  # Validate configuration
  _validate_configuration()

func _validate_configuration() -> void:
  if enemy_types.size() != enemy_counts.size():
    push_error("Wave: enemy_types and enemy_counts arrays must have the same size")
    return
  
  if enemy_types.is_empty():
    push_warning("Wave: No enemy types configured for wave")
    return

func _process(delta: float) -> void:
  if not _is_active:
    return

  _wave_elapsed += delta

  if not _is_spawning_active or _enemies_to_spawn.is_empty():
    return

  var progress: float
  if duration <= 0.0:
    progress = 1.0
  else:
    progress = clampf(_wave_elapsed / duration, 0.0, 1.0)
  var rate := maxf(0.0, spawn_rate_curve.sample(progress)) # enemies per second; clamped so negative curve values don't drain the accumulator

  _spawn_accumulator += rate * delta

  while _spawn_accumulator >= 1.0 and not _enemies_to_spawn.is_empty():
    _spawn_accumulator -= 1.0
    _do_spawn_one_enemy()


func start_wave() -> void:
  if _is_active or _is_completed:
    return
  
  # Wait for start delay if configured
  if start_delay > 0.0:
    await get_tree().create_timer(start_delay, false).timeout
  
  _is_active = true
  _is_spawning_active = true
  _spawn_accumulator = 0.0
  _wave_elapsed = 0.0

  # Build spawn queue before emitting wave_started so listeners
  # see the correct get_remaining_enemies() count immediately.
  _build_spawn_queue()
  wave_started.emit(self )
  
  # Start wave duration timer
  _wave_timer.wait_time = duration
  _wave_timer.start()

func _build_spawn_queue() -> void:
  _enemies_to_spawn.clear()
  
  # Add all enemies to the spawn queue
  for i in range(enemy_types.size()):
    var enemy_type = enemy_types[i]
    var count = enemy_counts[i]
    
    for j in range(count):
      _enemies_to_spawn.append(enemy_type)
  
  # Shuffle the spawn queue for variety
  _enemies_to_spawn.shuffle()

func _do_spawn_one_enemy() -> void:
  if _enemies_to_spawn.is_empty() or not _is_active:
    return

  var enemy_type := _enemies_to_spawn.pop_front() as Resource_EnemyType

  # Let the parent spawner handle the actual instantiation and positioning
  var spawner := get_parent() as System_EnemySpawner
  if spawner:
    var enemy = spawner.spawn_enemy(enemy_type)
    if enemy:
      enemy_spawned.emit(enemy, self )

func _end_wave() -> void:
  if not _is_active:
    return

  # Stop spawning immediately — duration is a hard cutoff regardless of overlap state
  _is_spawning_active = false

  if not allow_overlap and get_parent().get_spawned_enemy_count() > 0:
    MyLogger.debug("Spawner.Wave", "Waiting for all spawned enemies to be cleared before completing wave")
    # Wait until all spawned enemies are gone before completing the wave
    _wave_timer.start(WAVE_OVERLAP_RECHECK_TIME)
    return

  _is_active = false
  _is_completed = true
  
  wave_completed.emit(self )

func is_active() -> bool:
  return _is_active

func is_completed() -> bool:
  return _is_completed

func get_remaining_enemies() -> int:
  return _enemies_to_spawn.size()
