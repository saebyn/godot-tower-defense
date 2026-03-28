extends Node

# Signal emitted when a sound effect is played (for debug/tracking purposes)
signal sound_played(effect: Resource_SoundEffect.SoundEffect)

var sound_effect_configs: Dictionary[Resource_SoundEffect.SoundEffect, Resource_SoundEffect] = {}

var sfx_directory: String = "res://Config/SoundEffects/"
var sfx_resource_extension: String = ".tres"

# UI audio player for non-spatial sounds (buttons, menus, etc.)
var ui_audio_player: AudioStreamPlayer

# Background music player (child node configured in audio_manager.tscn)
@onready var bg_music_player: AudioStreamPlayer = $BgMusicAudioStreamPlayer


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
  
  # Process existing nodes in the tree (handles main menu and any pre-loaded scenes)
  _process_existing_buttons(get_tree().root)
  
  # Apply initial music pause state and connect to settings changes
  _on_audio_settings_changed()
  SettingsManager.audio_settings_changed.connect(_on_audio_settings_changed)


## Recursively process existing buttons in the scene tree
func _process_existing_buttons(node: Node) -> void:
  # Process this node if it's a button
  if node is BaseButton:
    _on_node_added(node)
  
  # Recursively process children
  for child in node.get_children():
    _process_existing_buttons(child)


## Automatically connect to buttons added to the scene tree
## To skip auto-attachment, set metadata "skip_audio_manager" to true on the button
func _on_node_added(node: Node) -> void:
  # Handle all Button types (Button, CheckButton, etc.)
  if node is BaseButton:
    # Check if button has metadata to skip auto-attachment
    if node.get_meta("skip_audio_manager", false) == true:
      return
    
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
## If pitch_override is provided (not null), it will be used instead of the config's pitch variation
func play_sound(audio_player: Variant, effect: Resource_SoundEffect.SoundEffect, pitch_override: Variant = null) -> void:
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
  
  # Use pitch override if provided, otherwise use config's pitch variation
  if pitch_override != null:
    audio_player.pitch_scale = pitch_override
  else:
    audio_player.pitch_scale = config.pitch_variation_min + randf() * (config.pitch_variation_max - config.pitch_variation_min)
  
  audio_player.volume_db = config.volume_db
  audio_player.play()
  
  # Emit signal for sound effect tracking/debugging
  sound_played.emit(effect)


## Play a non-spatial sound effect (2D audio for UI, etc.)
func play_sound_2d(effect: Resource_SoundEffect.SoundEffect) -> void:
  play_sound(ui_audio_player, effect)


## Get the configuration for a sound effect
func get_effect_config(effect: Resource_SoundEffect.SoundEffect) -> Resource_SoundEffect:
  return sound_effect_configs.get(effect, null)


## Get the category name as a string
func get_category_name(category: Resource_SoundEffect.SoundCategory) -> String:
  return Resource_SoundEffect.SoundCategory.keys()[category]


## Start playing background music. Safe to call if already playing.
func play_background_music() -> void:
  if bg_music_player and not bg_music_player.playing:
    bg_music_player.play()
    MyLogger.info("AudioManager", "Background music started")


## Stop background music.
func stop_background_music() -> void:
  if bg_music_player and bg_music_player.playing:
    bg_music_player.stop()
    MyLogger.info("AudioManager", "Background music stopped")


## Apply the music pause mode based on current settings.
func _on_audio_settings_changed() -> void:
  if bg_music_player:
    bg_music_player.process_mode = Node.PROCESS_MODE_PAUSABLE if SettingsManager.music_pause else Node.PROCESS_MODE_ALWAYS
    MyLogger.debug("AudioManager", "Applied music pause setting: %s" % SettingsManager.music_pause)