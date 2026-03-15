extends GutTest

## Unit tests for Hotbar pause behavior
## Tests that hotbar slot management works when the game is paused via speed control
## and that world placement is correctly blocked when the game is paused.

var hotbar_scene = preload("res://Common/UI/hotbar/hotbar.tscn")
var hotbar: UI_Hotbar

## A minimal obstacle type added to ObstacleRegistry for tests that need it
var _test_obstacle: Resource_ObstacleType
## The original available_obstacle_types list to restore after each test
var _original_available: Array[Resource_ObstacleType] = []

func before_each():
  # Reset GameManager to known state
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  GameManager.resume_game()

  # Snapshot existing available obstacles so we can restore them after the test
  _original_available = ObstacleRegistry.available_obstacle_types.duplicate()

  # Create a minimal obstacle for tests that need a populated slot
  _test_obstacle = Resource_ObstacleType.new()
  _test_obstacle.id = "_test_hotbar_obstacle"
  _test_obstacle.name = "Test Obstacle"

  # Instantiate hotbar
  hotbar = hotbar_scene.instantiate()
  add_child_autofree(hotbar)
  await wait_process_frames(2)

func after_each():
  # Restore ObstacleRegistry to its original state
  ObstacleRegistry.available_obstacle_types = _original_available

  # Ensure game is not paused after tests
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  GameManager.resume_game()

## Helper: inject the test obstacle into the registry and configure slot 0
func _setup_populated_slot() -> void:
  ObstacleRegistry.available_obstacle_types.append(_test_obstacle)
  hotbar.slot_obstacle_ids[0] = _test_obstacle.id

## Process Mode Tests

func test_hotbar_process_mode_is_always():
  # The hotbar must process even when the scene tree is paused so that
  # slot management (right-click config) still works during speed = 0 pause.
  assert_eq(hotbar.process_mode, Node.PROCESS_MODE_ALWAYS,
    "Hotbar should have PROCESS_MODE_ALWAYS so it responds when the game is paused")

## World Placement Blocking Tests

func test_slot_pressed_emits_obstacle_selected_when_not_paused():
  # Arrange - populate slot 0 with a test obstacle and watch for the signal
  _setup_populated_slot()
  watch_signals(hotbar)

  # Act - game is not paused; pressing the slot should emit obstacle_selected
  GameManager.resume_game()
  hotbar._on_slot_pressed(0)

  # Assert - the signal must be emitted with the test obstacle
  assert_signal_emitted(hotbar, "obstacle_selected",
    "obstacle_selected should be emitted when game is not paused")
  assert_signal_emitted_with_parameters(hotbar, "obstacle_selected", [_test_obstacle],
    "obstacle_selected should carry the selected obstacle")

func test_slot_pressed_does_not_emit_obstacle_selected_when_paused():
  # Arrange - populate slot 0 and watch the signal
  _setup_populated_slot()
  watch_signals(hotbar)

  # Act - pause the game and press the slot
  GameManager.pause_game()
  hotbar._on_slot_pressed(0)

  # Assert - obstacle_selected must not be emitted when game is paused (speed = 0)
  assert_signal_not_emitted(hotbar, "obstacle_selected",
    "obstacle_selected should not be emitted when game is paused (speed = 0)")

func test_slot_pressed_does_not_emit_obstacle_selected_in_game_menu():
  # Arrange - populate slot 0 and watch the signal
  _setup_populated_slot()
  watch_signals(hotbar)

  # Act - open in-game menu (pauses the game and sets IN_GAME_MENU state)
  GameManager.pause_game()
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)
  hotbar._on_slot_pressed(0)

  # Assert - obstacle_selected must not be emitted when in-game menu is open
  assert_signal_not_emitted(hotbar, "obstacle_selected",
    "obstacle_selected should not be emitted when in-game menu is open")

## Hotbar Configuration Blocking Tests

func test_right_click_config_allowed_when_paused_via_speed_control():
  # Arrange - populate slot 0 so the config menu has something to show,
  # then simulate speed-control pause (game is paused but state is PLAYING)
  _setup_populated_slot()
  GameManager.pause_game()
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING,
    "State should remain PLAYING when paused via speed control")

  # Act - simulate right-click mouse button event
  var event = InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_RIGHT
  event.pressed = true

  hotbar.current_configuring_slot = -1
  hotbar._on_slot_gui_input(event, 0)

  # Assert - current_configuring_slot should be set, meaning the guard did NOT block
  assert_eq(hotbar.current_configuring_slot, 0,
    "Slot configuration should be allowed when paused via speed control (state = PLAYING)")

func test_right_click_config_blocked_when_in_game_menu():
  # Arrange - open in-game menu
  _setup_populated_slot()
  GameManager.pause_game()
  GameManager.set_game_state(GameManager.GameState.IN_GAME_MENU)

  # Act - attempt right-click config — should be ignored
  var event = InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_RIGHT
  event.pressed = true

  hotbar.current_configuring_slot = -1
  hotbar._on_slot_gui_input(event, 0)

  # Assert - current_configuring_slot must remain -1 because the guard blocked the call
  assert_eq(hotbar.current_configuring_slot, -1,
    "Slot configuration should be blocked when in-game menu is open")
