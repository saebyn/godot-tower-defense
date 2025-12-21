extends Control

class_name UI_SoundBoard

## Sound board UI for testing and playing sound effects from AudioManager
## Displays sound effects organized by category in a grid layout
## Shows variation count and configurable pitch range for each effect

@onready var sound_grid_container: GridContainer = %SoundGridContainer
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var edit_mode_button: Button = %EditModeButton
@onready var save_button: Button = %SaveButton

var edit_mode: bool = false
var modified_configs: Dictionary = {} # Maps effect_value to modified config
var effect_edit_controls: Dictionary = {} # Maps effect_value to dict of edit controls

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
  
  # Edit controls container (hidden by default)
  var edit_container = VBoxContainer.new()
  edit_container.visible = false
  edit_container.add_theme_constant_override("separation", 3)
  
  # Pitch min control
  var pitch_min_container = HBoxContainer.new()
  var pitch_min_label = Label.new()
  pitch_min_label.text = "Min Pitch:"
  pitch_min_label.custom_minimum_size = Vector2(70, 0)
  pitch_min_container.add_child(pitch_min_label)
  var pitch_min_spinbox = SpinBox.new()
  pitch_min_spinbox.min_value = 0.0
  pitch_min_spinbox.max_value = 2.0
  pitch_min_spinbox.step = 0.1
  pitch_min_spinbox.value = config.pitch_variation_min
  pitch_min_spinbox.custom_minimum_size = Vector2(100, 0)
  pitch_min_spinbox.value_changed.connect(_on_config_value_changed.bind(effect_value, "pitch_min"))
  pitch_min_container.add_child(pitch_min_spinbox)
  edit_container.add_child(pitch_min_container)
  
  # Pitch max control
  var pitch_max_container = HBoxContainer.new()
  var pitch_max_label = Label.new()
  pitch_max_label.text = "Max Pitch:"
  pitch_max_label.custom_minimum_size = Vector2(70, 0)
  pitch_max_container.add_child(pitch_max_label)
  var pitch_max_spinbox = SpinBox.new()
  pitch_max_spinbox.min_value = 0.0
  pitch_max_spinbox.max_value = 2.0
  pitch_max_spinbox.step = 0.1
  pitch_max_spinbox.value = config.pitch_variation_max
  pitch_max_spinbox.custom_minimum_size = Vector2(100, 0)
  pitch_max_spinbox.value_changed.connect(_on_config_value_changed.bind(effect_value, "pitch_max"))
  pitch_max_container.add_child(pitch_max_spinbox)
  edit_container.add_child(pitch_max_container)
  
  # Volume control
  var volume_container = HBoxContainer.new()
  var volume_label = Label.new()
  volume_label.text = "Volume:"
  volume_label.custom_minimum_size = Vector2(70, 0)
  volume_container.add_child(volume_label)
  var volume_spinbox = SpinBox.new()
  volume_spinbox.min_value = -80.0
  volume_spinbox.max_value = 24.0
  volume_spinbox.step = 0.1
  volume_spinbox.value = config.volume_db
  volume_spinbox.custom_minimum_size = Vector2(100, 0)
  volume_spinbox.suffix = " dB"
  volume_spinbox.value_changed.connect(_on_config_value_changed.bind(effect_value, "volume"))
  volume_container.add_child(volume_spinbox)
  edit_container.add_child(volume_container)
  
  # Category control
  var category_container = HBoxContainer.new()
  var category_label = Label.new()
  category_label.text = "Category:"
  category_label.custom_minimum_size = Vector2(70, 0)
  category_container.add_child(category_label)
  var category_option = OptionButton.new()
  category_option.custom_minimum_size = Vector2(140, 0)
  for cat in Resource_SoundEffect.SoundCategory.values():
    var cat_name = Resource_SoundEffect.SoundCategory.keys()[cat]
    category_option.add_item(cat_name.capitalize().replace("_", " "), cat)
  category_option.selected = config.category
  category_option.item_selected.connect(_on_category_changed.bind(effect_value))
  category_container.add_child(category_option)
  edit_container.add_child(category_container)
  
  button_container.add_child(edit_container)
  
  # Store references to edit controls
  effect_edit_controls[effect_value] = {
    "container": edit_container,
    "pitch_min": pitch_min_spinbox,
    "pitch_max": pitch_max_spinbox,
    "volume": volume_spinbox,
    "category": category_option,
    "info_label": info_label,
    "button": button
  }
  
  # Spacing
  var spacer = Control.new()
  spacer.custom_minimum_size = Vector2(0, 5)
  button_container.add_child(spacer)
  
  return button_container

func _on_sound_button_pressed(effect: Resource_SoundEffect.SoundEffect, effect_name: String):
  MyLogger.info("SoundBoard", "Playing sound effect: %s" % effect_name)
  AudioManager.play_sound(audio_player, effect)

func _on_edit_mode_toggled(button_pressed: bool):
  edit_mode = button_pressed
  MyLogger.info("SoundBoard", "Edit mode toggled: %s" % ("ON" if edit_mode else "OFF"))
  
  # Show/hide edit controls for all effects
  for effect_value in effect_edit_controls:
    var controls = effect_edit_controls[effect_value]
    controls["container"].visible = edit_mode

func _on_config_value_changed(new_value: float, effect_value: Resource_SoundEffect.SoundEffect, property: String):
  # Get or create modified config
  if effect_value not in modified_configs:
    var original_config = AudioManager.get_effect_config(effect_value)
    # Use the original resource directly so it retains its path for saving
    modified_configs[effect_value] = original_config
  
  var config = modified_configs[effect_value]
  
  # Update the property
  match property:
    "pitch_min":
      config.pitch_variation_min = new_value
    "pitch_max":
      config.pitch_variation_max = new_value
    "volume":
      config.volume_db = new_value
  
  # Update info label
  _update_info_label(effect_value, config)
  
  # Enable save button
  save_button.disabled = false
  
  MyLogger.debug("SoundBoard", "Modified %s: %s = %s" % [effect_value, property, new_value])

func _on_category_changed(index: int, effect_value: Resource_SoundEffect.SoundEffect):
  # Get or create modified config
  if effect_value not in modified_configs:
    var original_config = AudioManager.get_effect_config(effect_value)
    # Use the original resource directly so it retains its path for saving
    modified_configs[effect_value] = original_config
  
  var config = modified_configs[effect_value]
  config.category = index
  
  # Enable save button
  save_button.disabled = false
  
  MyLogger.debug("SoundBoard", "Modified category for %s: %s" % [effect_value, index])

func _update_info_label(effect_value: Resource_SoundEffect.SoundEffect, config: Resource_SoundEffect):
  if effect_value not in effect_edit_controls:
    return
  
  var controls = effect_edit_controls[effect_value]
  var info_label = controls["info_label"]
  var button = controls["button"]
  
  var variation_count = config.samples.size()
  var pitch_info = "Pitch: %.1f - %.1f" % [config.pitch_variation_min, config.pitch_variation_max]
  var db_info = "Volume: %.1f dB" % config.volume_db
  info_label.text = "%d variation%s | %s | %s" % [
    variation_count,
    "s" if variation_count != 1 else "",
    pitch_info,
    db_info
  ]
  
  # Mark as modified
  if effect_value in modified_configs:
    button.modulate = Color(1.0, 1.0, 0.7) # Yellow tint for modified
  else:
    button.modulate = Color(1.0, 1.0, 1.0) # Normal color

func _on_save_button_pressed():
  MyLogger.info("SoundBoard", "Saving %d modified sound effects..." % modified_configs.size())
  
  var saved_count = 0
  var failed_count = 0
  
  for effect_value in modified_configs:
    var config = modified_configs[effect_value]
    
    # Validate pitch range before saving
    if config.pitch_variation_min > config.pitch_variation_max:
      MyLogger.warn("SoundBoard", "Skipping save for %s: pitch_min (%s) > pitch_max (%s)" % 
        [effect_value, config.pitch_variation_min, config.pitch_variation_max])
      failed_count += 1
      continue
    
    if _save_sound_effect_config(effect_value, config):
      saved_count += 1
      # Update AudioManager's copy
      AudioManager.sound_effect_configs[effect_value] = config
    else:
      failed_count += 1
  
  # Clear modified list and disable save button
  modified_configs.clear()
  save_button.disabled = true
  
  # Reset button colors
  for effect_value in effect_edit_controls:
    effect_edit_controls[effect_value]["button"].modulate = Color(1.0, 1.0, 1.0)
  
  if failed_count > 0:
    MyLogger.warn("SoundBoard", "Save complete: %d succeeded, %d failed" % [saved_count, failed_count])
  else:
    MyLogger.info("SoundBoard", "Save complete: %d succeeded, %d failed" % [saved_count, failed_count])

func _save_sound_effect_config(effect_value: Resource_SoundEffect.SoundEffect, config: Resource_SoundEffect) -> bool:
  # Determine the file path based on effect name
  var effect_name = ""
  for key in Resource_SoundEffect.SoundEffect.keys():
    if Resource_SoundEffect.SoundEffect[key] == effect_value:
      effect_name = key.to_lower()
      break
  
  if effect_name == "":
    MyLogger.error("SoundBoard", "Could not find effect name for value: %s" % effect_value)
    return false
  
  var file_path = "res://Config/SoundEffects/%s.tres" % effect_name
  
  # Save the resource
  var err = ResourceSaver.save(config, file_path)
  if err != OK:
    MyLogger.error("SoundBoard", "Failed to save %s: Error %d" % [file_path, err])
    return false
  
  MyLogger.info("SoundBoard", "Saved: %s" % file_path)
  return true

func _on_close_button_pressed():
  MyLogger.info("SoundBoard", "Close button pressed")
  get_tree().quit()
