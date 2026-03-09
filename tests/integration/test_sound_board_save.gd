extends GutTest

## Integration test for sound board save functionality
## Tests that modifications are properly saved to .tres files

var sound_board: UI_SoundBoard
var SoundBoardScene = preload("res://Stages/UI/sound_board/sound_board.tscn")
var test_resource_path = "res://Config/SoundEffects/default.tres"

func before_each():
  # Backup original file contents so we can do a byte-perfect restore after the test,
  # regardless of what the resource cache contains.
  var file = FileAccess.open(ProjectSettings.globalize_path(test_resource_path), FileAccess.READ)
  if file:
    set_meta("original_file_content", file.get_as_text())
    file.close()

  # Instantiate the sound board scene
  sound_board = SoundBoardScene.instantiate()
  add_child(sound_board)
  # Wait for _ready to complete
  await wait_process_frames(1)

func after_each():
  # Restore the file from the backed-up raw content
  if has_meta("original_file_content"):
    var file = FileAccess.open(ProjectSettings.globalize_path(test_resource_path), FileAccess.WRITE)
    if file:
      file.store_string(get_meta("original_file_content"))
      file.close()
    # Invalidate the resource cache entry so future loads reflect the restored file
    ResourceLoader.load(test_resource_path, "", ResourceLoader.CACHE_MODE_REPLACE)

  # Clean up the sound board
  if sound_board:
    sound_board.queue_free()
    sound_board = null

func test_save_writes_to_file():
  # Arrange - Get the DEFAULT effect
  var default_effect = Resource_SoundEffect.SoundEffect.DEFAULT
  
  # Verify we can access the effect in AudioManager
  var original_config = AudioManager.get_effect_config(default_effect)
  assert_not_null(original_config, "Should have DEFAULT config")
  
  var original_pitch_min = original_config.pitch_variation_min
  var new_pitch_min = 1.234 # Use a distinctive value
  
  # Act - Modify and save
  sound_board._on_config_value_changed(new_pitch_min, default_effect, "pitch_min")
  sound_board._on_save_button_pressed()
  await wait_process_frames(1)
  
  # Force reload from file
  ResourceLoader.load_threaded_request(test_resource_path)
  var saved_config = ResourceLoader.load(test_resource_path)
  
  # Assert
  assert_not_null(saved_config, "Should load saved resource")
  assert_almost_eq(saved_config.pitch_variation_min, new_pitch_min, 0.001,
    "Saved pitch_min should match modified value")
  
  MyLogger.info("TestSoundBoardSave", "Save test passed: %s -> %s" % [original_pitch_min, saved_config.pitch_variation_min])
