# Settings System Usage Examples

## For Developers: Using SettingsManager in Your Code

The SettingsManager is a global singleton accessible from any script in the game.

### Reading Settings

```gdscript
# Check if game is in fullscreen
if SettingsManager.fullscreen:
    print("Game is in fullscreen mode")

# Get current resolution index
var res_idx = SettingsManager.resolution_index
print("Current resolution: ", SettingsManager.get_resolution_string(res_idx))

# Check audio volumes
print("Master volume: ", SettingsManager.master_volume, " dB")
print("Music volume: ", SettingsManager.music_volume, " dB")
print("SFX volume: ", SettingsManager.sfx_volume, " dB")
```

### Changing Settings Programmatically

```gdscript
# Toggle fullscreen
SettingsManager.set_fullscreen(true)

# Change resolution
SettingsManager.set_resolution(2)  # 1920x1080

# Adjust volumes
SettingsManager.set_master_volume(-10.0)  # -10 dB
SettingsManager.set_music_volume(-20.0)   # -20 dB
SettingsManager.set_sfx_volume(0.0)       # 0 dB (max)
```

### Listening to Settings Changes

```gdscript
extends Node

func _ready():
    # Connect to settings change signals
    SettingsManager.video_settings_changed.connect(_on_video_settings_changed)
    SettingsManager.audio_settings_changed.connect(_on_audio_settings_changed)
    SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_video_settings_changed():
    print("Video settings have changed!")
    # Update your game's graphics accordingly

func _on_audio_settings_changed():
    print("Audio settings have changed!")
    # Update audio mixing or effects

func _on_settings_changed():
    print("Some settings have changed!")
    # General settings update handler
```

## For Developers: Adding New Settings

### Adding a New Video Setting

1. Add the variable to SettingsManager:
```gdscript
# In settings_manager.gd
var shadow_quality: int = 2  # 0=low, 1=medium, 2=high
```

2. Add save/load logic:
```gdscript
# In load_settings()
shadow_quality = config.get_value("video", "shadow_quality", shadow_quality)

# In save_settings()
config.set_value("video", "shadow_quality", shadow_quality)
```

3. Add apply logic:
```gdscript
# In apply_video_settings()
# Apply shadow quality
match shadow_quality:
    0:
        RenderingServer.shadow_quality = RenderingServer.SHADOW_QUALITY_LOW
    1:
        RenderingServer.shadow_quality = RenderingServer.SHADOW_QUALITY_MEDIUM
    2:
        RenderingServer.shadow_quality = RenderingServer.SHADOW_QUALITY_HIGH
```

4. Add setter method:
```gdscript
func set_shadow_quality(quality: int) -> void:
    if shadow_quality != quality and quality >= 0 and quality <= 2:
        shadow_quality = quality
        apply_video_settings()
        save_settings()
```

5. Add UI control to settings_menu.tscn and connect it in settings_menu.gd

### Adding a New Audio Bus

1. Create the bus in `default_bus_layout.tres`

2. Add volume control in SettingsManager:
```gdscript
var ui_volume: float = 0.0

# In load_settings()
ui_volume = config.get_value("audio", "ui_volume", ui_volume)

# In save_settings()
config.set_value("audio", "ui_volume", ui_volume)

# In apply_audio_settings()
var ui_bus = AudioServer.get_bus_index("UI")
AudioServer.set_bus_volume_db(ui_bus, ui_volume)

# Add setter
func set_ui_volume(volume_db: float) -> void:
    ui_volume = clamp(volume_db, -80.0, 0.0)
    apply_audio_settings()
    save_settings()
```

3. Add slider to Audio tab in settings_menu.tscn

## For Players: Using the Settings Menu

### Changing Video Settings

1. Open Settings from Main Menu or Pause Menu
2. Ensure you're on the "Video" tab
3. To enable fullscreen:
   - Click the checkbox next to "Fullscreen"
   - Click "Apply" to confirm
4. To change resolution:
   - Click the Resolution dropdown
   - Select your desired resolution
   - Click "Apply" to confirm
5. To toggle V-Sync:
   - Click the checkbox next to "V-Sync"
   - Click "Apply" to confirm

**Note**: Resolution only applies in windowed mode. Fullscreen uses native resolution.

### Adjusting Audio Levels

1. Open Settings from Main Menu or Pause Menu
2. Click the "Audio" tab
3. Drag the sliders to adjust volumes:
   - **Master**: Overall game volume
   - **Music**: Background music volume
   - **SFX**: Sound effects volume
4. The percentage updates in real-time as you drag
5. Click "Apply" to save your changes
6. Click "Cancel" to discard changes

**Tips**:
- Start with Master at 100% and adjust Music/SFX relative to it
- If everything is too quiet, increase Master
- If music drowns out SFX, lower Music or increase SFX

### Rebinding Keys

1. Open Settings from Main Menu or Pause Menu
2. Click the "Keybinds" tab
3. Find the action you want to rebind
4. Click the button showing the current key
5. The button text changes to "Press any key..."
6. Press the key you want to bind
7. The button updates to show the new key
8. Repeat for other actions as needed
9. Click "Apply" to save all keybind changes
10. Click "Cancel" to discard changes

**Note**: Currently, keybinds are not persisted between sessions. This is a planned enhancement.

## Troubleshooting

### Settings Not Saving

If your settings aren't being saved:
1. Check that you clicked "Apply" not "Cancel"
2. Verify you have write permissions to the user data directory
3. Check the console for error messages from SettingsManager

### Resolution Not Changing

If resolution doesn't change:
1. Make sure you're not in fullscreen mode
2. Verify the resolution is supported by your monitor
3. Try a different resolution
4. Check console for errors

### Keybinds Not Working

If a rebound key doesn't work:
1. Make sure you clicked "Apply" after rebinding
2. Verify the key isn't being used by the OS
3. Try a different key
4. Restart the game to ensure changes take effect

### Audio Too Quiet/Loud

If audio levels aren't right:
1. Check Master volume first (should be near 100%)
2. Adjust individual buses (Music/SFX) relative to Master
3. Remember: 0% = silent, 100% = maximum
4. Audio uses logarithmic scale, so changes near 100% are more noticeable

## Advanced: Custom Settings Menu

If you want to create a custom settings interface:

```gdscript
extends Control

func _ready():
    # Create your custom UI
    var fullscreen_button = Button.new()
    fullscreen_button.text = "Toggle Fullscreen"
    fullscreen_button.pressed.connect(_toggle_fullscreen)
    add_child(fullscreen_button)

func _toggle_fullscreen():
    # Use SettingsManager directly
    SettingsManager.set_fullscreen(not SettingsManager.fullscreen)
    print("Fullscreen: ", SettingsManager.fullscreen)
```

The Settings Menu is just a UI layer over SettingsManager. You can create any custom interface you want and interact with SettingsManager directly.
