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
  
  # Assert - Default master volume should be approximately 50%
  assert_almost_eq(master_volume_db, -6.02, 0.1, "Default master volume should be -6.02 dB")

func test_default_music_volume():
  # Arrange - SettingsManager is already initialized
  # Act
  var music_volume_db = SettingsManager.music_volume
  
  # Assert - Music volume default is 0.0 dB (100%)
  assert_eq(music_volume_db, 0.0, "Default music volume should be 0.0 dB")

func test_default_sfx_volume():
  # Arrange - SettingsManager is already initialized
  # Act
  var sfx_volume_db = SettingsManager.sfx_volume
  
  # Assert - SFX volume default is 0.0 dB (100%)
  assert_eq(sfx_volume_db, 0.0, "Default SFX volume should be 0.0 dB")
