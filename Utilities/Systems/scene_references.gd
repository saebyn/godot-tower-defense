extends Node

## SceneReferences Autoload
##
## Centralized registry for commonly accessed scene references (Camera3D, EnemySpawner).
## Eliminates the need for expensive recursive scene tree traversal to find these components.
##
## Usage:
##   - Components self-register in _ready() using register_camera() or register_enemy_spawner()
##   - Components self-unregister in _exit_tree() using unregister_camera() or unregister_enemy_spawner()
##   - Consumers access via SceneReferences.camera or SceneReferences.get_camera()
##   - Listen to signals for immediate notification of registration/unregistration events

var camera: Camera3D = null
var enemy_spawner: System_EnemySpawner = null

signal camera_registered(camera: Camera3D)
signal camera_unregistered()
signal enemy_spawner_registered(spawner: System_EnemySpawner)
signal enemy_spawner_unregistered()

## Register the main camera. Emits camera_registered signal.
## Logs a warning if replacing an existing camera reference.
func register_camera(new_camera: Camera3D) -> void:
  if camera and camera != new_camera:
    MyLogger.warn("SceneReferences", "Replacing existing camera reference")
  camera = new_camera
  camera_registered.emit(new_camera)
  MyLogger.info("SceneReferences", "Camera registered")

## Unregister the main camera. Emits camera_unregistered signal.
func unregister_camera() -> void:
  camera = null
  camera_unregistered.emit()
  MyLogger.info("SceneReferences", "Camera unregistered")

## Register the enemy spawner. Emits enemy_spawner_registered signal.
## Logs a warning if replacing an existing spawner reference.
func register_enemy_spawner(spawner: System_EnemySpawner) -> void:
  if enemy_spawner and enemy_spawner != spawner:
    MyLogger.warn("SceneReferences", "Replacing existing enemy spawner reference")
  enemy_spawner = spawner
  enemy_spawner_registered.emit(spawner)
  MyLogger.info("SceneReferences", "Enemy spawner registered")

## Unregister the enemy spawner. Emits enemy_spawner_unregistered signal.
func unregister_enemy_spawner() -> void:
  enemy_spawner = null
  enemy_spawner_unregistered.emit()
  MyLogger.info("SceneReferences", "Enemy spawner unregistered")

## Get the registered camera. Returns null if not registered.
func get_camera() -> Camera3D:
  return camera

## Get the registered enemy spawner. Returns null if not registered.
func get_enemy_spawner() -> System_EnemySpawner:
  return enemy_spawner
