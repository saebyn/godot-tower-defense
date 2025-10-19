extends Node3D
class_name EnemySpawner

@export var spawn_area: MeshInstance3D

var _spawned_enemies: int = 0

var current_enemies: Array[Node3D] = []

# Wave system
var _waves: Array[Wave] = []
var _current_wave_index: int = 0

# Signals for wave system
signal wave_started(wave: Wave)
signal wave_completed(wave: Wave)
signal all_waves_completed()
signal enemy_spawned(enemy: Node3D)

func _ready() -> void:
    # Defer mode detection to ensure all children are ready
    _detect_mode.call_deferred()

func _detect_mode() -> void:
    # Check for Wave child nodes
    _waves.clear() # Clear in case of multiple calls
    for child in get_children():
        if child is Wave:
            _waves.append(child)
    
    Logger.info("Spawner", "Using wave mode with %d waves" % _waves.size())
    _setup_wave_mode()

func _setup_wave_mode() -> void:
    # Connect wave signals
    for wave in _waves:
        wave.wave_started.connect(_on_wave_started)
        wave.wave_completed.connect(_on_wave_completed)
        wave.enemy_spawned.connect(_on_enemy_spawned_from_wave)
    
    # Start the first wave
    if not _waves.is_empty():
        _start_next_wave()

func _start_next_wave() -> void:
    if _current_wave_index >= _waves.size():
        all_waves_completed.emit()
        Logger.info("Spawner", "All waves completed")
        return
    
    var wave = _waves[_current_wave_index]
    Logger.info("Spawner", "Starting wave %d" % (_current_wave_index + 1))
    wave.start_wave()

func _on_wave_started(wave: Wave) -> void:
    wave_started.emit(wave)

func _on_wave_completed(wave: Wave) -> void:
    wave_completed.emit(wave)
    _current_wave_index += 1
    
    # Start next wave after a brief delay
    await get_tree().create_timer(1.0).timeout
    _start_next_wave()

func _on_enemy_spawned_from_wave(enemy: Node3D, _wave: Wave) -> void:
    enemy_spawned.emit(enemy)


func spawn_enemy(enemy_type: EnemyTypeResource) -> Node3D:
    var enemy = enemy_type.scene.instantiate()
    enemy.load_resource(enemy_type)

    enemy.global_position = find_random_spawn_position()
    add_child(enemy)
    current_enemies.append(enemy)
    _spawned_enemies += 1
    enemy_spawned.emit(enemy)
    return enemy


func get_spawned_enemy_count() -> int:
    return _spawned_enemies


func _on_child_exiting_tree(node: Node) -> void:
    if node in current_enemies:
        Logger.debug("Spawner", "Enemy exited tree")
        current_enemies.erase(node)
        _spawned_enemies -= 1


func find_random_spawn_position() -> Vector3:
    # Generate a random position within the spawn area
    var bounds = spawn_area.get_aabb()
    var random_position = Vector3(
        randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
        randf_range(bounds.position.y, bounds.position.y + bounds.size.y),
        randf_range(bounds.position.z, bounds.position.z + bounds.size.z)
    )
    return random_position

func get_current_wave_number() -> int:
    return _current_wave_index + 1

func get_total_waves() -> int:
    return _waves.size()
