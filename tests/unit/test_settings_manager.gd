extends GutTest

## Unit tests for SettingsManager functionality
## Tests default settings values and audio volume configuration

func before_each():
  # Note: We cannot fully reset SettingsManager between tests since it's an autoload
  # Tests should be designed to be independent despite this limitation
  pass

func after_each():
  pass

func test_default_master_volume_is_50_percent():
  # Arrange - SettingsManager is already initialized as an autoload
  
  # Act - Get the default master volume in dB
  var master_volume_db = SettingsManager.master_volume
  
  # Convert dB to percentage for verification
  var master_volume_percentage = _db_to_percentage(master_volume_db)
  
  # Assert - Default master volume should be approximately 50%
  assert_almost_eq(master_volume_percentage, 50.0, 0.5, "Default master volume should be 50%")
  assert_almost_eq(master_volume_db, -6.02, 0.1, "Default master volume should be -6.02 dB")

func test_default_music_volume():
  # Arrange - SettingsManager is already initialized
  
  # Act
  var music_volume_db = SettingsManager.music_volume
  var music_volume_percentage = _db_to_percentage(music_volume_db)
  
  # Assert - Music volume default is 0.0 dB (100%)
  assert_eq(music_volume_db, 0.0, "Default music volume should be 0.0 dB")
  assert_almost_eq(music_volume_percentage, 100.0, 0.5, "Default music volume should be 100%")

func test_default_sfx_volume():
  # Arrange - SettingsManager is already initialized
  
  # Act
  var sfx_volume_db = SettingsManager.sfx_volume
  var sfx_volume_percentage = _db_to_percentage(sfx_volume_db)
  
  # Assert - SFX volume default is 0.0 dB (100%)
  assert_eq(sfx_volume_db, 0.0, "Default SFX volume should be 0.0 dB")
  assert_almost_eq(sfx_volume_percentage, 100.0, 0.5, "Default SFX volume should be 100%")

func test_volume_conversion_db_to_percentage():
  # Test the conversion function for various values
  assert_almost_eq(_db_to_percentage(0.0), 100.0, 0.1, "0 dB should be 100%")
  assert_almost_eq(_db_to_percentage(-6.02), 50.0, 0.5, "-6.02 dB should be 50%")
  assert_almost_eq(_db_to_percentage(-12.04), 25.0, 0.5, "-12.04 dB should be 25%")
  assert_almost_eq(_db_to_percentage(-80.0), 0.0, 0.5, "-80 dB should be 0%")

# Helper function to convert dB to percentage (same as in settings_menu.gd)
func _db_to_percentage(db: float) -> float:
  return db_to_linear(db) * 100.0
