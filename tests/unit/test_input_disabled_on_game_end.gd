extends GutTest

## Unit tests for input disabling during victory/game over screens
## Verifies that attacks, hotbar interactions, and obstacle placement are disabled

var main_scene: Node3D
var hotbar: UI_Hotbar
var obstacle_placement: Utility_ObstaclePlacement

func before_each():
  # Reset GameManager to known state
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  GameManager.resume_game()

func after_each():
  # Clean up instantiated scenes
  if main_scene and is_instance_valid(main_scene):
    main_scene.queue_free()
    main_scene = null
  if hotbar and is_instance_valid(hotbar):
    hotbar.queue_free()
    hotbar = null
  if obstacle_placement and is_instance_valid(obstacle_placement):
    obstacle_placement.queue_free()
    obstacle_placement = null
  
  # Restore default state
  GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
  GameManager.resume_game()

func test_main_scene_disables_input_on_victory():
  # Arrange
  main_scene = preload("res://Stages/Game/main/main.tscn").instantiate()
  add_child(main_scene)
  await get_tree().process_frame
  
  # Verify initial state
  assert_true(main_scene.input_enabled, "Input should be enabled initially in PLAYING state")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  await get_tree().process_frame
  
  # Assert
  assert_false(main_scene.input_enabled, "Input should be disabled on VICTORY state")

func test_main_scene_disables_input_on_game_over():
  # Arrange
  main_scene = preload("res://Stages/Game/main/main.tscn").instantiate()
  add_child(main_scene)
  await get_tree().process_frame
  
  # Verify initial state
  assert_true(main_scene.input_enabled, "Input should be enabled initially in PLAYING state")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.GAME_OVER)
  await get_tree().process_frame
  
  # Assert
  assert_false(main_scene.input_enabled, "Input should be disabled on GAME_OVER state")

func test_main_scene_disables_input_on_in_game_menu():
  # Arrange
  main_scene = preload("res://Stages/Game/main/main.tscn").instantiate()
  add_child(main_scene)
  await get_tree().process_frame
  
  # Verify initial state
  assert_true(main_scene.input_enabled, "Input should be enabled initially in PLAYING state")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  await get_tree().process_frame
  
  # Assert
  assert_false(main_scene.input_enabled, "Input should be disabled on IN_GAME_MENU state")

func test_main_scene_re_enables_input_when_returning_to_playing():
  # Arrange
  main_scene = preload("res://Stages/Game/main/main.tscn").instantiate()
  add_child(main_scene)
  await get_tree().process_frame
  
  # Set to game over first
  GameManager.set_game_state(GameManager.GameState.GAME_OVER)
  await get_tree().process_frame
  assert_false(main_scene.input_enabled, "Input should be disabled on GAME_OVER")
  
  # Act - return to playing
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  await get_tree().process_frame
  
  # Assert
  assert_true(main_scene.input_enabled, "Input should be re-enabled when returning to PLAYING state")

func test_hotbar_disables_input_on_victory():
  # Arrange
  hotbar = preload("res://Common/UI/hotbar/hotbar.tscn").instantiate()
  add_child(hotbar)
  await get_tree().process_frame
  
  # Verify initial state
  assert_true(hotbar.input_enabled, "Input should be enabled initially in PLAYING state")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  await get_tree().process_frame
  
  # Assert
  assert_false(hotbar.input_enabled, "Hotbar input should be disabled on VICTORY state")

func test_hotbar_disables_input_on_game_over():
  # Arrange
  hotbar = preload("res://Common/UI/hotbar/hotbar.tscn").instantiate()
  add_child(hotbar)
  await get_tree().process_frame
  
  # Verify initial state
  assert_true(hotbar.input_enabled, "Input should be enabled initially in PLAYING state")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.GAME_OVER)
  await get_tree().process_frame
  
  # Assert
  assert_false(hotbar.input_enabled, "Hotbar input should be disabled on GAME_OVER state")

func test_obstacle_placement_disables_input_on_victory():
  # Arrange
  obstacle_placement = Utility_ObstaclePlacement.new()
  add_child(obstacle_placement)
  await get_tree().process_frame
  
  # Verify initial state
  assert_true(obstacle_placement.input_enabled, "Input should be enabled initially in PLAYING state")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  await get_tree().process_frame
  
  # Assert
  assert_false(obstacle_placement.input_enabled, "Placement input should be disabled on VICTORY state")

func test_obstacle_placement_disables_input_on_game_over():
  # Arrange
  obstacle_placement = Utility_ObstaclePlacement.new()
  add_child(obstacle_placement)
  await get_tree().process_frame
  
  # Verify initial state
  assert_true(obstacle_placement.input_enabled, "Input should be enabled initially in PLAYING state")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.GAME_OVER)
  await get_tree().process_frame
  
  # Assert
  assert_false(obstacle_placement.input_enabled, "Placement input should be disabled on GAME_OVER state")

func test_obstacle_placement_cancels_active_placement_on_game_end():
  # Arrange
  obstacle_placement = Utility_ObstaclePlacement.new()
  add_child(obstacle_placement)
  await get_tree().process_frame
  
  # Create a mock preview to simulate active placement
  obstacle_placement._preview = Node3D.new()
  obstacle_placement.add_child(obstacle_placement._preview)
  
  assert_not_null(obstacle_placement._preview, "Preview should exist before game end")
  
  # Act
  GameManager.set_game_state(GameManager.GameState.VICTORY)
  await get_tree().process_frame
  
  # Assert
  assert_null(obstacle_placement._preview, "Active placement should be cancelled on VICTORY state")
