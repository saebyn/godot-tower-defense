# Settings UI Implementation

## Overview
This implementation adds a comprehensive settings UI accessible from both the main menu and pause menu, with support for video, audio, and keybind settings.

## Components Created

### 1. SettingsManager (Singleton)
**File**: `Utilities/Systems/settings_manager.gd`

A global autoloaded singleton that manages all game settings and persistence.

**Features**:
- **Video Settings**:
  - Fullscreen mode toggle
  - V-Sync enable/disable
  - Resolution selection (1280x720, 1600x900, 1920x1080, 2560x1440, 3840x2160)
- **Audio Settings**:
  - Master volume control
  - Music volume control
  - Sound Effects volume control
  - All volumes stored in dB (-80 to 0 range)
- **Persistence**: Settings automatically saved to `user://settings.cfg`
- **Auto-apply**: Settings applied on load and when changed

**Signals**:
- `settings_changed()` - Emitted when any setting changes
- `video_settings_changed()` - Emitted when video settings change
- `audio_settings_changed()` - Emitted when audio settings change

### 2. Settings Menu UI
**Files**:
- `Common/UI/settings_menu/settings_menu.tscn`
- `Common/UI/settings_menu/settings_menu.gd`

A tabbed settings menu with three tabs:

#### Video Tab
- Fullscreen checkbox
- V-Sync checkbox
- Resolution dropdown

#### Audio Tab
- Master volume slider (0-100%)
- Music volume slider (0-100%)
- SFX volume slider (0-100%)
- Real-time volume labels

#### Keybinds Tab
- Scrollable list of all customizable keybinds
- Click button to rebind
- Shows current key binding
- Filters out UI and internal actions

**Features**:
- Temporary settings storage (apply on confirm)
- Apply and Cancel buttons
- Process mode 3 (always active, even when paused)
- Modal overlay with semi-transparent background

### 3. Keybind Button Component
**Files**:
- `Common/UI/settings_menu/keybind_button.tscn`
- `Common/UI/settings_menu/keybind_button.gd`

Reusable component for displaying and rebinding input actions.

**Features**:
- Displays action name (formatted)
- Shows current key binding
- Click to enter rebind mode
- Waits for key press to rebind
- Automatically updates display

### 4. Main Menu Integration
**File**: `Stages/UI/main_menu/main_menu.gd`

Updated to instantiate and manage the settings menu.

**Changes**:
- Added settings menu instantiation on ready
- Connected settings button to show settings menu
- Added settings menu closed callback

### 5. Pause Menu Integration
**Files**:
- `Stages/UI/pause_menu/pause_menu.gd`
- `Stages/UI/pause_menu/pause_menu.tscn`

Updated to include settings button and manage settings menu.

**Changes**:
- Added Settings button between Resume and Restart
- Added settings menu instantiation
- Connected settings button to show settings menu
- Adjusted VBoxContainer height to accommodate new button

## User Experience

### From Main Menu:
1. Click "SETTINGS" button
2. Settings menu opens with Video tab active
3. Adjust settings as desired
4. Click "Apply" to save changes or "Cancel" to discard

### From Pause Menu (In-Game):
1. Press ESC to open pause menu
2. Click "Settings" button
3. Settings menu opens overlaying the pause menu
4. Adjust settings as desired
5. Click "Apply" to save and return to pause menu
6. Settings take effect immediately

### Keybind Customization:
1. Navigate to Keybinds tab
2. Click the button next to the action you want to rebind
3. Button text changes to "Press any key..."
4. Press the desired key
5. Binding updates immediately
6. Click "Apply" to confirm all changes

## Technical Details

### Settings Persistence
Settings are saved to `user://settings.cfg` (ConfigFile format) with the following structure:

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

### Audio Bus Integration
The system integrates with Godot's audio bus system:
- Master bus: Controls overall game volume
- Music bus: Controls background music
- Sound Effects bus: Controls SFX

Volume values are stored in dB (-80 to 0) and converted to percentage (0-100) for UI display.

### Resolution Handling
Resolutions are stored as Vector2i and only applied in windowed mode. In fullscreen mode, the system uses the native display resolution. The window is automatically centered when resolution changes.

## Testing Verification

The implementation was tested with:
1. **Headless mode**: Successfully loads and applies settings
2. **Main menu**: Settings button functional
3. **SettingsManager**: Properly registered as singleton
4. **Script classes**: KeybindButton and SettingsMenu registered in global cache
5. **Logging**: All operations logged through Logger system

## Future Enhancements

Potential improvements for future iterations:
1. Graphics quality presets (low/medium/high)
2. FOV adjustment
3. Mouse sensitivity settings
4. Language/localization selection
5. Accessibility options (color blind modes, text size)
6. Default keybind reset button
7. Keybind conflict detection
8. Game-specific settings (difficulty, tutorials, etc.)
