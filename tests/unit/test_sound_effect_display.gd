extends GutTest

## Unit tests for UI_SoundEffectDisplay
## Tests sound effect tracking, aggregation, and expiration

var sound_effect_display: UI_SoundEffectDisplay
var container: VBoxContainer

func before_each():
  # Create a test instance of the sound effect display
  sound_effect_display = UI_SoundEffectDisplay.new()
  
  # Create the container manually for unit testing since @onready won't work
  container = VBoxContainer.new()
  container.name = "EffectsContainer"
  sound_effect_display.add_child(container)
  
  # Set the container reference manually
  sound_effect_display.container = container
  
  # Add to tree (will trigger _ready which sets visible=false)
  add_child(sound_effect_display)
  
  # Make visible for testing (after _ready runs)
  await get_tree().process_frame
  sound_effect_display.visible = true

func after_each():
  # Clean up the test instance
  if sound_effect_display:
    sound_effect_display.queue_free()
    sound_effect_display = null

func test_display_initially_hidden():
  # Arrange
  var new_display = UI_SoundEffectDisplay.new()
  add_child(new_display)
  
  # Act & Assert
  assert_false(new_display.visible, "Display should be hidden initially")
  
  # Cleanup
  new_display.queue_free()

func test_toggle_display_visibility():
  # Arrange
  sound_effect_display.visible = false
  
  # Act
  sound_effect_display.toggle_display()
  
  # Assert
  assert_true(sound_effect_display.visible, "Display should be visible after toggle")
  
  # Act
  sound_effect_display.toggle_display()
  
  # Assert
  assert_false(sound_effect_display.visible, "Display should be hidden after second toggle")

func test_sound_played_creates_new_entry():
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  
  # Debug: Verify setup
  assert_not_null(sound_effect_display.container, "Container should not be null")
  assert_true(sound_effect_display.visible, "Display should be visible")
  
  # Act
  sound_effect_display._on_sound_played(effect)
  
  # Assert
  assert_eq(sound_effect_display.tracked_effects.size(), 1, "Should have one tracked effect")
  var effect_name = sound_effect_display._get_effect_name(effect)
  assert_true(effect_name in sound_effect_display.tracked_effects, "Effect should be tracked")

func test_duplicate_sound_increments_count():
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.TURRET_FIRE
  
  # Act
  sound_effect_display._on_sound_played(effect)
  sound_effect_display._on_sound_played(effect)
  sound_effect_display._on_sound_played(effect)
  
  # Assert
  var effect_name = sound_effect_display._get_effect_name(effect)
  var entry = sound_effect_display.tracked_effects[effect_name]
  assert_eq(entry.count, 3, "Count should be 3 after playing same effect 3 times")

func test_label_text_shows_count_for_duplicates():
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.ZOMBIE_DEATH
  
  # Act
  sound_effect_display._on_sound_played(effect)
  var effect_name = sound_effect_display._get_effect_name(effect)
  var entry_single = sound_effect_display.tracked_effects[effect_name]
  var text_single = entry_single.label.text
  
  sound_effect_display._on_sound_played(effect)
  var entry_multi = sound_effect_display.tracked_effects[effect_name]
  var text_multi = entry_multi.label.text
  
  # Assert
  assert_false(text_single.contains("(x"), "Single occurrence should not show count")
  assert_true(text_multi.contains("(x2)"), "Multiple occurrences should show count")

func test_different_sounds_create_separate_entries():
  # Arrange
  var effect1 = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  var effect2 = Resource_SoundEffect.SoundEffect.ZOMBIE_DEATH
  var effect3 = Resource_SoundEffect.SoundEffect.UI_CONFIRM
  
  # Act
  sound_effect_display._on_sound_played(effect1)
  sound_effect_display._on_sound_played(effect2)
  sound_effect_display._on_sound_played(effect3)
  
  # Assert
  assert_eq(sound_effect_display.tracked_effects.size(), 3, "Should have three separate tracked effects")

func test_get_effect_name_returns_readable_name():
  # Arrange
  var effect = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  
  # Act
  var name = sound_effect_display._get_effect_name(effect)
  
  # Assert
  assert_eq(name, "Player Attack Hit", "Should return capitalized readable name")

func test_clear_all_effects():
  # Arrange
  sound_effect_display._on_sound_played(Resource_SoundEffect.SoundEffect.TURRET_FIRE)
  sound_effect_display._on_sound_played(Resource_SoundEffect.SoundEffect.ZOMBIE_DEATH)
  
  # Act
  sound_effect_display._clear_all_effects()
  
  # Assert
  assert_eq(sound_effect_display.tracked_effects.size(), 0, "All effects should be cleared")

func test_max_display_limit_enforcement():
  # Arrange - Play more than MAX_DISPLAYED_EFFECTS
  for i in range(sound_effect_display.MAX_DISPLAYED_EFFECTS + 5):
    # Use different effects by using modulo on enum values
    var effect_values = Resource_SoundEffect.SoundEffect.values()
    var effect = effect_values[i % effect_values.size()]
    # Wait a tiny bit between each to ensure different timestamps
    await get_tree().create_timer(0.01).timeout
    sound_effect_display._on_sound_played(effect)
  
  # Assert
  assert_lte(
    sound_effect_display.tracked_effects.size(),
    sound_effect_display.MAX_DISPLAYED_EFFECTS,
    "Should not exceed maximum display limit"
  )

func test_sound_not_tracked_when_invisible():
  # Arrange
  sound_effect_display.visible = false
  var effect = Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT
  
  # Act
  sound_effect_display._on_sound_played(effect)
  
  # Assert
  assert_eq(sound_effect_display.tracked_effects.size(), 0, "Should not track sounds when invisible")
