extends GutTest

## Unit tests for UI_SoundBoard scene
## Tests initialization, button generation, category grouping, and audio integration

var sound_board: UI_SoundBoard
var SoundBoardScene = preload("res://Stages/UI/sound_board/sound_board.tscn")

func before_each():
  # Instantiate the sound board scene
  sound_board = SoundBoardScene.instantiate()
  add_child(sound_board)
  # Wait for _ready to complete
  await wait_frames(1)

func after_each():
  # Clean up the sound board
  if sound_board:
    sound_board.queue_free()
    sound_board = null

func test_sound_board_initializes():
  # Assert
  assert_not_null(sound_board, "Sound board should instantiate")
  assert_not_null(sound_board.sound_grid_container, "Grid container should exist")
  assert_not_null(sound_board.audio_player, "Audio player should exist")

func test_grid_container_has_columns():
  # Assert
  var grid = sound_board.sound_grid_container
  assert_true(grid.columns >= 1, "Grid should have at least 1 column")

func test_buttons_are_generated_for_sound_effects():
  # Act
  var grid = sound_board.sound_grid_container
  var category_containers = grid.get_children()
  
  # Assert
  assert_true(category_containers.size() > 0, "Should have at least one category container")
  
  # Check that each category has buttons
  var total_buttons = 0
  for category_container in category_containers:
    if category_container is VBoxContainer:
      var buttons = _find_buttons_in_container(category_container)
      total_buttons += buttons.size()
  
  assert_true(total_buttons > 0, "Should have at least one sound effect button")

func test_each_button_has_info_label():
  # Act
  var grid = sound_board.sound_grid_container
  var category_containers = grid.get_children()
  
  # Assert
  for category_container in category_containers:
    if category_container is VBoxContainer:
      var button_containers = _find_button_containers(category_container)
      for button_container in button_containers:
        var labels = _find_labels_in_container(button_container)
        assert_true(
          labels.size() > 0,
          "Each button container should have at least one info label"
        )

func test_category_headers_exist():
  # Act
  var grid = sound_board.sound_grid_container
  var category_containers = grid.get_children()
  
  # Assert
  for category_container in category_containers:
    if category_container is VBoxContainer:
      var children = category_container.get_children()
      if children.size() > 0:
        var first_child = children[0]
        assert_true(
          first_child is Label,
          "First child should be a category header label"
        )

func test_sound_board_can_be_freed():
  # Arrange
  var parent = sound_board.get_parent()
  var initial_child_count = parent.get_child_count()
  
  # Act
  sound_board.queue_free()
  await wait_frames(2)
  
  # Assert
  var final_child_count = parent.get_child_count()
  assert_true(
    final_child_count < initial_child_count,
    "Sound board should be removed when freed"
  )

func test_button_press_triggers_audio():
  # Arrange
  var grid = sound_board.sound_grid_container
  var category_containers = grid.get_children()
  var audio_player = sound_board.audio_player
  
  # Find first button
  var first_button = null
  for category_container in category_containers:
    if category_container is VBoxContainer:
      var buttons = _find_buttons_in_container(category_container)
      if buttons.size() > 0:
        first_button = buttons[0]
        break
  
  assert_not_null(first_button, "Should find at least one button")
  
  # Act
  first_button.emit_signal("pressed")
  await wait_frames(1)
  
  # Assert
  # Note: We can't reliably test if audio is playing in headless mode,
  # but we can verify the stream was set
  assert_not_null(audio_player.stream, "Audio stream should be set after button press")

func test_sound_effects_are_grouped_by_category():
  # Act
  var grid = sound_board.sound_grid_container
  var category_containers = grid.get_children()
  
  # Get all categories that have effects
  var categories_with_effects = {}
  for effect_name in Resource_SoundEffect.SoundEffect.keys():
    var effect_value = Resource_SoundEffect.SoundEffect[effect_name]
    var config = AudioManager.get_effect_config(effect_value)
    if config:
      var category = config.category
      if category not in categories_with_effects:
        categories_with_effects[category] = []
      categories_with_effects[category].append(effect_name)
  
  # Assert
  # The number of category containers should match the number of categories with effects
  assert_eq(
    category_containers.size(),
    categories_with_effects.size(),
    "Number of category columns should match number of categories with effects"
  )

func test_info_labels_show_variation_count():
  # Act
  var grid = sound_board.sound_grid_container
  var category_containers = grid.get_children()
  
  # Assert
  for category_container in category_containers:
    if category_container is VBoxContainer:
      var button_containers = _find_button_containers(category_container)
      for button_container in button_containers:
        var labels = _find_labels_in_container(button_container)
        for label in labels:
          if label.text.contains("variation"):
            # Found an info label, verify it has the expected format
            assert_true(
              label.text.contains("|"),
              "Info label should contain separator '|'"
            )
            assert_true(
              label.text.contains("Pitch:"),
              "Info label should contain pitch information"
            )

func test_info_labels_show_pitch_range():
  # Act
  var grid = sound_board.sound_grid_container
  var category_containers = grid.get_children()
  
  # Assert
  var found_pitch_info = false
  for category_container in category_containers:
    if category_container is VBoxContainer:
      var button_containers = _find_button_containers(category_container)
      for button_container in button_containers:
        var labels = _find_labels_in_container(button_container)
        for label in labels:
          if label.text.contains("Pitch:"):
            found_pitch_info = true
            # Verify format: "Pitch: X.X - X.X"
            assert_true(
              label.text.contains("-"),
              "Pitch info should show range with '-'"
            )
  
  assert_true(found_pitch_info, "Should find at least one label with pitch information")

func test_edit_mode_button_exists():
  # Assert
  assert_not_null(sound_board.edit_mode_button, "Edit mode button should exist")
  assert_true(sound_board.edit_mode_button.toggle_mode, "Edit mode button should be a toggle button")

func test_save_button_exists():
  # Assert
  assert_not_null(sound_board.save_button, "Save button should exist")
  assert_true(sound_board.save_button.disabled, "Save button should be disabled initially")

func test_edit_controls_hidden_by_default():
  # Assert
  for effect_value in sound_board.effect_edit_controls:
    var controls = sound_board.effect_edit_controls[effect_value]
    assert_false(controls["container"].visible, "Edit controls should be hidden by default")

func test_edit_mode_toggle_shows_controls():
  # Act
  sound_board.edit_mode_button.button_pressed = true
  sound_board._on_edit_mode_toggled(true)
  await wait_frames(1)
  
  # Assert
  for effect_value in sound_board.effect_edit_controls:
    var controls = sound_board.effect_edit_controls[effect_value]
    assert_true(controls["container"].visible, "Edit controls should be visible when edit mode is on")

func test_edit_controls_contain_spinboxes():
  # Assert - check first effect's controls
  if sound_board.effect_edit_controls.size() > 0:
    var first_effect = sound_board.effect_edit_controls.keys()[0]
    var controls = sound_board.effect_edit_controls[first_effect]
    
    assert_not_null(controls["pitch_min"], "Should have pitch_min spinbox")
    assert_not_null(controls["pitch_max"], "Should have pitch_max spinbox")
    assert_not_null(controls["volume"], "Should have volume spinbox")
    assert_not_null(controls["category"], "Should have category option button")

func test_modifying_value_enables_save_button():
  # Arrange
  assert_true(sound_board.save_button.disabled, "Save button should start disabled")
  
  # Get first effect controls
  if sound_board.effect_edit_controls.size() > 0:
    var first_effect = sound_board.effect_edit_controls.keys()[0]
    var controls = sound_board.effect_edit_controls[first_effect]
    
    # Act - modify a value
    var new_value = 1.5
    sound_board._on_config_value_changed(new_value, first_effect, "pitch_min")
    await wait_frames(1)
    
    # Assert
    assert_false(sound_board.save_button.disabled, "Save button should be enabled after modification")
    assert_true(sound_board.modified_configs.has(first_effect), "Effect should be in modified configs")

# Helper functions
func _find_buttons_in_container(container: Node) -> Array:
  var buttons = []
  for child in container.get_children():
    if child is Button:
      buttons.append(child)
    elif child is VBoxContainer:
      # Recursively search in VBoxContainers
      buttons.append_array(_find_buttons_in_container(child))
  return buttons

func _find_button_containers(container: Node) -> Array:
  var button_containers = []
  for child in container.get_children():
    if child is VBoxContainer:
      # Check if this VBoxContainer has a Button as a child
      for subchild in child.get_children():
        if subchild is Button:
          button_containers.append(child)
          break
  return button_containers

func _find_labels_in_container(container: Node) -> Array:
  var labels = []
  for child in container.get_children():
    if child is Label:
      labels.append(child)
  return labels
