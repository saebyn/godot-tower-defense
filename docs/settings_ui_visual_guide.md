# Settings UI Visual Structure

## Main Menu
```
┌─────────────────────────────────┐
│                                 │
│      TOWER DEFENSE              │
│                                 │
│    ┌──────────────────┐         │
│    │   START GAME     │         │
│    └──────────────────┘         │
│                                 │
│    ┌──────────────────┐         │
│    │    SETTINGS  ←───┼─────────┼── Opens Settings Menu
│    └──────────────────┘         │
│                                 │
│    ┌──────────────────┐         │
│    │      EXIT        │         │
│    └──────────────────┘         │
│                                 │
└─────────────────────────────────┘
```

## Pause Menu
```
┌─────────────────────────────────┐
│           PAUSED                │
│                                 │
│    ┌──────────────────┐         │
│    │     Resume       │         │
│    └──────────────────┘         │
│                                 │
│    ┌──────────────────┐         │
│    │    Settings  ←───┼─────────┼── Opens Settings Menu
│    └──────────────────┘         │
│                                 │
│    ┌──────────────────┐         │
│    │    Restart       │         │
│    └──────────────────┘         │
│                                 │
│    ┌──────────────────┐         │
│    │   Main Menu      │         │
│    └──────────────────┘         │
│                                 │
│    ┌──────────────────┐         │
│    │      Quit        │         │
│    └──────────────────┘         │
│                                 │
└─────────────────────────────────┘
```

## Settings Menu - Video Tab
```
┌─────────────────────────────────────────────────┐
│              SETTINGS                           │
│ ┌─────────┬─────────┬──────────┐               │
│ │  Video  │  Audio  │ Keybinds │               │
│ └─────────┴─────────┴──────────┘               │
│                                                 │
│  Fullscreen:        [✓]                         │
│                                                 │
│  V-Sync:            [✓]                         │
│                                                 │
│  Resolution:        [1920x1080      ▼]          │
│                     Options:                    │
│                     - 1280x720                  │
│                     - 1600x900                  │
│                     - 1920x1080 (selected)      │
│                     - 2560x1440                 │
│                     - 3840x2160                 │
│                                                 │
│                                                 │
│             ┌────────┐  ┌────────┐              │
│             │ Apply  │  │ Cancel │              │
│             └────────┘  └────────┘              │
└─────────────────────────────────────────────────┘
```

## Settings Menu - Audio Tab
```
┌─────────────────────────────────────────────────┐
│              SETTINGS                           │
│ ┌─────────┬─────────┬──────────┐               │
│ │  Video  │  Audio  │ Keybinds │               │
│ └─────────┴─────────┴──────────┘               │
│                                                 │
│  Master: 100%                                   │
│  ├────────────────────────────┤                │
│  │■■■■■■■■■■■■■■■■■■■■■■■■■■■■│                │
│  └────────────────────────────┘                │
│                                                 │
│  Music: 100%                                    │
│  ├────────────────────────────┤                │
│  │■■■■■■■■■■■■■■■■■■■■■■■■■■■■│                │
│  └────────────────────────────┘                │
│                                                 │
│  SFX: 100%                                      │
│  ├────────────────────────────┤                │
│  │■■■■■■■■■■■■■■■■■■■■■■■■■■■■│                │
│  └────────────────────────────┘                │
│                                                 │
│             ┌────────┐  ┌────────┐              │
│             │ Apply  │  │ Cancel │              │
│             └────────┘  └────────┘              │
└─────────────────────────────────────────────────┘
```

## Settings Menu - Keybinds Tab
```
┌─────────────────────────────────────────────────┐
│              SETTINGS                           │
│ ┌─────────┬─────────┬──────────┐               │
│ │  Video  │  Audio  │ Keybinds │               │
│ └─────────┴─────────┴──────────┘               │
│  ┌───────────────────────────────────────────┐ │
│  │ Camera Move Left     │    A    │            │
│  │ Camera Move Right    │    S    │            │
│  │ Camera Move Up       │    W    │            │
│  │ Camera Move Down     │    R    │            │
│  │                                             │ │
│  │  (Click any button to rebind)              │ │
│  │                                             │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│             ┌────────┐  ┌────────┐              │
│             │ Apply  │  │ Cancel │              │
│             └────────┘  └────────┘              │
└─────────────────────────────────────────────────┘
```

## User Flow

### Opening Settings from Main Menu
1. User clicks "SETTINGS" button on main menu
2. Settings menu appears with semi-transparent overlay
3. Video tab is shown by default
4. User can navigate between tabs
5. User adjusts settings
6. User clicks "Apply" to save changes
7. Settings menu closes, returns to main menu

### Opening Settings from Pause Menu
1. User presses ESC during gameplay
2. Pause menu appears
3. User clicks "Settings" button
4. Settings menu overlays the pause menu
5. User adjusts settings
6. User clicks "Apply" to save changes
7. Settings menu closes, returns to pause menu
8. User can resume game or return to main menu

### Rebinding Keys
1. Navigate to Keybinds tab
2. Click on the key button next to desired action
3. Button text changes to "Press any key..."
4. Press the new key
5. Button updates to show new key
6. Click "Apply" to save all changes
7. Keybind immediately active in game

## Technical Details

- **Modal Overlay**: Semi-transparent black background (50% opacity)
- **Process Mode**: Set to 3 (always active, works during pause)
- **Tab Container**: Godot's built-in TabContainer for easy navigation
- **Sliders**: HSlider controls with range 0-100 for intuitive volume control
- **Real-time Feedback**: Volume labels update instantly as sliders move
- **Validation**: Resolution only applies in windowed mode
- **Persistence**: Settings auto-save to user:// directory
