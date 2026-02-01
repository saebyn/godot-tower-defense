extends GutTest

## Integration test for sound board save functionality
## Tests that modifications are properly saved to .tres files

var sound_board: UI_SoundBoard
var SoundBoardScene = preload("res://Stages/UI/sound_board/sound_board.tscn")
var test_resource_path = "res://Config/SoundEffects/default.tres"

func before_each():
  # Backup original resource
  var original = ResourceLoader.load(test_resource_path)
  if original:
    # Store original values for restoration
    set_meta("original_pitch_min", original.pitch_variation_min)
    set_meta("original_pitch_max", original.pitch_variation_max)
    set_meta("original_volume", original.volume_db)
    set_meta("original_category", original.category)
  
  # Instantiate the sound board scene
  sound_board = SoundBoardScene.instantiate()
  add_child(sound_board)
  # Wait for _ready to complete
  await wait_process_frames(1)

func after_each():
  # Restore original resource
  var original = ResourceLoader.load(test_resource_path)
  if original and has_meta("original_pitch_min"):
    original.pitch_variation_min = get_meta("original_pitch_min")
    original.pitch_variation_max = get_meta("original_pitch_max")
    original.volume_db = get_meta("original_volume")
    original.category = get_meta("original_category")
    ResourceSaver.save(original, test_resource_path)
  
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
