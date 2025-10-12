# Settings UI - Quick Reference

## What Was Added

### 🎮 New Singleton: SettingsManager
Global autoloaded system managing all game settings with automatic persistence.

**Location**: `Utilities/Systems/settings_manager.gd`

**Key Methods**:
- `set_fullscreen(bool)` - Toggle fullscreen mode
- `set_vsync(bool)` - Toggle V-Sync
- `set_resolution(int)` - Change window resolution
- `set_master_volume(float)` - Adjust master audio (-80 to 0 dB)
- `set_music_volume(float)` - Adjust music audio
- `set_sfx_volume(float)` - Adjust SFX audio

**Signals**:
- `settings_changed()` - Any setting changed
- `video_settings_changed()` - Video setting changed
- `audio_settings_changed()` - Audio setting changed

### 🎨 New UI: Settings Menu
Complete tabbed interface for adjusting game settings.

**Location**: `Common/UI/settings_menu/`

**Tabs**:
1. **Video** - Resolution, fullscreen, V-Sync
2. **Audio** - Master, Music, SFX sliders
3. **Keybinds** - Rebindable input actions

**Accessible From**:
- Main Menu → Settings button
- Pause Menu (ESC) → Settings button

### 🔧 Modified Files

**Main Menu** (`Stages/UI/main_menu/main_menu.gd`):
- Added settings menu instantiation
- Connected settings button to show menu

**Pause Menu** (`Stages/UI/pause_menu/pause_menu.gd` + `.tscn`):
- Added Settings button to UI
- Added settings menu instantiation
- Connected settings button to show menu

**Project Config** (`project.godot`):
- Registered SettingsManager as autoload

## File Structure

```
godot-tower-defense/
├── Utilities/Systems/
│   └── settings_manager.gd          (NEW - 170 lines)
├── Common/UI/settings_menu/
│   ├── settings_menu.tscn           (NEW - Settings UI scene)
│   ├── settings_menu.gd             (NEW - 189 lines)
│   ├── keybind_button.tscn          (NEW - Keybind component)
│   └── keybind_button.gd            (NEW - 67 lines)
├── Stages/UI/main_menu/
│   └── main_menu.gd                 (MODIFIED - +23 lines)
├── Stages/UI/pause_menu/
│   ├── pause_menu.gd                (MODIFIED - +22 lines)
│   └── pause_menu.tscn              (MODIFIED - +3 lines)
├── project.godot                    (MODIFIED - +1 line)
└── docs/
    ├── settings_ui_implementation.md     (NEW - Complete guide)
    ├── settings_ui_visual_guide.md       (NEW - Visual reference)
    └── settings_usage_examples.md        (NEW - Code examples)
```

## Settings Persistence

Settings are automatically saved to: `user://settings.cfg`

Example saved settings:
```ini
[video]
fullscreen=false
vsync_enabled=true
resolution_index=2

[audio]
master_volume=0.0
music_volume=0.0
sfx_volume=0.0
```

## Quick Usage Guide

### For Players

**Opening Settings**:
- Main Menu: Click "SETTINGS"
- In Game: Press ESC, then click "Settings"

**Changing Video**:
1. Go to Video tab
2. Toggle fullscreen/V-Sync checkboxes
3. Select resolution from dropdown
4. Click "Apply"

**Adjusting Audio**:
1. Go to Audio tab
2. Drag sliders to adjust volumes
3. Labels show percentage in real-time
4. Click "Apply"

**Rebinding Keys**:
1. Go to Keybinds tab
2. Click button next to action
3. Press new key
4. Click "Apply"

### For Developers

**Read a setting**:
```gdscript
if SettingsManager.fullscreen:
    print("Fullscreen enabled")
```

**Change a setting**:
```gdscript
SettingsManager.set_master_volume(-10.0)
```

**React to changes**:
```gdscript
func _ready():
    SettingsManager.video_settings_changed.connect(_on_video_changed)
```

## Testing the Implementation

Run these commands to verify:

```bash
# Check all files exist
ls -l Utilities/Systems/settings_manager.gd
ls -l Common/UI/settings_menu/

# Verify SettingsManager is registered
grep "SettingsManager=" project.godot

# Test in headless mode
./godot --headless --path . "res://Stages/UI/main_menu/main_menu.tscn"
```

Expected output:
```
[INFO] SettingsManager: No settings file found, using defaults
[INFO] SettingsManager: Settings Manager initialized
```

## What's Next?

Suggested enhancements for future iterations:
- [ ] Graphics quality presets (low/medium/high)
- [ ] Field of view (FOV) adjustment
- [ ] Mouse sensitivity settings
- [ ] Language/localization selection
- [ ] Accessibility options (colorblind modes, text size)
- [ ] Default keybind reset button
- [ ] Keybind conflict detection
- [ ] Persistent keybind saving
- [ ] More granular audio controls (dialogue, ambient)
- [ ] Advanced video options (anti-aliasing, shadows)

## Summary

✅ **Complete settings system implemented**
✅ **Accessible from main menu and pause menu**
✅ **Video, audio, and keybind settings**
✅ **Automatic persistence**
✅ **Clean, modular architecture**
✅ **Comprehensive documentation**
✅ **Ready for production use**

---

*For detailed information, see the documentation in the `docs/` folder.*
