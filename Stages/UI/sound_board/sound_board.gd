extends Control

class_name UI_SoundBoard

## Sound board UI for testing and playing sound effects from AudioManager
## Displays sound effects organized by category in a grid layout
## Shows variation count and configurable pitch range for each effect

@onready var sound_grid_container: GridContainer = %SoundGridContainer
@onready var audio_player: AudioStreamPlayer = %AudioPlayer

func _ready():
  MyLogger.info("SoundBoard", "Sound board loaded")
  _populate_sound_grid()

func _populate_sound_grid():
  if not sound_grid_container:
    MyLogger.warn("SoundBoard", "Sound grid container not found")
    return
  
  # Group sound effects by category
  var effects_by_category: Dictionary = {}
  
  for effect_name in Resource_SoundEffect.SoundEffect.keys():
    var effect_value = Resource_SoundEffect.SoundEffect[effect_name]
    var config = AudioManager.get_effect_config(effect_value)
    
    if config != null:
      var category = config.category
      if category not in effects_by_category:
        effects_by_category[category] = []
      effects_by_category[category].append({
        "name": effect_name,
        "value": effect_value,
        "config": config
      })
    else:
      MyLogger.warn("SoundBoard", "No config found for effect: %s" % effect_name)
  
  # Get sorted list of categories
  var categories = effects_by_category.keys()
  categories.sort()
  
  # Set grid columns to number of categories
  sound_grid_container.columns = max(1, categories.size())
  
  MyLogger.info("SoundBoard", "Creating grid with %d categories and %d total effects" % [categories.size(), Resource_SoundEffect.SoundEffect.keys().size()])
  
  # Create a column for each category
  for category in categories:
    var category_container = VBoxContainer.new()
    category_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    # Category header
    var category_label = Label.new()
    var category_name = AudioManager.get_category_name(category)
    category_label.text = category_name.capitalize()
    category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    category_label.add_theme_font_size_override("font_size", 18)
    category_container.add_child(category_label)
    
    # Separator
    var separator = HSeparator.new()
    category_container.add_child(separator)
    
    # Add effects in this category
    var effects = effects_by_category[category]
    for effect_data in effects:
      var effect_button = _create_effect_button(
        effect_data["name"],
        effect_data["value"],
        effect_data["config"]
      )
      category_container.add_child(effect_button)
    
    sound_grid_container.add_child(category_container)

func _create_effect_button(effect_name: String, effect_value: Resource_SoundEffect.SoundEffect, config: Resource_SoundEffect) -> VBoxContainer:
  var button_container = VBoxContainer.new()
  button_container.custom_minimum_size = Vector2(250, 0)
  
  # Main button
  var button = Button.new()
  var display_name = effect_name.capitalize()
  button.text = display_name
  button.custom_minimum_size = Vector2(0, 40)
  # Skip audio manager auto-attachment since we handle our own sounds
  button.set_meta("skip_audio_manager", true)
  button.pressed.connect(_on_sound_button_pressed.bind(effect_value, effect_name))
  button_container.add_child(button)
  
  # Info label showing variations and pitch range
  var info_label = Label.new()
  var variation_count = config.samples.size()
  var pitch_info = "Pitch: %.1f - %.1f" % [config.pitch_variation_min, config.pitch_variation_max]
  var db_info = "Volume: %.1f dB" % config.volume_db
  info_label.text = "%d variation%s | %s | %s" % [
    variation_count,
    "s" if variation_count != 1 else "",
    pitch_info,
    db_info
  ]
  info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  info_label.add_theme_font_size_override("font_size", 10)
  info_label.modulate = Color(0.8, 0.8, 0.8, 0.9)
  button_container.add_child(info_label)
  
  # Spacing
  var spacer = Control.new()
  spacer.custom_minimum_size = Vector2(0, 5)
  button_container.add_child(spacer)
  
  return button_container

func _on_sound_button_pressed(effect: Resource_SoundEffect.SoundEffect, effect_name: String):
  MyLogger.info("SoundBoard", "Playing sound effect: %s" % effect_name)
  AudioManager.play_sound(audio_player, effect)

func _on_close_button_pressed():
  MyLogger.info("SoundBoard", "Close button pressed")
  get_tree().quit()
