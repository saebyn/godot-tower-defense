extends Node3D
class_name Wave

## A wave definition node that specifies enemies to spawn during a wave period
## Used as child nodes of EnemySpawner to define wave-based enemy spawning

@export_group("Wave Timing")
@export var duration: float = 10.0 ## Duration of the wave in seconds
@export var start_delay: float = 0.0 ## Optional delay before wave starts in seconds

@export_group("Enemy Configuration")
@export var enemy_scenes: Array[PackedScene] = [] ## Enemy types to spawn in this wave
@export var enemy_counts: Array[int] = [] ## Number of each enemy type to spawn
@export var spawn_interval: float = 2.0 ## Time between individual enemy spawns in seconds

## Internal state
var _is_active: bool = false
var _is_completed: bool = false
var _enemies_to_spawn: Array[Dictionary] = [] ## Queue of enemies to spawn
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
  if enemy_scenes.size() != enemy_counts.size():
    push_error("Wave: enemy_scenes and enemy_counts arrays must have the same size")
    return
  
  if enemy_scenes.is_empty():
    push_warning("Wave: No enemy scenes configured for wave")
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
  for i in range(enemy_scenes.size()):
    var scene = enemy_scenes[i]
    var count = enemy_counts[i]
    
    for j in range(count):
      _enemies_to_spawn.append({
        "scene": scene,
        "index": i
      })
  
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
  
  var enemy_data = _enemies_to_spawn.pop_front()
  var enemy_scene = enemy_data.scene as PackedScene
  
  if not enemy_scene:
    push_error("Wave: Invalid enemy scene in spawn queue")
    return
  
  # Let the parent spawner handle the actual instantiation and positioning
  var spawner = get_parent() as EnemySpawner
  if spawner:
    var enemy = enemy_scene.instantiate()
    spawner.spawn_enemy_at_position(enemy, spawner.find_random_spawn_position())
    enemy_spawned.emit(enemy, self)

func _end_wave() -> void:
  if not _is_active:
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