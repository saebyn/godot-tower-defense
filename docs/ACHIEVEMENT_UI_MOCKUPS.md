# Achievement UI Visual Mockups

These ASCII diagrams show the visual layout of the new Achievement UI components.

## Achievement Notification Toast (Top-Right Corner)

```
┌──────────────────────────────────────────────┐
│  ┌────────┐  ACHIEVEMENT UNLOCKED!           │
│  │        │                                   │
│  │  ICON  │  Achievement Name                │
│  │  64x64 │  Achievement description goes    │
│  │        │  here and wraps to multiple      │
│  └────────┘  lines if needed                 │
└──────────────────────────────────────────────┘
```

**Animation:**
- Slides in from right (0.5s, ease-out-back)
- Displays for 5 seconds
- Slides out to right (0.5s, ease-in-back)
- Sound effect plays on appear

## Achievement List Screen (Centered)

```
┌────────────────────────────────────────────────────────────┐
│  Achievements                                    [Close]    │
├────────────────────────────────────────────────────────────┤
│             Achievements Unlocked: 1 / 2 (50%)             │
├────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐ │
│  │ ┌────────┐  First Blood                              │ │
│  │ │        │  Defeat your first enemy                  │ │
│  │ │  ICON  │  Unlocked: 10/24/2024                     │ │
│  │ │        │                                            │ │
│  │ └────────┘                                            │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ ┌────────┐  Zombie Slayer    [LOCKED OVERLAY]       │ │
│  │ │   ?    │  Defeat 100 zombies                       │ │
│  │ │   ?    │  Progress: 15%                            │ │
│  │ │   ?    │                                            │ │
│  │ └────────┘                                            │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  (Scrollable if more achievements)                        │
└────────────────────────────────────────────────────────────┘
```

**Features:**
- 800x600 pixel panel centered on screen
- Header with title and close button
- Stats showing unlock progress
- Scrollable list of achievement cards
- Cards sorted: unlocked first, then by name
- Locked achievements show progress percentage
- Unlocked achievements show unlock date
- Hidden achievements show "???" until unlocked

## Main Menu (Updated)

```
┌────────────────────┐
│  TOWER DEFENSE     │
│                    │
│  [START GAME]      │
│                    │
│  [LEVEL SELECT]    │
│                    │
│  [TECH TREE]       │
│                    │
│  [ACHIEVEMENTS] ←── NEW BUTTON
│                    │
│  [SETTINGS]        │
│                    │
│  [EXIT]            │
└────────────────────┘
```

## Pause Menu (Updated)

```
┌────────────────────┐
│      PAUSED        │
│                    │
│  [Resume]          │
│                    │
│  [Tech Tree]       │
│                    │
│  [Achievements] ←── NEW BUTTON
│                    │
│  [Settings]        │
│                    │
│  [Restart]         │
│                    │
│  [Main Menu]       │
│                    │
│  [Quit]            │
└────────────────────┘
```

## Notification Queue Behavior

When multiple achievements unlock simultaneously:

```
Achievement 1 unlocks → Queue: []
                      → Show immediately

Achievement 2 unlocks → Queue: [Achievement 2]
                      → Wait for Achievement 1 to finish

Achievement 3 unlocks → Queue: [Achievement 2, Achievement 3]
                      → Wait in queue

Achievement 1 finishes → Queue: [Achievement 3]
                       → Show Achievement 2

Achievement 2 finishes → Queue: []
                       → Show Achievement 3

Achievement 3 finishes → Queue: []
                       → All done
```

## States of Achievement Cards

### Unlocked Achievement Card
```
┌──────────────────────────────────────────────────────┐
│ ┌────────┐  Achievement Name                         │
│ │        │  Achievement description text             │
│ │  ICON  │  Unlocked: 10/24/2024                     │
│ │        │                                            │
│ └────────┘                                            │
└──────────────────────────────────────────────────────┘
```

### Locked Achievement Card (Normal)
```
┌──────────────────────────────────────────────────────┐
│ ┌────────┐  Achievement Name    [DARK OVERLAY 60%]  │
│ │        │  Achievement description text             │
│ │  ICON  │  Progress: 25%                            │
│ │  (dim) │                                            │
│ └────────┘                                            │
└──────────────────────────────────────────────────────┘
```

### Hidden Achievement Card (Locked)
```
┌──────────────────────────────────────────────────────┐
│ ┌────────┐  ???                [DARK OVERLAY 60%]   │
│ │   ?    │  Hidden achievement                       │
│ │   ?    │                                            │
│ │   ?    │                                            │
│ └────────┘                                            │
└──────────────────────────────────────────────────────┘
```

## Color Scheme

The UI uses the project's existing theme (`ztd_ui_theme.tres`):
- **Panels**: Semi-transparent dark backgrounds
- **Text**: Light colors for readability
- **Unlocked**: Full brightness
- **Locked**: 60% opacity overlay
- **Hidden**: Question marks instead of details

## Responsive Behavior

- **Notification**: Fixed 400x120px, positioned relative to viewport
- **Achievement List**: Fixed 800x600px, centered on screen
- **Cards**: Full width of container, fixed height ~100px
- **Scrolling**: Automatic when achievement list exceeds viewport height
