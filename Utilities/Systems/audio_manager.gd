extends Node

var sound_effect_configs: Dictionary[Resource_SoundEffect.SoundEffect, Resource_SoundEffect] = {}

var sfx_directory: String = "res://Config/SoundEffects/"
var sfx_resource_extension: String = ".tres"

# UI audio player for non-spatial sounds (buttons, menus, etc.)
var ui_audio_player: AudioStreamPlayer


func _ready() -> void:
  # Create UI audio player
  ui_audio_player = AudioStreamPlayer.new()
  ui_audio_player.bus = "Sound Effects"
  add_child(ui_audio_player)
  
  # load resources from config directory into sound_effect_configs
  var dir = DirAccess.open(sfx_directory)
  if not dir:
    MyLogger.error("AudioManager", "Could not open sound effects directory: %s" % sfx_directory)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  while file_name != "":
    if file_name.ends_with(sfx_resource_extension):
      var file_path = sfx_directory + file_name
      var resource = ResourceLoader.load(file_path)
      if resource and resource is Resource_SoundEffect:
        sound_effect_configs[resource.get("sound_effect")] = resource
        MyLogger.debug("AudioManager", "Loaded sound effect: %s" % str(resource.get("sound_effect")))
      else:
        MyLogger.warn("AudioManager", "Failed to load sound effect from: %s" % file_path)

    file_name = dir.get_next()
  dir.list_dir_end()
  
  # Connect to scene tree to automatically handle UI sounds
  get_tree().node_added.connect(_on_node_added)


## Automatically connect to buttons added to the scene tree
func _on_node_added(node: Node) -> void:
  # Handle all Button types (Button, CheckButton, etc.)
  if node is BaseButton:
    # Connect to pressed signal for click sound
    if not node.pressed.is_connected(_on_button_pressed):
      node.pressed.connect(_on_button_pressed.bind(node))
    
    # Connect to mouse_entered for hover sound
    if not node.mouse_entered.is_connected(_on_button_hovered):
      node.mouse_entered.connect(_on_button_hovered.bind(node))


## Play sound when button is pressed
func _on_button_pressed(button: BaseButton) -> void:
  # Determine which sound to play based on button name/type
  var sound_effect = _get_button_sound_effect(button)
  play_sound_2d(sound_effect)


## Play sound when button is hovered
func _on_button_hovered(_button: BaseButton) -> void:
  play_sound_2d(Resource_SoundEffect.SoundEffect.UI_HOVER)


## Determine which sound effect to play for a button
func _get_button_sound_effect(button: BaseButton) -> Resource_SoundEffect.SoundEffect:
  var button_name = button.name.to_lower()
  var button_text = ""
  if button is Button:
    button_text = button.text.to_lower()
  
  # Check for cancel/close actions
  if button_name.contains("cancel") or button_name.contains("close") or button_name.contains("back"):
    return Resource_SoundEffect.SoundEffect.UI_CANCEL
  if button_text.contains("cancel") or button_text.contains("close") or button_text.contains("back"):
    return Resource_SoundEffect.SoundEffect.UI_CANCEL
  if button_name.contains("resume"):
    return Resource_SoundEffect.SoundEffect.UI_CANCEL
  
  # Check for delete/remove actions (could use ERROR sound)
  if button_name.contains("delete") or button_name.contains("remove"):
    return Resource_SoundEffect.SoundEffect.UI_CANCEL
  
  # Default to confirm sound for most buttons
  return Resource_SoundEffect.SoundEffect.UI_CONFIRM


## Play a spatial sound effect (3D positional audio)
func play_sound(audio_player: Variant, effect: Resource_SoundEffect.SoundEffect) -> void:
  var config: Resource_SoundEffect = null

  if effect == Resource_SoundEffect.SoundEffect.NONE:
    return

  if effect in sound_effect_configs:
    config = sound_effect_configs[effect]
  else:
    MyLogger.warn("AudioManager", "Sound effect %s not found in configurations!" % str(effect))
    config = sound_effect_configs.get(Resource_SoundEffect.SoundEffect.DEFAULT, null)

  if not config:
    MyLogger.error("AudioManager", "Default sound effect configuration missing!")
    return

  if config.samples.is_empty():
    MyLogger.warn("AudioManager", "No samples configured for effect %s" % str(effect))
    return

  var random_sample_index = randi() % config.samples.size()
  audio_player.stream = config.samples[random_sample_index]
  audio_player.pitch_scale = config.pitch_variation_min + randf() * (config.pitch_variation_max - config.pitch_variation_min)
  audio_player.play()


## Play a non-spatial sound effect (2D audio for UI, etc.)
func play_sound_2d(effect: Resource_SoundEffect.SoundEffect) -> void:
  var config: Resource_SoundEffect = null

  if effect == Resource_SoundEffect.SoundEffect.NONE:
    return

  if effect in sound_effect_configs:
    config = sound_effect_configs[effect]
  else:
    MyLogger.warn("AudioManager", "Sound effect %s not found in configurations!" % str(effect))
    config = sound_effect_configs.get(Resource_SoundEffect.SoundEffect.DEFAULT, null)

  if not config:
    MyLogger.error("AudioManager", "Default sound effect configuration missing!")
    return

  if config.samples.is_empty():
    MyLogger.warn("AudioManager", "No samples configured for effect %s" % str(effect))
    return

  var random_sample_index = randi() % config.samples.size()
  ui_audio_player.stream = config.samples[random_sample_index]
  ui_audio_player.pitch_scale = config.pitch_variation_min + randf() * (config.pitch_variation_max - config.pitch_variation_min)
  ui_audio_player.play()


## Get the configuration for a sound effect
func get_effect_config(effect: Resource_SoundEffect.SoundEffect) -> Resource_SoundEffect:
  return sound_effect_configs.get(effect, null)


## Get the category name as a string
func get_category_name(category: Resource_SoundEffect.SoundCategory) -> String:
  return Resource_SoundEffect.SoundCategory.keys()[category]