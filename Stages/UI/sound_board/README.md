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

- **Dynamic Button Generation**: Automatically creates a button for each sound effect defined in `AudioManager.SoundEffect` enum
- **Sound Preview**: Click any button to play the corresponding sound effect
- **Audio Variations**: Plays random variations with randomized pitch (as per AudioManager implementation)
- **Easy Navigation**: Close button to exit the scene

## Purpose

This tool is designed for:
- Testing audio implementation
- Previewing sound effects during development
- Verifying audio file loading and playback
- Demonstrating available sound effects to team members

## Implementation Details

The sound board:
- Extends `Control` with class name `UI_SoundBoard`
- Uses the existing UI theme (`ztd_ui_theme.tres`)
- Dynamically iterates through `AudioManager.SoundEffect.keys()` to create buttons
- Formats enum names from SNAKE_CASE to Title Case for display
- Utilizes `AudioManager.play_sound()` for consistent audio playback
