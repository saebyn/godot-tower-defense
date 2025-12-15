# Sound Effect Display

A debug display component that shows recently played sound effects in the corner of the screen, useful for debugging audio playback and verifying sound effect triggers.

## Features

- **Real-time Display**: Shows sound effects as they play
- **Smart Aggregation**: Counts duplicate sounds instead of spamming the list (e.g., "Turret Fire (x5)")
- **Auto-Expiration**: Sounds automatically disappear after 5 seconds
- **Display Limit**: Shows up to 10 most recent sound effects
- **Optional Toggle**: Hidden by default, press F11 to show/hide

## Usage

### In-Game

1. Press **F11** to toggle the sound effect display on/off
2. Sound effects will appear in the bottom-left corner as they play
3. Duplicate sounds within 5 seconds will show a count: "Sound Name (x3)"
4. Each entry automatically disappears after 5 seconds

### Manual Testing

A test scene is available at `tests/manual/test_sound_effect_display_manual.tscn`:

- **F11**: Toggle display visibility
- **1-5**: Play different sound effects
- **SPACE**: Play rapid sounds to test aggregation

## Implementation Details

### Signal-Based Tracking

The AudioManager emits a `sound_played` signal whenever a sound effect is triggered:

```gdscript
# AudioManager emits this signal
signal sound_played(effect: Resource_SoundEffect.SoundEffect)
```

### Display Component

Located in `Common/UI/sound_effect_display/`:
- `sound_effect_display.tscn` - UI scene
- `sound_effect_display.gd` - Display logic

### Integration

The display is integrated into the main UI at `Stages/UI/main_ui/ui.tscn` and positioned in the bottom-left corner.

## Architecture

The sound effect display uses a dictionary to track active sounds:

```gdscript
{
  "Sound Name": {
    "count": 3,           # Number of times played
    "timestamp": 12345.6,  # Last play time
    "label": Label,       # UI label node
    "effect": Enum        # Sound effect enum value
  }
}
```

### Cleanup Process

- Every frame, checks for expired entries (> 5 seconds old)
- Removes expired labels from the UI
- Enforces a maximum of 10 displayed effects

## Testing

Unit tests are available in `tests/unit/test_sound_effect_display.gd`:

```bash
./run_tests.sh -gselect="test_sound_effect_display"
```

All 10 tests pass, covering:
- Display visibility toggle
- Sound tracking and aggregation
- Label text formatting with counts
- Expiration after 5 seconds
- Maximum display limit enforcement
- Behavior when invisible

## UI Design

The display appears in the bottom-left corner with:
- Semi-transparent black background (70% opacity)
- White text at 14px font size
- "Sound Effects" header with separator
- Scrollable list of recent sounds
- Format: "Sound Effect Name" or "Sound Effect Name (x5)"
