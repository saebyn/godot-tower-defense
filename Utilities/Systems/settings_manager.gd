extends Node

## SettingsManager - Manages game settings and persistence
##
## Handles video, audio, and input settings with automatic save/load functionality

signal settings_changed()
signal video_settings_changed()
signal audio_settings_changed()

const SETTINGS_FILE = "user://settings.cfg"

# Video settings
var fullscreen: bool = false
var vsync_enabled: bool = true
var resolution_index: int = 2  # Default to 1920x1080

# Audio settings (in dB, range -80 to 0)
var master_volume: float = 0.0
var music_volume: float = 0.0
var sfx_volume: float = 0.0

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
  apply_settings()
  Logger.info("SettingsManager", "Settings Manager initialized")

## Load settings from file
func load_settings() -> void:
  var config = ConfigFile.new()
  var err = config.load(SETTINGS_FILE)
  
  if err != OK:
    Logger.info("SettingsManager", "No settings file found, using defaults")
    return
  
  # Load video settings
  fullscreen = config.get_value("video", "fullscreen", fullscreen)
  vsync_enabled = config.get_value("video", "vsync_enabled", vsync_enabled)
  resolution_index = config.get_value("video", "resolution_index", resolution_index)
  
  # Load audio settings
  master_volume = config.get_value("audio", "master_volume", master_volume)
  music_volume = config.get_value("audio", "music_volume", music_volume)
  sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
  
  Logger.info("SettingsManager", "Settings loaded from file")

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
  
  var err = config.save(SETTINGS_FILE)
  if err != OK:
    Logger.error("SettingsManager", "Failed to save settings: %d" % err)
  else:
    Logger.info("SettingsManager", "Settings saved to file")

## Apply all current settings
func apply_settings() -> void:
  apply_video_settings()
  apply_audio_settings()
  settings_changed.emit()

## Apply video settings
func apply_video_settings() -> void:
  var window = get_window()
  
  # Apply fullscreen
  if fullscreen:
    window.mode = Window.MODE_FULLSCREEN
  else:
    window.mode = Window.MODE_WINDOWED
  
  # Apply vsync
  if vsync_enabled:
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
  else:
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
  
  # Apply resolution (only for windowed mode)
  if not fullscreen and resolution_index >= 0 and resolution_index < RESOLUTIONS.size():
    var res = RESOLUTIONS[resolution_index]
    window.size = res
    # Center window
    var screen_size = DisplayServer.screen_get_size()
    var window_size = window.size
    window.position = (screen_size - window_size) / 2
  
  video_settings_changed.emit()
  Logger.debug("SettingsManager", "Video settings applied")

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
  Logger.debug("SettingsManager", "Audio settings applied")

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

## Get resolution string for display
func get_resolution_string(index: int) -> String:
  if index >= 0 and index < RESOLUTIONS.size():
    var res = RESOLUTIONS[index]
    return "%dx%d" % [res.x, res.y]
  return "Unknown"

## Convert volume from dB to linear (0.0 to 1.0)
func db_to_linear(db: float) -> float:
  return db_to_linear(db)

## Convert volume from linear (0.0 to 1.0) to dB
func linear_to_db(linear: float) -> float:
  return linear_to_db(linear)
