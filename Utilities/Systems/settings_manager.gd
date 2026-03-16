extends Node

## SettingsManager - Manages game settings and persistence
##
## Handles video, audio, and input settings with automatic save/load functionality

signal video_settings_changed()
signal audio_settings_changed()
signal debug_mode_changed(enabled: bool)

const SETTINGS_FILE = "user://settings.cfg"

# Debug settings (runtime only, not persisted)
var debug_mode: bool = false:
  set(value):
    if debug_mode != value:
      debug_mode = value
      debug_mode_changed.emit(debug_mode)
      MyLogger.info("SettingsManager", "Debug mode %s" % ("enabled" if debug_mode else "disabled"))

# Video settings
var fullscreen: bool = false
var vsync_enabled: bool = true
var resolution_index: int = 2 # Default to 1920x1080

# Audio settings (in dB, range -80 to 0)
# Default master volume is -6.02 dB (50% volume)
var master_volume: float = -6.02
var music_volume: float = 0.0
var sfx_volume: float = 0.0
var music_pause: bool = false

# Twitch settings
var twitch_enabled: bool = false
var twitch_welcome_message: String = ""

# Available resolutions
const RESOLUTIONS: Array[Vector2i] = [
  Vector2i(1280, 720),
  Vector2i(1600, 900),
  Vector2i(1920, 1080),
  Vector2i(2560, 1440),
  Vector2i(3840, 2160)
]

func _ready() -> void:
  load_settings()
  apply_audio_settings()
  apply_video_settings()
  MyLogger.info("SettingsManager", "Settings Manager initialized")

## Load settings from file
func load_settings() -> void:
  var config = ConfigFile.new()
  var err = config.load(SETTINGS_FILE)
  
  if err != OK:
    MyLogger.info("SettingsManager", "No settings file found, using defaults")
    return
  
  # Load video settings
  fullscreen = config.get_value("video", "fullscreen", fullscreen)
  vsync_enabled = config.get_value("video", "vsync_enabled", vsync_enabled)
  resolution_index = config.get_value("video", "resolution_index", resolution_index)
  
  # Load audio settings
  master_volume = config.get_value("audio", "master_volume", master_volume)
  music_volume = config.get_value("audio", "music_volume", music_volume)
  sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
  music_pause = config.get_value("audio", "music_pause", music_pause)

  # Twitch settings
  twitch_enabled = config.get_value("twitch", "enabled", twitch_enabled)
  twitch_welcome_message = config.get_value("twitch", "welcome_message", twitch_welcome_message)
  
  # Load keybind settings
  _load_keybinds(config)
  
  MyLogger.info("SettingsManager", "Settings loaded from file")

## Save settings to file
func save_settings() -> void:
  var config = ConfigFile.new()
  
  # Save video settings
  config.set_value("video", "fullscreen", fullscreen)
  config.set_value("video", "vsync_enabled", vsync_enabled)
  config.set_value("video", "resolution_index", resolution_index)
  
  # Save audio settings
  config.set_value("audio", "master_volume", master_volume)
  config.set_value("audio", "music_volume", music_volume)
  config.set_value("audio", "sfx_volume", sfx_volume)
  config.set_value("audio", "music_pause", music_pause)

  # Save Twitch settings
  config.set_value("twitch", "enabled", twitch_enabled)
  config.set_value("twitch", "welcome_message", twitch_welcome_message)
  
  # Save keybind settings
  _save_keybinds(config)
  
  var err = config.save(SETTINGS_FILE)
  if err != OK:
    MyLogger.error("SettingsManager", "Failed to save settings: %d" % err)
  else:
    MyLogger.info("SettingsManager", "Settings saved to file")

## Apply all current settings
func apply_settings() -> void:
  apply_video_settings()
  apply_audio_settings()

## Apply video settings
func apply_video_settings() -> void:
  var window = get_tree().root
  
  # Apply vsync
  if vsync_enabled:
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
  else:
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

  # Skip window size/position changes when running in the editor's embedded window
  # The editor manages the embedded window size, and changing it causes layout issues
  if Engine.is_embedded_in_editor():
    MyLogger.debug("SettingsManager", "Running in editor - skipping window size/position changes")
  else:
    # Apply fullscreen
    if fullscreen:
      window.mode = Window.MODE_FULLSCREEN
    else:
      window.mode = Window.MODE_WINDOWED

    
    # Apply resolution (only for windowed mode)
    if not fullscreen and resolution_index >= 0 and resolution_index < RESOLUTIONS.size():
      var res = RESOLUTIONS[resolution_index]
      window.size = res
      # Center window
      var screen_size = DisplayServer.screen_get_size()
      var window_size = window.size
      window.position = (screen_size - window_size) / 2

    MyLogger.debug("SettingsManager", "Video settings applied")

  video_settings_changed.emit()


## Apply audio settings
func apply_audio_settings() -> void:
  var master_bus = AudioServer.get_bus_index("Master")
  var music_bus = AudioServer.get_bus_index("Music")
  var sfx_bus = AudioServer.get_bus_index("Sound Effects")
  
  # Apply volume levels
  AudioServer.set_bus_volume_db(master_bus, master_volume)
  AudioServer.set_bus_volume_db(music_bus, music_volume)
  AudioServer.set_bus_volume_db(sfx_bus, sfx_volume)
  
  audio_settings_changed.emit()
  MyLogger.debug("SettingsManager", "Audio settings applied")

## Set fullscreen mode
func set_fullscreen(enabled: bool) -> void:
  if fullscreen != enabled:
    fullscreen = enabled
    apply_video_settings()
    save_settings()

## Set vsync mode
func set_vsync(enabled: bool) -> void:
  if vsync_enabled != enabled:
    vsync_enabled = enabled
    apply_video_settings()
    save_settings()

## Set resolution by index
func set_resolution(index: int) -> void:
  if resolution_index != index and index >= 0 and index < RESOLUTIONS.size():
    resolution_index = index
    apply_video_settings()
    save_settings()

## Set master volume
func set_master_volume(volume_db: float) -> void:
  master_volume = clamp(volume_db, -80.0, 0.0)
  apply_audio_settings()
  save_settings()

## Set music volume
func set_music_volume(volume_db: float) -> void:
  music_volume = clamp(volume_db, -80.0, 0.0)
  apply_audio_settings()
  save_settings()

## Set sound effects volume
func set_sfx_volume(volume_db: float) -> void:
  sfx_volume = clamp(volume_db, -80.0, 0.0)
  apply_audio_settings()
  save_settings()

## Set debug mode (runtime only, not persisted)
func set_debug_mode(enabled: bool) -> void:
  debug_mode = enabled

## Set Twitch enabled
func set_twitch_enabled(enabled: bool) -> void:
  if twitch_enabled != enabled:
    twitch_enabled = enabled
    save_settings()

## Get resolution string for display
func get_resolution_string(index: int) -> String:
  if index >= 0 and index < RESOLUTIONS.size():
    var res = RESOLUTIONS[index]
    return "%dx%d" % [res.x, res.y]
  return "Unknown"

## Save keybind settings into an existing ConfigFile object
func _save_keybinds(config: ConfigFile) -> void:
  # get_actions() is called once per save; this is acceptable since save_settings()
  # is only invoked on explicit user action (Apply button, video confirmation, etc.)
  var actions = InputMap.get_actions()
  for action in actions:
    if action.begins_with("ui_") or action.begins_with("spatial_editor"):
      continue
    var events = InputMap.action_get_events(action)
    if events.size() == 0:
      continue
    var bindings: Array = []
    for event in events:
      if event is InputEventKey:
        bindings.append({
          "type": "key",
          "physical_keycode": event.physical_keycode,
          "ctrl_pressed": event.ctrl_pressed,
          "alt_pressed": event.alt_pressed,
          "shift_pressed": event.shift_pressed,
          "meta_pressed": event.meta_pressed,
          "command_or_control_autoremap": event.command_or_control_autoremap
        })
      elif event is InputEventMouseButton:
        bindings.append({
          "type": "mouse",
          "button_index": int(event.button_index)
        })
    if not bindings.is_empty():
      config.set_value("keybinds", action, bindings)

## Load keybind settings from a ConfigFile object and apply them to InputMap
func _load_keybinds(config: ConfigFile) -> void:
  if not config.has_section("keybinds"):
    return
  for action in config.get_section_keys("keybinds"):
    if not InputMap.has_action(action):
      continue
    var bindings: Array = config.get_value("keybinds", action, [])
    if bindings.is_empty():
      continue
    InputMap.action_erase_events(action)
    for binding_data in bindings:
      var event: InputEvent = null
      if binding_data.get("type") == "key":
        var key_event = InputEventKey.new()
        key_event.physical_keycode = binding_data.get("physical_keycode", 0)
        key_event.ctrl_pressed = binding_data.get("ctrl_pressed", false)
        key_event.alt_pressed = binding_data.get("alt_pressed", false)
        key_event.shift_pressed = binding_data.get("shift_pressed", false)
        key_event.meta_pressed = binding_data.get("meta_pressed", false)
        key_event.command_or_control_autoremap = binding_data.get("command_or_control_autoremap", false)
        event = key_event
      elif binding_data.get("type") == "mouse":
        var mouse_event = InputEventMouseButton.new()
        mouse_event.button_index = binding_data.get("button_index", MOUSE_BUTTON_LEFT)
        event = mouse_event
      if event != null:
        InputMap.action_add_event(action, event)
  MyLogger.info("SettingsManager", "Keybinds loaded from file")
