extends Node3D
class_name EnemySpawner

@export var spawn_area: MeshInstance3D
@export var spawn_interval: float = 2.0 # Time between spawns in seconds
@export var enemy_scene: PackedScene
@export var max_enemies: int = 10 # Maximum number of enemies allowed at once

@onready var timer = $Timer
var current_enemies: Array[Node3D] = []

func _ready() -> void:
    timer.wait_time = spawn_interval
    timer.start()

func _on_Timer_timeout() -> void:
    if current_enemies.size() < max_enemies:
        var enemy = enemy_scene.instantiate()
        enemy.global_position = find_random_spawn_position()
        add_child(enemy)
        current_enemies.append(enemy)


func _on_child_exiting_tree(node: Node) -> void:
    if node in current_enemies:
        current_enemies.erase(node)


func find_random_spawn_position() -> Vector3:
    # Generate a random position within the spawn area
    var bounds = spawn_area.get_aabb()
    var random_position = Vector3(
        randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
        randf_range(bounds.position.y, bounds.position.y + bounds.size.y),
        randf_range(bounds.position.z, bounds.position.z + bounds.size.z)
    )
    return random_position