extends GutTest

## Unit tests for Main UI Tech Tree Button
## Tests tech tree button integration in main HUD

var main_ui_scene = preload("res://Stages/UI/main_ui/ui.tscn")
var main_ui: Control

func before_each():
  # Reset managers to known state
  TechTreeManager.reset_tech_tree()
  CurrencyManager.current_scrap = 100
  CurrencyManager.current_xp = 0
  CurrencyManager.current_level = 1
  GameManager.resume_game()
  GameManager.set_game_state(GameManager.GameState.PLAYING)
  
  # Instantiate main UI
  main_ui = main_ui_scene.instantiate()
  add_child_autofree(main_ui)
  
  # Wait for ready to complete
  await wait_process_frames(2)

func test_tech_tree_button_exists():
  # Assert
  assert_not_null(main_ui.tech_tree_button, "Tech tree button should exist in main UI")

func test_tech_tree_button_has_text():
  # Assert
  assert_eq(main_ui.tech_tree_button.text, "Tech Tree", "Button should display 'Tech Tree' text")

func test_tech_tree_button_has_tooltip():
  # Assert
  assert_eq(main_ui.tech_tree_button.tooltip_text, "Open Tech Tree (Y)", "Button should have tooltip with keyboard shortcut")

func test_clicking_button_opens_tech_tree():
  # Arrange
  assert_null(main_ui.tech_tree_ui, "Tech tree should not be open initially")
  
  # Act - simulate button press
  main_ui._on_tech_tree_button_pressed()
  await wait_process_frames(2)
  
  # Assert
  assert_not_null(main_ui.tech_tree_ui, "Tech tree should be instantiated after button press")
  assert_true(GameManager.is_paused(), "Game should be paused when tech tree opens")
  assert_eq(GameManager.current_state, GameManager.GameState.IN_GAME_MENU, "Game state should be IN_GAME_MENU")

func test_closing_tech_tree_resumes_game():
  # Arrange - open tech tree first
  main_ui._on_tech_tree_button_pressed()
  await wait_process_frames(2)
  assert_not_null(main_ui.tech_tree_ui, "Tech tree should be open")
  
  # Act - close tech tree
  main_ui.tech_tree_ui.closed.emit()
  await wait_process_frames(2)
  
  # Assert
  assert_null(main_ui.tech_tree_ui, "Tech tree should be null after closing")
  assert_false(GameManager.is_paused(), "Game should be resumed after tech tree closes")
  assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "Game state should be PLAYING")

func test_keyboard_shortcut_opens_tech_tree():
  # Arrange
  assert_null(main_ui.tech_tree_ui, "Tech tree should not be open initially")
  
  # Act - simulate 'Y' key press via toggle_tech_tree
  main_ui._toggle_tech_tree()
  await wait_process_frames(2)
  
  # Assert
  assert_not_null(main_ui.tech_tree_ui, "Tech tree should be instantiated after keyboard shortcut")
  assert_true(GameManager.is_paused(), "Game should be paused when tech tree opens")

func test_keyboard_shortcut_closes_tech_tree():
  # Arrange - open tech tree first
  main_ui._toggle_tech_tree()
  await wait_process_frames(2)
  assert_not_null(main_ui.tech_tree_ui, "Tech tree should be open")
  
  # Act - press keyboard shortcut again to close
  main_ui._toggle_tech_tree()
  await wait_process_frames(2)
  
  # Assert
  assert_null(main_ui.tech_tree_ui, "Tech tree should be closed after second keyboard press")
  assert_false(GameManager.is_paused(), "Game should be resumed after tech tree closes")

func test_prevents_multiple_tech_tree_instances():
  # Arrange - open tech tree first
  main_ui._toggle_tech_tree()
  await wait_process_frames(2)
  var first_instance = main_ui.tech_tree_ui
  assert_not_null(first_instance, "Tech tree should be open")
  
  # Act - try to open tech tree again
  main_ui._show_tech_tree()
  await wait_process_frames(2)
  
  # Assert
  assert_eq(main_ui.tech_tree_ui, first_instance, "Should not create a second tech tree instance")

func test_tech_tree_process_mode_is_always():
  # Arrange - open tech tree
  main_ui._toggle_tech_tree()
  await wait_process_frames(2)
  
  # Assert
  assert_not_null(main_ui.tech_tree_ui, "Tech tree should be instantiated")
  assert_eq(main_ui.tech_tree_ui.process_mode, Node.PROCESS_MODE_ALWAYS, "Tech tree should have PROCESS_MODE_ALWAYS (3)")

func test_signal_cleanup_on_close():
  # Arrange - open and close tech tree
  main_ui._toggle_tech_tree()
  await wait_process_frames(2)
  var tech_tree_instance = main_ui.tech_tree_ui
  assert_not_null(tech_tree_instance, "Tech tree should be open")
  
  # Act - close tech tree
  main_ui._close_tech_tree()
  await wait_process_frames(2)
  
  # Assert - instance should be queued for deletion
  assert_null(main_ui.tech_tree_ui, "Reference should be null after closing")
  # Note: We can't directly test if queue_free() was called, but we verify the reference is nulled

func test_tech_tree_interactions_work_while_paused():
  # Arrange - open tech tree which pauses the game
  main_ui._toggle_tech_tree()
  await wait_process_frames(2)
  assert_true(GameManager.is_paused(), "Game should be paused")
  
  # Act - try to interact with tech tree (select a tech)
  main_ui.tech_tree_ui._on_tech_node_selected("tur_scrap_shooter")
  await wait_process_frames(2)
  
  # Assert - tech tree should respond to interactions while paused
  assert_true(main_ui.tech_tree_ui.detail_panel.visible, "Detail panel should be visible")
  assert_eq(main_ui.tech_tree_ui.selected_tech_id, "tur_scrap_shooter", "Tech should be selected while game is paused")
