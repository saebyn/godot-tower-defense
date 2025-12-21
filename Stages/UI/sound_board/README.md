# Sound Board

A standalone testing scene for previewing and playing all sound effects defined in the AudioManager.

## Location

`res://Stages/UI/sound_board/sound_board.tscn`

## Usage

### Running Directly
To open the sound board scene directly in Godot:
1. Open the project in Godot Editor
2. Navigate to `Stages/UI/sound_board/sound_board.tscn`
3. Press F5 or click "Run Current Scene"

### From Command Line
```bash
godot --path . "res://Stages/UI/sound_board/sound_board.tscn"
```

## Features

- **Category Organization**: Sound effects are organized by category (Combat, UI, Building, Ambience) in a grid layout
- **Variation Count Display**: Shows the number of audio variations available for each effect
- **Pitch Range Information**: Displays the configurable pitch variation range for each effect
- **Dynamic Button Generation**: Automatically creates a button for each sound effect defined in `Resource_SoundEffect.SoundEffect` enum
- **Sound Preview**: Click any button to play the corresponding sound effect
- **Audio Variations**: Plays random variations with randomized pitch based on configured ranges (per AudioManager implementation)
- **Interactive Editing**: Edit sound effect properties in real-time
  - **Edit Mode Toggle**: Enable/disable editing controls
  - **Pitch Range Controls**: Adjust min/max pitch variation with spinboxes
  - **Volume Control**: Set volume in dB with spinbox
  - **Category Selection**: Change sound effect category with dropdown
  - **Visual Feedback**: Modified effects show with yellow tint
  - **Save Changes**: Persist modifications back to .tres resource files
- **Easy Navigation**: Close button to exit the scene

## Editing Sound Effects

The sound board includes an interactive editing mode for modifying sound effect configurations:

1. Click the **Edit Mode** button to show editing controls
2. Adjust parameters using the spinboxes and dropdowns:
   - **Min Pitch**: Minimum pitch variation (0.0 - 2.0)
   - **Max Pitch**: Maximum pitch variation (0.0 - 2.0)
   - **Volume**: Volume in decibels (-80.0 dB - 24.0 dB)
   - **Category**: Sound effect category (UI, Combat, Building, Ambience, Player Action)
3. Modified sound effects are highlighted with a yellow tint
4. Click **Save Changes** to write modifications to the .tres files
5. The info label updates in real-time to reflect your changes

**Note**: Saved changes persist to the resource files in `res://Config/SoundEffects/`

## Grid Layout

The sound board displays effects in columns, with each column representing a category:
- **Combat**: Attack sounds, impact effects, weapon sounds, etc.
- **UI**: Menu sounds, notifications, button clicks, confirmations, etc.
- **Building**: Construction sounds, placement effects, progress indicators, etc.
- **Ambience**: Environmental sounds, background audio, ambient effects, etc.

## Purpose

This tool is designed for:
- Testing audio implementation
- Previewing sound effects during development
- Verifying audio file loading and playback
- Demonstrating available sound effects to team members
- Checking pitch variation ranges and variation counts
- **Editing sound effect configurations** (pitch, volume, category)
- **Iterative audio tuning** during game development

## Implementation Details

The sound board:
- Extends `Control` with class name `UI_SoundBoard`
- Uses the existing UI theme (`ztd_ui_theme.tres`)
- Dynamically groups effects by category using `AudioManager.SoundEffectConfig`
- Creates a grid with columns for each category
- Displays variation count and pitch range for each effect
- Utilizes `AudioManager.play_sound()` for consistent audio playback

## AudioManager Integration

Each sound effect in AudioManager now includes:
- **Category**: Organizes sounds by type (Combat, UI, Building, Ambience)
- **Variations**: Array of audio samples that are randomly selected
- **Pitch Range**: Configurable min/max pitch variation for each effect
  - Example: Combat sounds might have wider variation (0.8-1.2) for variety
  - Example: UI sounds might have tighter variation (0.9-1.1) for consistency
