extends GutTest

## Unit tests for AudioManager autoload
## Tests SoundEffectConfig class, category system, and helper methods

var test_audio_player: AudioStreamPlayer

func before_each():
  # Create a test audio player for playback tests
  test_audio_player = AudioStreamPlayer.new()
  add_child(test_audio_player)

func after_each():
  # Clean up the test audio player
  if test_audio_player:
    test_audio_player.queue_free()
    test_audio_player = null

func test_sound_effect_config_initialization():
  # Arrange & Act
  var config = AudioManager.SoundEffectConfig.new(
    [],
    AudioManager.SoundCategory.COMBAT,
    0.8,
    1.2
  )
  
  # Assert
  assert_eq(config.category, AudioManager.SoundCategory.COMBAT, "Category should be COMBAT")
  assert_almost_eq(config.pitch_variation_min, 0.8, 0.01, "Min pitch should be 0.8")
  assert_almost_eq(config.pitch_variation_max, 1.2, 0.01, "Max pitch should be 1.2")
  assert_eq(config.samples.size(), 0, "Samples array should be empty")

func test_sound_effect_config_default_values():
  # Arrange & Act
  var config = AudioManager.SoundEffectConfig.new(
    [],
    AudioManager.SoundCategory.USER_INTERFACE
  )
  
  # Assert
  assert_eq(config.category, AudioManager.SoundCategory.USER_INTERFACE, "Category should be USER_INTERFACE")
  assert_almost_eq(config.pitch_variation_min, 0.5, 0.01, "Default min pitch should be 0.5")
  assert_almost_eq(config.pitch_variation_max, 1.0, 0.01, "Default max pitch should be 1.0")

func test_get_effect_config_returns_valid_config():
  # Act
  var config = AudioManager.get_effect_config(AudioManager.SoundEffect.PLAYER_ATTACK_HIT)
  
  # Assert
  assert_not_null(config, "Config should not be null for PLAYER_ATTACK_HIT")
  assert_eq(config.category, AudioManager.SoundCategory.COMBAT, "PLAYER_ATTACK_HIT should be in COMBAT category")

func test_get_effect_config_returns_null_for_missing_effect():
  # Note: This test verifies the current behavior where missing effects return null
  # We use a value outside the valid enum range
  var valid_values = AudioManager.SoundEffect.values()
  var invalid_effect = valid_values.max() + 1
  
  # Act
  var config = AudioManager.get_effect_config(invalid_effect)
  
  # Assert
  assert_null(config, "Config should be null for invalid effect")

func test_get_category_name_returns_correct_string():
  # Act
  var combat_name = AudioManager.get_category_name(AudioManager.SoundCategory.COMBAT)
  var ui_name = AudioManager.get_category_name(AudioManager.SoundCategory.USER_INTERFACE)
  var building_name = AudioManager.get_category_name(AudioManager.SoundCategory.BUILDING)
  var ambience_name = AudioManager.get_category_name(AudioManager.SoundCategory.AMBIENCE)
  
  # Assert
  assert_eq(combat_name, "COMBAT", "COMBAT category name should be 'COMBAT'")
  assert_eq(ui_name, "USER_INTERFACE", "USER_INTERFACE category name should be 'USER_INTERFACE'")
  assert_eq(building_name, "BUILDING", "BUILDING category name should be 'BUILDING'")
  assert_eq(ambience_name, "AMBIENCE", "AMBIENCE category name should be 'AMBIENCE'")

func test_play_sound_sets_audio_stream():
  # Arrange
  var effect = AudioManager.SoundEffect.PLAYER_ATTACK_HIT
  
  # Act
  AudioManager.play_sound(test_audio_player, effect)
  
  # Assert
  assert_not_null(test_audio_player.stream, "Audio stream should be set")
  assert_true(test_audio_player.playing, "Audio player should be playing")

func test_play_sound_applies_pitch_variation():
  # Arrange
  var effect = AudioManager.SoundEffect.PLAYER_ATTACK_HIT
  var config = AudioManager.get_effect_config(effect)
  
  # Act
  AudioManager.play_sound(test_audio_player, effect)
  
  # Assert
  assert_true(
    test_audio_player.pitch_scale >= config.pitch_variation_min,
    "Pitch scale should be >= min pitch"
  )
  assert_true(
    test_audio_player.pitch_scale <= config.pitch_variation_max,
    "Pitch scale should be <= max pitch"
  )

func test_all_sound_effects_have_configs():
  # Act & Assert
  for effect_name in AudioManager.SoundEffect.keys():
    var effect_value = AudioManager.SoundEffect[effect_name]
    var config = AudioManager.get_effect_config(effect_value)
    
    assert_not_null(
      config,
      "Effect %s should have a config" % effect_name
    )

func test_all_configs_have_valid_pitch_ranges():
  # Act & Assert
  for effect_name in AudioManager.SoundEffect.keys():
    var effect_value = AudioManager.SoundEffect[effect_name]
    var config = AudioManager.get_effect_config(effect_value)
    
    if config:
      assert_true(
        config.pitch_variation_min < config.pitch_variation_max,
        "Min pitch should be less than max pitch for %s" % effect_name
      )
      assert_true(
        config.pitch_variation_min > 0.0,
        "Min pitch should be positive for %s" % effect_name
      )
