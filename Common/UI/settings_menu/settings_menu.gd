extends Control
class_name SettingsMenu

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

# Keybinds tab controls
@onready var keybinds_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/TabContainer/Keybinds/ScrollContainer/KeybindsContainer

# Bottom buttons
@onready var apply_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/ApplyButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

# Keybind button scene
const KeybindButtonScene = preload("res://Common/UI/settings_menu/keybind_button.tscn")

# Temporary settings storage
var temp_fullscreen: bool
var temp_vsync: bool
var temp_resolution: int
var temp_master_volume: float
var temp_music_volume: float
var temp_sfx_volume: float

func _ready() -> void:
  # Hide by default
  visible = false
  
  # Setup resolution options
  _setup_resolution_options()
  
  # Setup keybind buttons
  _setup_keybind_buttons()
  
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
  
  # Bottom buttons
  apply_button.pressed.connect(_on_apply_pressed)
  cancel_button.pressed.connect(_on_cancel_pressed)

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
  
  # Update UI controls
  fullscreen_check.button_pressed = temp_fullscreen
  vsync_check.button_pressed = temp_vsync
  resolution_option.selected = temp_resolution
  
  # Audio sliders (convert dB to 0-100 range)
  master_slider.value = _db_to_percentage(temp_master_volume)
  music_slider.value = _db_to_percentage(temp_music_volume)
  sfx_slider.value = _db_to_percentage(temp_sfx_volume)
  
  _update_volume_labels()

func _db_to_percentage(db: float) -> float:
  # Convert dB (-80 to 0) to percentage (0 to 100)
  return (db + 80.0) * 100.0 / 80.0

func _percentage_to_db(percentage: float) -> float:
  # Convert percentage (0 to 100) to dB (-80 to 0)
  return (percentage * 80.0 / 100.0) - 80.0

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
  _update_volume_labels()

func _on_music_volume_changed(value: float) -> void:
  temp_music_volume = _percentage_to_db(value)
  _update_volume_labels()

func _on_sfx_volume_changed(value: float) -> void:
  temp_sfx_volume = _percentage_to_db(value)
  _update_volume_labels()

func _on_apply_pressed() -> void:
  # Apply all settings
  SettingsManager.fullscreen = temp_fullscreen
  SettingsManager.vsync_enabled = temp_vsync
  SettingsManager.resolution_index = temp_resolution
  SettingsManager.master_volume = temp_master_volume
  SettingsManager.music_volume = temp_music_volume
  SettingsManager.sfx_volume = temp_sfx_volume
  
  SettingsManager.apply_settings()
  SettingsManager.save_settings()
  
  Logger.info("SettingsMenu", "Settings applied and saved")
  
  hide_menu()
  closed.emit()

func _on_cancel_pressed() -> void:
  Logger.debug("SettingsMenu", "Settings cancelled")
  hide_menu()
  closed.emit()
