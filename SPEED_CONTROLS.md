# Game Speed Controls

## Overview
The game now includes speed control functionality that allows players to adjust the game simulation speed and pause/resume gameplay.

## UI Components
- **Pause Button (⏸️/▶️)**: Pauses or resumes the game
- **1x Button**: Normal game speed
- **2x Button**: Double game speed  
- **4x Button**: Quadruple game speed

## Controls Location
The speed controls are located in the top-right corner of the game UI, next to the currency display.

## Keyboard Shortcuts
- **ESC**: Toggle pause/resume (same as clicking the pause button)

## Technical Implementation

### GameManager Extensions
The `GameManager` singleton has been extended with:
- `set_game_speed(float)`: Sets game speed multiplier
- `get_game_speed()`: Returns current speed multiplier
- Enhanced pause/resume that preserves speed settings

### Speed Control Logic
- Speed changes use `Engine.time_scale` for smooth simulation scaling
- When paused, `time_scale` is set to 0.0
- Speed changes while paused are stored and applied when resumed
- UI buttons reflect the current speed setting with visual feedback

### UI Integration
- Speed controls integrate with existing GameManager pause system
- UI updates automatically when speed or pause state changes
- Component follows the project's UI architecture patterns

## Usage
1. Use the pause button or ESC to pause/resume the game
2. Click speed buttons (1x, 2x, 4x) to change simulation speed
3. Speed changes can be made while paused and will apply when resumed
4. Current speed setting is visually indicated by the pressed button state