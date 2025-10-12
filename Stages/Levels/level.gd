class_name Level
extends Node3D

@export_category("References")
@export var enemy_spawner: EnemySpawner
@export var ui: Control

@export_category("Level Settings")
@export var survivor_count: int = 1


func _ready() -> void:
  enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
  enemy_spawner.wave_started.connect(_on_wave_started)
  enemy_spawner.wave_completed.connect(_on_wave_completed)
  enemy_spawner.all_waves_completed.connect(_on_all_waves_completed)


func _on_enemy_spawned(enemy: Node3D) -> void:
  ui._on_enemy_spawned(enemy)

func _on_wave_started(wave: Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  ui._on_wave_started(wave, wave_number)

func _on_wave_completed(wave: Wave) -> void:
  var wave_number = enemy_spawner.get_current_wave_number()
  ui._on_wave_completed(wave, wave_number)


func _on_all_waves_completed() -> void:
  Logger.info("Level", "All waves completed. Triggering victory.")
  GameManager.set_game_state(GameManager.GameState.VICTORY)


func on_target_died(_target: Node3D, _damage_source: String) -> void:
  if survivor_count <= 0:
    Logger.warning("Level", "All survivors already dead, ignoring target death.")
    return

  survivor_count -= 1
  Logger.trace("Level", "A survivor has died. Remaining survivors: %d" % survivor_count)

  if survivor_count <= 0:
    Logger.info("Level", "All survivors have died. Triggering game over.")
    GameManager.set_game_state(GameManager.GameState.GAME_OVER)