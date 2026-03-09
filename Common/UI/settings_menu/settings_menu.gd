extends Control
class_name UI_SettingsMenu

## Settings Menu UI
## Provides interface for adjusting video, audio, and input settings

signal closed()

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer

# Video tab controls
@onready var fullscreen_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Video/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var vsync_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Video/VBoxContainer/VsyncContainer/VsyncCheck
@onready var resolution_option: OptionButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Video/VBoxContainer/ResolutionContainer/ResolutionOption

# Audio tab controls
@onready var master_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterContainer/MasterSlider
@onready var master_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MasterContainer/MasterLabel
@onready var music_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicContainer/MusicSlider
@onready var music_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicContainer/MusicLabel
@onready var sfx_slider: HSlider = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SFXContainer/SFXSlider
@onready var sfx_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/SFXContainer/SFXLabel
@onready var music_pause_label: Label = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicPauseContainer/MusicPauseLabel
@onready var music_pause_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Audio/VBoxContainer/MusicPauseContainer/MusicPauseCheck

# Keybinds tab controls
@onready var keybinds_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/TabContainer/Keybinds/ScrollContainer/KeybindsContainer

# Debug tab controls
@onready var debug_check: CheckButton = $Panel/MarginContainer/VBoxContainer/TabContainer/Debug/VBoxContainer/DebugModeContainer/DebugModeCheck

# Bottom buttons
@onready var apply_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/ApplyButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

# Twitch settings UI elements
@onready var twitch_auth_button: Button = %TwitchAuthButton
@onready var twitch_status_label: Label = %TwitchStatusLabel
@onready var twitch_enabled_check: CheckButton = %TwitchEnabledCheckButton

# Keybind button scene
const KeybindButtonScene = preload("res://Common/UI/settings_menu/keybind_button.tscn")
const VideoConfirmDialogScene = preload("res://Common/UI/settings_menu/video_confirm_dialog.tscn")

# Temporary settings storage
var temp_fullscreen: bool
var temp_vsync: bool
var temp_resolution: int
var temp_master_volume: float
var temp_music_volume: float
var temp_sfx_volume: float
var temp_music_pause: bool
var temp_twitch_enabled: bool

# Store original keybinds to restore on cancel
var original_keybinds: Dictionary = {}

# Previous video settings for revert
var previous_fullscreen: bool
var previous_vsync: bool
var previous_resolution: int

# Previous audio settings for revert
var previous_master_volume: float
var previous_music_volume: float
var previous_sfx_volume: float
var previous_music_pause: bool
var previous_twitch_enabled: bool

# Video confirmation dialog
var video_confirm_dialog = null

func _ready() -> void:
  # Hide by default
  visible = false
  
  # Create video confirmation dialog
  video_confirm_dialog = VideoConfirmDialogScene.instantiate()
  add_child(video_confirm_dialog)
  video_confirm_dialog.settings_confirmed.connect(_on_video_settings_confirmed)
  video_confirm_dialog.settings_reverted.connect(_on_video_settings_reverted)
  
  # Setup resolution options
  _setup_resolution_options()
  
  # Setup keybind buttons
  _setup_keybind_buttons()

  # Setup Twitch status
  _update_twitch_status()
  
  # Connect signals
  _connect_signals()


func _connect_signals() -> void:
  # Video settings
  fullscreen_check.toggled.connect(_on_fullscreen_toggled)
  vsync_check.toggled.connect(_on_vsync_toggled)
  resolution_option.item_selected.connect(_on_resolution_selected)
  
  # Audio settings
  master_slider.value_changed.connect(_on_master_volume_changed)
  music_slider.value_changed.connect(_on_music_volume_changed)
  sfx_slider.value_changed.connect(_on_sfx_volume_changed)
  music_pause_check.toggled.connect(_on_music_pause_toggled)
  
  # Bottom buttons
  apply_button.pressed.connect(_on_apply_pressed)
  cancel_button.pressed.connect(_on_cancel_pressed)

  # Twitch settings
  twitch_enabled_check.toggled.connect(_on_twitch_enabled_toggled)
  twitch_auth_button.pressed.connect(_on_twitch_auth_pressed)
  if SettingsManager.twitch_enabled and is_instance_valid(Twitch.auth):
    Twitch.auth.unauthenticated.connect(_on_twitch_unauthenticated)
  
  # Debug settings
  debug_check.toggled.connect(_on_debug_mode_toggled)

func _setup_resolution_options() -> void:
  resolution_option.clear()
  for i in range(SettingsManager.RESOLUTIONS.size()):
    var res_string = SettingsManager.get_resolution_string(i)
    resolution_option.add_item(res_string, i)

func _setup_keybind_buttons() -> void:
  # Get all input actions
  var actions = InputMap.get_actions()
  
  for action in actions:
    # Skip UI actions and built-in actions
    if action.begins_with("ui_") or action.begins_with("spatial_editor"):
      continue
    
    # Create keybind button for this action
    var keybind_button = KeybindButtonScene.instantiate()
    keybind_button.action_name = action
    keybinds_container.add_child(keybind_button)

func show_menu() -> void:
  visible = true
  _load_current_settings()
  _store_original_keybinds()
  
  # Focus the first tab
  if tab_container:
    tab_container.current_tab = 0

func hide_menu() -> void:
  visible = false

func _load_current_settings() -> void:
  # Load from SettingsManager into temporary variables
  temp_fullscreen = SettingsManager.fullscreen
  temp_vsync = SettingsManager.vsync_enabled
  temp_resolution = SettingsManager.resolution_index
  temp_master_volume = SettingsManager.master_volume
  temp_music_volume = SettingsManager.music_volume
  temp_sfx_volume = SettingsManager.sfx_volume
  temp_music_pause = SettingsManager.music_pause
  temp_twitch_enabled = SettingsManager.twitch_enabled

  # Save original settings for potential revert
  previous_fullscreen = temp_fullscreen
  previous_vsync = temp_vsync
  previous_resolution = temp_resolution
  previous_master_volume = temp_master_volume
  previous_music_volume = temp_music_volume
  previous_sfx_volume = temp_sfx_volume
  previous_music_pause = temp_music_pause
  previous_twitch_enabled = temp_twitch_enabled

  # Update UI controls
  fullscreen_check.button_pressed = temp_fullscreen
  vsync_check.button_pressed = temp_vsync
  resolution_option.selected = temp_resolution
  
  # Audio sliders (convert dB to 0-100 range)
  master_slider.value = _db_to_percentage(temp_master_volume)
  music_slider.value = _db_to_percentage(temp_music_volume)
  sfx_slider.value = _db_to_percentage(temp_sfx_volume)
  music_pause_check.button_pressed = temp_music_pause
  
  # Debug settings
  debug_check.button_pressed = SettingsManager.debug_mode

  # Twitch settings
  twitch_enabled_check.button_pressed = temp_twitch_enabled
  
  _update_volume_labels()

func _db_to_percentage(db: float) -> float:
  return db_to_linear(db) * 100.0

func _percentage_to_db(percentage: float) -> float:
  return linear_to_db(percentage / 100.0)

func _update_volume_labels() -> void:
  master_label.text = "Master: %d%%" % int(master_slider.value)
  music_label.text = "Music: %d%%" % int(music_slider.value)
  sfx_label.text = "SFX: %d%%" % int(sfx_slider.value)

func _on_fullscreen_toggled(pressed: bool) -> void:
  temp_fullscreen = pressed

func _on_vsync_toggled(pressed: bool) -> void:
  temp_vsync = pressed

func _on_resolution_selected(index: int) -> void:
  temp_resolution = index

func _on_master_volume_changed(value: float) -> void:
  temp_master_volume = _percentage_to_db(value)
  # immediately change the master volume for instant feedback
  SettingsManager.master_volume = temp_master_volume
  SettingsManager.apply_audio_settings()
  _update_volume_labels()

func _on_music_volume_changed(value: float) -> void:
  temp_music_volume = _percentage_to_db(value)
  # immediately change the music volume for instant feedback
  SettingsManager.music_volume = temp_music_volume
  SettingsManager.apply_audio_settings()
  _update_volume_labels()

func _on_sfx_volume_changed(value: float) -> void:
  temp_sfx_volume = _percentage_to_db(value)
  # immediately change the SFX volume for instant feedback
  SettingsManager.sfx_volume = temp_sfx_volume
  SettingsManager.apply_audio_settings()
  _update_volume_labels()

func _on_music_pause_toggled(pressed: bool) -> void:
  temp_music_pause = pressed
  SettingsManager.music_pause = temp_music_pause
  SettingsManager.apply_audio_settings()

func _on_twitch_unauthenticated() -> void:
  MyLogger.warning("SettingsMenu", "Twitch token lost - re-authentication required")
  twitch_status_label.text = "Twitch: Disconnected"
  twitch_auth_button.disabled = false

func _on_twitch_enabled_toggled(pressed: bool) -> void:
  temp_twitch_enabled = pressed
  SettingsManager.twitch_enabled = temp_twitch_enabled
  _update_twitch_status()

func _on_twitch_auth_pressed() -> void:
  # Start Twitch authentication process
  MyLogger.info("SettingsMenu", "Starting Twitch authentication process")

  # Disable the auth button while authenticating to prevent multiple clicks
  twitch_auth_button.disabled = true
  twitch_status_label.text = "Twitch: Authenticating..."

  var setup_successful: bool = await Twitch.setup()

  if setup_successful:
    MyLogger.info("SettingsMenu", "Twitch authentication successful")
    twitch_status_label.text = "Twitch: Connected"
    twitch_auth_button.disabled = true
  else:
    MyLogger.warning("SettingsMenu", "Twitch authentication failed")
    twitch_status_label.text = "Twitch: Connection Failed"
    twitch_auth_button.disabled = false

func _update_twitch_status() -> void:
  if not SettingsManager.twitch_enabled:
    twitch_status_label.text = "Twitch: Disabled"
    twitch_auth_button.disabled = true
  elif Twitch.auth.is_authenticated:
    var display_name: String = await _get_twitch_display_name()
    if display_name.is_empty():
      twitch_status_label.text = "Twitch: Connected (unknown user)"
    else:
      twitch_status_label.text = "Twitch: Connected as %s" % display_name
    twitch_auth_button.disabled = true
  else:
    twitch_status_label.text = "Twitch: Not Connected"
    twitch_auth_button.disabled = false

func _get_twitch_display_name() -> String:
  var current_user: TwitchUser = await Twitch.get_current_user()
  if is_instance_valid(current_user) and not current_user.display_name.is_empty():
    return current_user.display_name
  return ""

func _on_debug_mode_toggled(pressed: bool) -> void:
  SettingsManager.set_debug_mode(pressed)

func _on_apply_pressed() -> void:
  # Check if video settings changed
  var video_settings_changed = (
    temp_fullscreen != SettingsManager.fullscreen or
    temp_vsync != SettingsManager.vsync_enabled or
    temp_resolution != SettingsManager.resolution_index
  )
  
  # Apply audio settings immediately (no confirmation needed)
  SettingsManager.master_volume = temp_master_volume
  SettingsManager.music_volume = temp_music_volume
  SettingsManager.sfx_volume = temp_sfx_volume
  SettingsManager.music_pause = temp_music_pause
  SettingsManager.apply_audio_settings()
  
  if video_settings_changed:
    # Apply video settings
    SettingsManager.fullscreen = temp_fullscreen
    SettingsManager.vsync_enabled = temp_vsync
    SettingsManager.resolution_index = temp_resolution
    SettingsManager.apply_video_settings()
    
    # Show confirmation dialog for video settings
    MyLogger.info("SettingsMenu", "Video settings changed, showing confirmation dialog")
    video_confirm_dialog.show_dialog()
  else:
    # No video changes, just save and close
    SettingsManager.save_settings()
    MyLogger.info("SettingsMenu", "Settings applied and saved")
    hide_menu()
    closed.emit()

func _on_cancel_pressed() -> void:
  MyLogger.debug("SettingsMenu", "Settings cancelled")
  _restore_original_keybinds()
  _restore_original_settings()
  hide_menu()
  closed.emit()

func _on_video_settings_confirmed() -> void:
  # User confirmed the video settings, save everything
  SettingsManager.save_settings()
  MyLogger.info("SettingsMenu", "Video settings confirmed and saved")
  hide_menu()
  closed.emit()

func _on_video_settings_reverted() -> void:
  # User rejected or timeout - revert video settings
  SettingsManager.fullscreen = previous_fullscreen
  SettingsManager.vsync_enabled = previous_vsync
  SettingsManager.resolution_index = previous_resolution
  SettingsManager.apply_video_settings()
  
  # Update temp settings to match reverted state
  temp_fullscreen = previous_fullscreen
  temp_vsync = previous_vsync
  temp_resolution = previous_resolution
  
  # Update UI to reflect reverted settings
  fullscreen_check.button_pressed = temp_fullscreen
  vsync_check.button_pressed = temp_vsync
  resolution_option.selected = temp_resolution
  
  MyLogger.info("SettingsMenu", "Video settings reverted to previous state")
  
  # Audio settings were already applied, so save those
  SettingsManager.save_settings()
  hide_menu()
  closed.emit()

func _store_original_keybinds() -> void:
  # Store the current keybinds so we can restore them if user cancels
  original_keybinds.clear()
  var actions = InputMap.get_actions()
  
  for action in actions:
    # Skip UI actions and built-in actions
    if action.begins_with("ui_") or action.begins_with("spatial_editor"):
      continue
    
    # Store a copy of all events for this action
    var events = InputMap.action_get_events(action)
    var events_copy = []
    for event in events:
      events_copy.append(event.duplicate())
    original_keybinds[action] = events_copy

func _restore_original_keybinds() -> void:
  # Restore keybinds to their original state
  for action in original_keybinds.keys():
    # Clear current bindings
    InputMap.action_erase_events(action)
    
    # Restore original bindings
    for event in original_keybinds[action]:
      InputMap.action_add_event(action, event)
  
  # Update the display of all keybind buttons
  if keybinds_container:
    for child in keybinds_container.get_children():
      if child.has_method("_update_display"):
        child._update_display()
  
  MyLogger.debug("SettingsMenu", "Keybinds restored to original state")

func _restore_original_settings() -> void:
  SettingsManager.master_volume = previous_master_volume
  SettingsManager.music_volume = previous_music_volume
  SettingsManager.sfx_volume = previous_sfx_volume
  SettingsManager.music_pause = previous_music_pause
  SettingsManager.apply_audio_settings()

  SettingsManager.fullscreen = previous_fullscreen
  SettingsManager.vsync_enabled = previous_vsync
  SettingsManager.resolution_index = previous_resolution
  # no need to apply video settings here since we will
  # revert to the previous settings immediately in the
  # video settings revert function

  SettingsManager.twitch_enabled = previous_twitch_enabled
