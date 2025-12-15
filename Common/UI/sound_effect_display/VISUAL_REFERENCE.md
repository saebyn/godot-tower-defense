# Sound Effect Display - Visual Reference

This document provides a visual representation of how the sound effect display appears in-game.

## Display Location

The sound effect display appears in the **bottom-left corner** of the screen:

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│                    GAME CONTENT AREA                       │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│                                                            │
│  ┌───────────────────────┐                                │
│  │  Sound Effects        │                                │
│  │  ─────────────────────│                                │
│  │  Turret Fire (x3)     │                                │
│  │  Zombie Death (x2)    │                                │
│  │  Player Attack Hit    │                                │
│  │  Ui Confirm           │                                │
│  └───────────────────────┘                                │
│                                                            │
│  [HOTBAR AND OTHER UI ELEMENTS]                           │
└────────────────────────────────────────────────────────────┘
```

## Display States

### Hidden (Default)
```
No display visible. Press F11 to show.
```

### Visible - Empty
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  (no recent sounds)   │
└───────────────────────┘
```

### Visible - Single Sound
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Turret Fire          │
└───────────────────────┘
```

### Visible - Multiple Sounds with Counts
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Turret Fire (x5)     │
│  Zombie Death (x2)    │
│  Player Attack Hit    │
│  Ui Confirm           │
│  Building Damaged     │
└───────────────────────┘
```

### Visible - At Max Capacity (10 effects)
```
┌───────────────────────────────┐
│  Sound Effects                │
│  ─────────────────────────────│
│  Turret Fire (x12)            │
│  Zombie Death (x8)            │
│  Player Attack Hit (x4)       │
│  Ui Confirm (x3)              │
│  Building Damaged (x2)        │
│  Electric Crackle             │
│  Fire Crackle                 │
│  Zombie Idle Groan            │
│  Building Complete            │
│  Achievement Unlocked         │
└───────────────────────────────┘
```

## Visual Styling

- **Background**: Black with 70% opacity (semi-transparent)
- **Border**: Panel border from theme
- **Text Color**: White
- **Font Size**: 14px for sound names
- **Header**: "Sound Effects" in default size
- **Separator**: Horizontal line below header
- **Padding**: 8px margin on all sides

## Behavior Demo

### Time-based Expiration (5 seconds)

**T=0s: Sound plays**
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Turret Fire          │
└───────────────────────┘
```

**T=2s: More sounds added**
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Turret Fire          │
│  Zombie Death         │
│  Ui Confirm           │
└───────────────────────┘
```

**T=5.1s: First sound expires**
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Zombie Death         │
│  Ui Confirm           │
└───────────────────────┘
```

### Count Aggregation

**Initial state:**
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Turret Fire          │
└───────────────────────┘
```

**After playing same sound 2 more times:**
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Turret Fire (x3)     │
└───────────────────────┘
```

**After playing same sound 7 more times:**
```
┌───────────────────────┐
│  Sound Effects        │
│  ─────────────────────│
│  Turret Fire (x10)    │
└───────────────────────┘
```

## Controls

| Key | Action |
|-----|--------|
| F11 | Toggle display on/off |

## Integration

The display is automatically included in the main game UI (`Stages/UI/main_ui/ui.tscn`) but remains hidden by default. It connects to AudioManager's `sound_played` signal to receive notifications whenever any sound effect plays in the game.
