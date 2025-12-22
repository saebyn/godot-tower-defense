extends GutTest

## Unit tests for PanicBehavior component
## Tests panic detection, movement, and animation control

var panic_behavior: Component_PanicBehavior
var target_node: Node3D
var enemy_node: Node3D

func before_each():
  # Create a target node (survivor)
  target_node = Node3D.new()
  target_node.position = Vector3.ZERO
  add_child_autofree(target_node)
  
  # Create and attach panic behavior
  panic_behavior = Component_PanicBehavior.new()
  target_node.add_child(panic_behavior)
  
  # Create an enemy node for testing
  enemy_node = Node3D.new()
  enemy_node.add_to_group("enemies")
  add_child_autofree(enemy_node)

func after_each():
  # Cleanup is handled by autofree
  pass

func test_panic_behavior_initializes():
  # Assert
  assert_not_null(panic_behavior, "PanicBehavior should be created")
  assert_not_null(panic_behavior.target, "PanicBehavior should have target reference")
  assert_eq(panic_behavior.target, target_node, "Target should be the parent node")
  assert_false(panic_behavior.is_panicking, "Should not be panicking initially")

func test_panic_detection_radius():
  # Arrange - place enemy far away
  enemy_node.global_position = Vector3(20, 0, 0)
  
  # Act & Assert
  assert_false(panic_behavior._check_for_nearby_enemies(), "Should not detect enemy far away")
  
  # Arrange - place enemy nearby
  enemy_node.global_position = Vector3(5, 0, 0)
  
  # Act & Assert
  assert_true(panic_behavior._check_for_nearby_enemies(), "Should detect enemy within radius")

func test_panic_starts_when_enemy_nearby():
  # Arrange
  enemy_node.global_position = Vector3(5, 0, 0)
  assert_false(panic_behavior.is_panicking, "Should not be panicking initially")
  
  # Act - process one frame
  panic_behavior._process(0.016)
  
  # Assert
  assert_true(panic_behavior.is_panicking, "Should start panicking when enemy nearby")

func test_panic_stops_when_enemy_leaves():
  # Arrange - start with enemy nearby to trigger panic
  enemy_node.global_position = Vector3(5, 0, 0)
  panic_behavior._process(0.016)
  assert_true(panic_behavior.is_panicking, "Should be panicking with enemy nearby")
  
  # Act - move enemy far away
  enemy_node.global_position = Vector3(20, 0, 0)
  panic_behavior._process(0.016)
  
  # Assert
  assert_false(panic_behavior.is_panicking, "Should stop panicking when enemy leaves")

func test_panic_movement_stays_within_radius():
  # Arrange
  var spawn_pos = target_node.global_position
  enemy_node.global_position = Vector3(5, 0, 0)
  panic_behavior._process(0.016) # Start panic
  
  # Act - simulate multiple frames of movement
  for i in range(100):
    panic_behavior._process(0.1)
  
  # Assert - survivor should stay within panic_move_radius of spawn
  var distance_from_spawn = target_node.global_position.distance_to(spawn_pos)
  assert_lte(distance_from_spawn, panic_behavior.panic_move_radius + 0.5,
    "Survivor should stay within panic radius (got: %.2f)" % distance_from_spawn)

func test_panic_destination_chosen_within_radius():
  # Arrange
  var spawn_pos = panic_behavior.spawn_position
  
  # Act
  panic_behavior._choose_new_panic_destination()
  
  # Assert
  var distance = panic_behavior.current_panic_destination.distance_to(spawn_pos)
  assert_lte(distance, panic_behavior.panic_move_radius,
    "Panic destination should be within panic radius")

func test_multiple_enemies_trigger_panic():
  # Arrange - create multiple enemies
  var enemy2 = Node3D.new()
  enemy2.add_to_group("enemies")
  enemy2.global_position = Vector3(15, 0, 0) # Far away
  add_child_autofree(enemy2)
  
  enemy_node.global_position = Vector3(15, 0, 0) # Also far away
  
  # Act & Assert - no enemies nearby
  assert_false(panic_behavior._check_for_nearby_enemies(), "Should not detect enemies far away")
  
  # Arrange - move one enemy close
  enemy_node.global_position = Vector3(5, 0, 0)
  
  # Act & Assert - one enemy nearby
  assert_true(panic_behavior._check_for_nearby_enemies(), "Should detect one nearby enemy")

func test_survivor_voice_pitch_used_for_yelp():
  # Arrange - set voice pitch on target
  target_node.set("voice_pitch", 1.5)
  enemy_node.global_position = Vector3(5, 0, 0)
  
  # Create audio player and add to target
  var audio_player = AudioStreamPlayer3D.new()
  target_node.set("audio_player", audio_player)
  target_node.add_child(audio_player)
  add_child_autofree(audio_player)  # Ensure cleanup
  
  # Act - trigger panic behavior to call _play_yelp_sound internally
  # The panic behavior will randomly play yelp sounds, so we call it directly
  panic_behavior._play_yelp_sound()
  
  # Assert - pitch should be set to survivor's voice_pitch
  # Note: This tests the integration with AudioManager
  assert_almost_eq(audio_player.pitch_scale, 1.5, 0.01, 
    "Yelp sound should use survivor's voice_pitch")
