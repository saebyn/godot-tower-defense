# Tech Tree UI Manual Testing Guide

## Prerequisites
- Godot 4.4 must be installed
- Project must be fully imported (run `./godot --headless --import --path .` first)

## Test Scenarios

### 1. Access from Main Menu
1. Launch the game: `./godot --path .`
2. From the main menu, click "TECH TREE" button
3. ✓ Tech tree screen should open
4. ✓ Should display tech nodes organized by branch

### 2. Access from Pause Menu
1. Launch the game and start playing
2. Press ESC to pause
3. Click "Tech Tree" button
4. ✓ Tech tree screen should open

### 3. Tech Node Display
1. Open tech tree
2. ✓ Should see branches: Offensive, Defensive, Economy, Support, Click, Advanced
3. ✓ Starter techs (Level 1) should show as "⚡ Available" (yellow)
4. ✓ Higher level techs should show as "🔒 Locked" (gray)

### 4. Tech Node Selection
1. Click on a tech node card
2. ✓ Detail panel should appear at bottom
3. ✓ Should show: Name, Description, Requirements, Unlocks, Unlock button

### 5. Unlock a Starter Tech
1. Select "Scrap Shooter" (Offensive branch, Level 1)
2. ✓ Unlock button should be enabled
3. Click "Unlock" button
4. ✓ Tech should unlock immediately (no cost)
5. ✓ Card should change to "✅ Unlocked" (green)

### 6. Mutually Exclusive Warning
1. Unlock "Scrap Shooter" if not already unlocked
2. Reach Level 2 (or set level in code for testing)
3. Select "Boom Barrel" tech
4. Click "Unlock" button
5. ✓ Confirmation dialog should appear
6. ✓ Should warn that "Molotov Mortar" will be permanently locked
7. Click "OK" to confirm
8. ✓ "Boom Barrel" should unlock
9. ✓ "Molotov Mortar" should show as "⛔ Locked" (red)

### 7. Prerequisites Check
1. Select a tech that requires another tech
2. ✓ Unlock button should be disabled
3. ✓ Requirements should list prerequisite techs

### 8. Level Requirement Check
1. Select a tech requiring Level 4+
2. ✓ Unlock button should be disabled
3. ✓ Requirements should show "Level X required"

### 9. Close Tech Tree
1. Click "Close" button
2. ✓ Tech tree screen should close
3. ✓ Should return to previous screen (main menu or pause menu)

### 10. UI Responsiveness
1. Navigate tech tree with mouse
2. ✓ Cards should respond to hover
3. ✓ Scroll should work if needed
4. ✓ All text should be readable
5. ✓ UI should use ztd_ui_theme.tres styling

## Known Issues
- Asset import must complete before testing (15+ minutes first time)
- Theme UID errors are expected before import completes

## Testing with Modified Level
To test high-level techs, add this to main.gd or use console:
```gdscript
CurrencyManager.current_level = 6  # Set to desired level
```
