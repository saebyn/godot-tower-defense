extends GutTest

## Unit test for Health Component camera-based scaling
## Verifies that health bars maintain constant screen-space size

var health_component: Component_Health
var test_scene: Node3D
var test_camera: Camera3D
var sprite3d: Sprite3D

func before_each():
  # Create a test scene with a camera and health component
  test_scene = Node3D.new()
  add_child_autofree(test_scene)
  
  # Create and configure a test camera
  test_camera = Camera3D.new()
  test_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
  test_camera.size = 65.0  # Default reference size
  test_scene.add_child(test_camera)
  
  # Load the health component scene
  var health_scene = load("res://Common/Components/health/health.tscn")
  health_component = health_scene.instantiate()
  test_scene.add_child(health_component)
  
  # Get reference to the sprite3d node
  sprite3d = health_component.get_node("Sprite3D")
  
  # Wait for _ready to be called
  await wait_frames(2)

func test_health_component_finds_camera():
  # Assert
  assert_not_null(health_component.camera, "Health component should find the camera")
  assert_eq(health_component.camera, test_camera, "Should find the correct camera")

func test_scale_at_reference_size():
  # Arrange - Camera at reference size
  test_camera.size = 65.0
  health_component.reference_camera_size = 65.0
  
  # Act - Process one frame to update scale
  await wait_frames(1)
  
  # Assert - Scale should be 1.0 at reference size
  assert_almost_eq(sprite3d.scale.x, 1.0, 0.01, "Scale should be 1.0 at reference camera size")
  assert_almost_eq(sprite3d.scale.y, 1.0, 0.01, "Scale Y should be 1.0 at reference camera size")
  assert_almost_eq(sprite3d.scale.z, 1.0, 0.01, "Scale Z should be 1.0 at reference camera size")

func test_scale_at_minimum_zoom():
  # Arrange - Camera at minimum zoom (closest, smaller size)
  test_camera.size = 5.0
  health_component.reference_camera_size = 65.0
  
  # Act - Process one frame to update scale
  await wait_frames(1)
  
  # Assert - Scale should be proportionally smaller (5.0 / 65.0 ≈ 0.077)
  var expected_scale = 5.0 / 65.0
  assert_almost_eq(sprite3d.scale.x, expected_scale, 0.01, "Scale should be smaller at minimum zoom")

func test_scale_at_maximum_zoom():
  # Arrange - Camera at maximum zoom (farthest, larger size)
  test_camera.size = 300.0
  health_component.reference_camera_size = 65.0
  
  # Act - Process one frame to update scale
  await wait_frames(1)
  
  # Assert - Scale should be proportionally larger (300.0 / 65.0 ≈ 4.62)
  var expected_scale = 300.0 / 65.0
  assert_almost_eq(sprite3d.scale.x, expected_scale, 0.01, "Scale should be larger at maximum zoom")

func test_scale_updates_when_camera_size_changes():
  # Arrange - Start at reference size
  test_camera.size = 65.0
  health_component.reference_camera_size = 65.0
  await wait_frames(1)
  
  var initial_scale = sprite3d.scale.x
  
  # Act - Change camera size
  test_camera.size = 130.0
  await wait_frames(1)
  
  # Assert - Scale should update
  assert_almost_eq(sprite3d.scale.x, 2.0, 0.01, "Scale should double when camera size doubles")
  assert_ne(sprite3d.scale.x, initial_scale, "Scale should change when camera size changes")

func test_scale_does_not_update_unnecessarily():
  # Arrange
  test_camera.size = 65.0
  health_component.reference_camera_size = 65.0
  await wait_frames(1)
  
  var initial_last_camera_size = health_component.last_camera_size
  
  # Act - Process frames without changing camera size
  await wait_frames(5)
  
  # Assert - last_camera_size should remain the same
  assert_eq(health_component.last_camera_size, initial_last_camera_size, 
    "last_camera_size should not change when camera size is constant")
