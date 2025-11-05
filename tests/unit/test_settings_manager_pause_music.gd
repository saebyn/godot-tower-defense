extends GutTest

## Unit tests for SettingsManager pause_music_on_pause functionality
## Tests save/load and setter functionality for the new setting

const TEST_SETTINGS_FILE = "user://test_settings_pause_music.cfg"

func before_each():
  # Clean up any existing test settings file
  if FileAccess.file_exists(TEST_SETTINGS_FILE):
    DirAccess.remove_absolute(TEST_SETTINGS_FILE)

func after_each():
  # Clean up test settings file
  if FileAccess.file_exists(TEST_SETTINGS_FILE):
    DirAccess.remove_absolute(TEST_SETTINGS_FILE)

func test_pause_music_on_pause_default_value():
  # Assert
  assert_true(SettingsManager.pause_music_on_pause, "pause_music_on_pause should default to true")

func test_set_pause_music_on_pause():
  # Arrange
  var initial_value = SettingsManager.pause_music_on_pause
  var new_value = not initial_value
  
  # Act
  SettingsManager.set_pause_music_on_pause(new_value)
  
  # Assert
  assert_eq(SettingsManager.pause_music_on_pause, new_value, "pause_music_on_pause should be updated")

func test_pause_music_on_pause_persists_after_save_and_load():
  # Arrange
  var config = ConfigFile.new()
  SettingsManager.pause_music_on_pause = false
  
  # Act - Save the setting
  config.set_value("audio", "pause_music_on_pause", SettingsManager.pause_music_on_pause)
  var save_err = config.save(TEST_SETTINGS_FILE)
  assert_eq(save_err, OK, "Settings should save successfully")
  
  # Reset the value
  SettingsManager.pause_music_on_pause = true
  
  # Load the setting
  var load_err = config.load(TEST_SETTINGS_FILE)
  assert_eq(load_err, OK, "Settings should load successfully")
  var loaded_value = config.get_value("audio", "pause_music_on_pause", true)
  
  # Assert
  assert_false(loaded_value, "Loaded pause_music_on_pause should match saved value")

func test_audio_settings_changed_signal_emitted_on_change():
  # Arrange
  watch_signals(SettingsManager)
  var new_value = not SettingsManager.pause_music_on_pause
  
  # Act
  SettingsManager.set_pause_music_on_pause(new_value)
  
  # Assert
  assert_signal_emitted(SettingsManager, "audio_settings_changed", "audio_settings_changed signal should be emitted")

func test_setting_same_value_does_not_emit_signal():
  # Arrange
  watch_signals(SettingsManager)
  var current_value = SettingsManager.pause_music_on_pause
  
  # Act
  SettingsManager.set_pause_music_on_pause(current_value)
  
  # Assert
  assert_signal_not_emitted(SettingsManager, "audio_settings_changed", "Signal should not be emitted when value doesn't change")
