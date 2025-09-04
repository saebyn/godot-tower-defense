extends Node3D
class_name EnemySpawner

@export var spawn_area: MeshInstance3D
@export var spawn_interval: float = 2.0 # Time between spawns in seconds (legacy mode)
@export var enemy_scene: PackedScene # Legacy single enemy scene
@export var max_enemies: int = 10 # Maximum number of enemies allowed at once

var _spawned_enemies: int = 0

@onready var timer = $Timer
var current_enemies: Array[Node3D] = []

# Wave system
var _waves: Array[Wave] = []
var _current_wave_index: int = 0
var _is_wave_mode: bool = false

# Signals for wave system
signal wave_started(wave: Wave)
signal wave_completed(wave: Wave)
signal all_waves_completed()
signal enemy_spawned(enemy: Node3D)

func _ready() -> void:
    # Detect if we have Wave children (wave mode) or use legacy mode
    _detect_mode()
    
    if _is_wave_mode:
        _setup_wave_mode()
    else:
        _setup_legacy_mode()

func _detect_mode() -> void:
    # Check for Wave child nodes
    for child in get_children():
        if child is Wave:
            _waves.append(child)
    
    _is_wave_mode = not _waves.is_empty()
    
    if _is_wave_mode:
        print("EnemySpawner: Using wave mode with ", _waves.size(), " waves")
    else:
        print("EnemySpawner: Using legacy mode")

func _setup_wave_mode() -> void:
    # Connect wave signals
    for wave in _waves:
        wave.wave_started.connect(_on_wave_started)
        wave.wave_completed.connect(_on_wave_completed)
        wave.enemy_spawned.connect(_on_enemy_spawned_from_wave)
    
    # Start the first wave
    if not _waves.is_empty():
        _start_next_wave()

func _setup_legacy_mode() -> void:
    # Use the original timer-based system
    timer.wait_time = spawn_interval
    timer.start()

func _start_next_wave() -> void:
    if _current_wave_index >= _waves.size():
        all_waves_completed.emit()
        print("EnemySpawner: All waves completed")
        return
    
    var wave = _waves[_current_wave_index]
    print("EnemySpawner: Starting wave ", _current_wave_index + 1)
    wave.start_wave()

func _on_wave_started(wave: Wave) -> void:
    wave_started.emit(wave)

func _on_wave_completed(wave: Wave) -> void:
    wave_completed.emit(wave)
    _current_wave_index += 1
    
    # Start next wave after a brief delay
    await get_tree().create_timer(1.0).timeout
    _start_next_wave()

func _on_enemy_spawned_from_wave(enemy: Node3D, wave: Wave) -> void:
    enemy_spawned.emit(enemy)

func _on_Timer_timeout() -> void:
    # Legacy mode spawning
    if not _is_wave_mode and _spawned_enemies < max_enemies:
        var enemy = enemy_scene.instantiate()
        spawn_enemy_at_position(enemy, find_random_spawn_position())

# New method to handle enemy spawning (used by both legacy and wave modes)
func spawn_enemy_at_position(enemy: Node3D, position: Vector3) -> void:
    if _spawned_enemies >= max_enemies:
        enemy.queue_free()
        return
    
    enemy.global_position = position
    add_child(enemy)
    current_enemies.append(enemy)
    _spawned_enemies += 1
    enemy_spawned.emit(enemy)


func _on_child_exiting_tree(node: Node) -> void:
    if node in current_enemies:
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