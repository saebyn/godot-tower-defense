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


func test_sound_effect_config_default_values():
  # Arrange & Act
  var config = Resource_SoundEffect.new()
  
  # Assert
  assert_eq(config.category, Resource_SoundEffect.SoundCategory.COMBAT, "Category should be COMBAT by default")
  assert_almost_eq(config.pitch_variation_min, 0.9, 0.01, "Default min pitch should be 0.9")
  assert_almost_eq(config.pitch_variation_max, 1.1, 0.01, "Default max pitch should be 1.1")

func test_get_effect_config_returns_valid_config():
  # Act
  var config = AudioManager.get_effect_config(Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT)
  
  # Assert
  assert_not_null(config, "Config should not be null for PLAYER_ATTACK_HIT")
  assert_eq(config.category, Resource_SoundEffect.SoundCategory.PLAYER_ACTION, "PLAYER_ATTACK_HIT should be in PLAYER_ACTION category")

func test_get_effect_config_returns_null_for_missing_effect():
  # Note: This test verifies the current behavior where missing effects return null
  # We use a value outside the valid enum range
  var valid_values = Resource_SoundEffect.SoundEffect.values()
  var invalid_effect = valid_values.max() + 1
  
  # Act
  var config = AudioManager.get_effect_config(invalid_effect)
  
  # Assert
  assert_null(config, "Config should be null for invalid effect")

func test_get_category_name_returns_correct_string():
  # Act
  var combat_name = AudioManager.get_category_name(Resource_SoundEffect.SoundCategory.COMBAT)
  var ui_name = AudioManager.get_category_name(Resource_SoundEffect.SoundCategory.USER_INTERFACE)
  var building_name = AudioManager.get_category_name(Resource_SoundEffect.SoundCategory.BUILDING)
  var ambience_name = AudioManager.get_category_name(Resource_SoundEffect.SoundCategory.AMBIENCE)
  
  # Assert
  assert_eq(combat_name, "COMBAT", "COMBAT category name should be 'COMBAT'")
  assert_eq(ui_name, "USER_INTERFACE", "USER_INTERFACE category name should be 'USER_INTERFACE'")
  assert_eq(building_name, "BUILDING", "BUILDING category name should be 'BUILDING'")
  assert_eq(ambience_name, "AMBIENCE", "AMBIENCE category name should be 'AMBIENCE'")

func test_play_sound_sets_audio_stream():
  # Skip if audio resources aren't loaded (e.g., in CI without full import)
  var config = AudioManager.get_effect_config(Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT)
  if config == null or config.samples.is_empty():
    pending("Audio resources not loaded - skipping test")
    return
  
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  
  # Act
  AudioManager.play_sound(test_audio_player, effect)
  
  # Assert
  assert_not_null(test_audio_player.stream, "Audio stream should be set")
  assert_true(test_audio_player.playing, "Audio player should be playing")

func test_play_sound_applies_pitch_variation():
  # Skip if audio resources aren't loaded (e.g., in CI without full import)
  var config = AudioManager.get_effect_config(Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT)
  if config == null or config.samples.is_empty():
    pending("Audio resources not loaded - skipping test")
    return
  
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  
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

func test_play_sound_with_pitch_override():
  # Skip if audio resources aren't loaded (e.g., in CI without full import)
  var config = AudioManager.get_effect_config(Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT)
  if config == null or config.samples.is_empty():
    pending("Audio resources not loaded - skipping test")
    return
  
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  var pitch_override = 1.5
  
  # Act
  AudioManager.play_sound(test_audio_player, effect, pitch_override)
  
  # Assert
  assert_almost_eq(
    test_audio_player.pitch_scale,
    pitch_override,
    0.01,
    "Pitch scale should match the override value"
  )

func test_play_sound_without_pitch_override_uses_config():
  # Skip if audio resources aren't loaded (e.g., in CI without full import)
  var config = AudioManager.get_effect_config(Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT)
  if config == null or config.samples.is_empty():
    pending("Audio resources not loaded - skipping test")
    return
  
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  
  # Act - explicitly pass null to test default behavior
  AudioManager.play_sound(test_audio_player, effect, null)
  
  # Assert
  assert_true(
    test_audio_player.pitch_scale >= config.pitch_variation_min,
    "Pitch scale should be >= min pitch when no override"
  )
  assert_true(
    test_audio_player.pitch_scale <= config.pitch_variation_max,
    "Pitch scale should be <= max pitch when no override"
  )

func test_survivor_yelp_uses_default_pitch_variation():
  # Act
  var config = AudioManager.get_effect_config(Resource_SoundEffect.SoundEffect.SURVIVOR_YELP)
  
  # Skip if audio resources aren't loaded (e.g., in CI without full import)
  if config == null:
    pending("Audio resources not loaded - skipping test")
    return
  
  # Assert - should use default pitch variation (0.9 - 1.1)
  assert_not_null(config, "SURVIVOR_YELP should have a config")
  assert_almost_eq(config.pitch_variation_min, 0.9, 0.01, "SURVIVOR_YELP should use default min pitch (0.9)")
  assert_almost_eq(config.pitch_variation_max, 1.1, 0.01, "SURVIVOR_YELP should use default max pitch (1.1)")
