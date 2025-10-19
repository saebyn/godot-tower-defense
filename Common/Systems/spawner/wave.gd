extends Node3D
class_name Wave

## A wave definition node that specifies enemies to spawn during a wave period
## Used as child nodes of EnemySpawner to define wave-based enemy spawning

@export_group("Wave Timing")
@export var duration: float = 10.0 ## Duration of the wave in seconds
@export var start_delay: float = 0.0 ## Optional delay before wave starts in seconds
@export var max_enemies: int = 10 ## Maximum number of enemies allowed at once from this wave
@export var allow_overlap: bool = false ## If true, allows this wave to overlap with the next wave

@export_group("Enemy Configuration")
@export var enemy_types: Array[EnemyTypeResource] = [] ## Enemy types to spawn in this wave
@export var enemy_counts: Array[int] = [] ## Number of each enemy type to spawn
@export var spawn_interval: float = 2.0 ## Time between individual enemy spawns in seconds

## Configuration
const WAVE_OVERLAP_RECHECK_TIME: float = 1.0 ## Time to wait before rechecking for overlap completion

## Internal state
var _is_active: bool = false
var _is_completed: bool = false
var _enemies_to_spawn: Array[EnemyTypeResource] = [] ## Queue of enemies to spawn
var _spawn_timer: Timer
var _wave_timer: Timer

## Signals
signal wave_started(wave: Wave)
signal wave_completed(wave: Wave)
signal enemy_spawned(enemy: Node3D, wave: Wave)

func _ready() -> void:
  # Create and configure timers
  _spawn_timer = Timer.new()
  _spawn_timer.wait_time = spawn_interval
  _spawn_timer.timeout.connect(_spawn_next_enemy)
  add_child(_spawn_timer)
  
  _wave_timer = Timer.new()
  _wave_timer.one_shot = true
  _wave_timer.timeout.connect(_end_wave)
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

func start_wave() -> void:
  if _is_active or _is_completed:
    return
  
  # Wait for start delay if configured
  if start_delay > 0.0:
    await get_tree().create_timer(start_delay).timeout
  
  _is_active = true
  wave_started.emit(self)
  
  # Build spawn queue
  _build_spawn_queue()
  
  # Start wave duration timer
  _wave_timer.wait_time = duration
  _wave_timer.start()
  
  # Start spawning enemies
  if not _enemies_to_spawn.is_empty():
    _spawn_timer.start()

func _build_spawn_queue() -> void:
  _enemies_to_spawn.clear()
  
  # Add all enemies to the spawn queue
  for i in range(enemy_types.size()):
    var enemy_type = enemy_types[i]
    var count = enemy_counts[i]
    
    for j in range(count):
      _enemies_to_spawn.append(enemy_type)
  
  # Shuffle the spawn queue for variety (optional)
  _enemies_to_spawn.shuffle()

func _spawn_next_enemy() -> void:
  if _enemies_to_spawn.is_empty() or not _is_active:
    _spawn_timer.stop()
    # Check if all enemies are spawned and end wave early if needed
    if _enemies_to_spawn.is_empty() and _is_active:
      # All enemies spawned before duration expired
      _end_wave()
    return

  if get_parent().get_spawned_enemy_count() >= max_enemies:
    Logger.debug("Spawner.Wave", "Max enemies reached, cannot spawn more right now")
    return

  var enemy_type := _enemies_to_spawn.pop_front() as EnemyTypeResource
  

  # Let the parent spawner handle the actual instantiation and positioning
  var spawner = get_parent() as EnemySpawner
  if spawner:
    var enemy := spawner.spawn_enemy(enemy_type)
    enemy_spawned.emit(enemy, self)

func _end_wave() -> void:
  if not _is_active:
    return

  if not allow_overlap and get_parent().get_spawned_enemy_count() > 0:
    Logger.debug("Spawner.Wave", "Waiting for all spawned enemies to be cleared before completing wave")
    # Wait until all spawned enemies are gone before completing the wave
    _wave_timer.start(WAVE_OVERLAP_RECHECK_TIME)
    return

  _is_active = false
  _is_completed = true
  _spawn_timer.stop()
  
  wave_completed.emit(self)

func is_active() -> bool:
  return _is_active

func is_completed() -> bool:
  return _is_completed

func get_remaining_enemies() -> int:
  return _enemies_to_spawn.size()