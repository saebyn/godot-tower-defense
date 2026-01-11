extends GutTest

## Unit tests for SceneReferences autoload
## Tests registration/unregistration of Camera3D and System_EnemySpawner references

var mock_camera: Camera3D
var mock_spawner: System_EnemySpawner

func before_each():
	# Reset SceneReferences state
	SceneReferences.camera = null
	SceneReferences.enemy_spawner = null
	
	# Create mock objects
	mock_camera = Camera3D.new()
	mock_spawner = System_EnemySpawner.new()

func after_each():
	# Clean up mock objects
	if mock_camera:
		mock_camera.free()
		mock_camera = null
	if mock_spawner:
		mock_spawner.free()
		mock_spawner = null

func test_register_camera_stores_reference():
	# Arrange & Act
	SceneReferences.register_camera(mock_camera)
	
	# Assert
	assert_eq(SceneReferences.camera, mock_camera, "Camera should be stored in SceneReferences")
	assert_eq(SceneReferences.get_camera(), mock_camera, "get_camera() should return stored camera")

func test_unregister_camera_clears_reference():
	# Arrange
	SceneReferences.register_camera(mock_camera)
	
	# Act
	SceneReferences.unregister_camera()
	
	# Assert
	assert_null(SceneReferences.camera, "Camera should be null after unregistration")
	assert_null(SceneReferences.get_camera(), "get_camera() should return null after unregistration")

func test_register_camera_emits_signal():
	# Arrange
	var signal_watcher = watch_signals(SceneReferences)
	
	# Act
	SceneReferences.register_camera(mock_camera)
	
	# Assert
	assert_signal_emitted(SceneReferences, "camera_registered", "Should emit camera_registered signal")
	assert_signal_emit_count(SceneReferences, "camera_registered", 1, "Should emit signal once")

func test_unregister_camera_emits_signal():
	# Arrange
	SceneReferences.register_camera(mock_camera)
	var signal_watcher = watch_signals(SceneReferences)
	
	# Act
	SceneReferences.unregister_camera()
	
	# Assert
	assert_signal_emitted(SceneReferences, "camera_unregistered", "Should emit camera_unregistered signal")

func test_register_enemy_spawner_stores_reference():
	# Arrange & Act
	SceneReferences.register_enemy_spawner(mock_spawner)
	
	# Assert
	assert_eq(SceneReferences.enemy_spawner, mock_spawner, "Enemy spawner should be stored in SceneReferences")
	assert_eq(SceneReferences.get_enemy_spawner(), mock_spawner, "get_enemy_spawner() should return stored spawner")

func test_unregister_enemy_spawner_clears_reference():
	# Arrange
	SceneReferences.register_enemy_spawner(mock_spawner)
	
	# Act
	SceneReferences.unregister_enemy_spawner()
	
	# Assert
	assert_null(SceneReferences.enemy_spawner, "Enemy spawner should be null after unregistration")
	assert_null(SceneReferences.get_enemy_spawner(), "get_enemy_spawner() should return null after unregistration")

func test_register_enemy_spawner_emits_signal():
	# Arrange
	var signal_watcher = watch_signals(SceneReferences)
	
	# Act
	SceneReferences.register_enemy_spawner(mock_spawner)
	
	# Assert
	assert_signal_emitted(SceneReferences, "enemy_spawner_registered", "Should emit enemy_spawner_registered signal")
	assert_signal_emit_count(SceneReferences, "enemy_spawner_registered", 1, "Should emit signal once")

func test_unregister_enemy_spawner_emits_signal():
	# Arrange
	SceneReferences.register_enemy_spawner(mock_spawner)
	var signal_watcher = watch_signals(SceneReferences)
	
	# Act
	SceneReferences.unregister_enemy_spawner()
	
	# Assert
	assert_signal_emitted(SceneReferences, "enemy_spawner_unregistered", "Should emit enemy_spawner_unregistered signal")

func test_register_camera_twice_replaces_reference():
	# Arrange
	var second_camera = Camera3D.new()
	SceneReferences.register_camera(mock_camera)
	
	# Act
	SceneReferences.register_camera(second_camera)
	
	# Assert
	assert_eq(SceneReferences.camera, second_camera, "Should replace old camera with new camera")
	assert_ne(SceneReferences.camera, mock_camera, "Should not keep old camera reference")
	
	# Cleanup
	second_camera.free()

func test_register_enemy_spawner_twice_replaces_reference():
	# Arrange
	var second_spawner = System_EnemySpawner.new()
	SceneReferences.register_enemy_spawner(mock_spawner)
	
	# Act
	SceneReferences.register_enemy_spawner(second_spawner)
	
	# Assert
	assert_eq(SceneReferences.enemy_spawner, second_spawner, "Should replace old spawner with new spawner")
	assert_ne(SceneReferences.enemy_spawner, mock_spawner, "Should not keep old spawner reference")
	
	# Cleanup
	second_spawner.free()

func test_get_camera_returns_null_when_not_registered():
	# Act & Assert
	assert_null(SceneReferences.get_camera(), "Should return null when no camera is registered")

func test_get_enemy_spawner_returns_null_when_not_registered():
	# Act & Assert
	assert_null(SceneReferences.get_enemy_spawner(), "Should return null when no spawner is registered")
