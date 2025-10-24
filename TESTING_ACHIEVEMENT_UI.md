# Testing the Achievement UI

## Prerequisites
- Godot 4.4 installed
- Repository cloned with submodules (`git submodule update --init --recursive`)
- Assets imported (run `./godot --headless --import --path .` and wait 15+ minutes)

## Quick Visual Test

### Test 1: Main Menu Achievements Button
1. Launch the game: `./godot res://Stages/UI/main_menu/main_menu.tscn`
2. Verify you see an "ACHIEVEMENTS" button on the main menu
3. Click the "ACHIEVEMENTS" button
4. Expected: Achievement list opens showing:
   - Title "Achievements"
   - Stats showing "Achievements Unlocked: X / Y (Z%)"
   - List of achievement cards
   - Each card shows: name, description, progress/unlock date
   - Close button

### Test 2: Pause Menu Achievements Button
1. Start a game
2. Press ESC to open pause menu
3. Verify you see an "Achievements" button
4. Click the "Achievements" button
5. Expected: Same achievement list opens

### Test 3: Achievement Notification Toast
To test the notification, you need to trigger an achievement unlock. Here are two ways:

#### Method A: Use Console (if debug console available)
1. In-game, open console
2. Manually unlock an achievement:
   ```gdscript
   var achievement = AchievementManager.get_achievement("first_blood")
   AchievementManager._unlock_achievement("first_blood")
   ```

#### Method B: Play the Game
1. Start the game
2. Defeat your first enemy to trigger "First Blood" achievement
3. Expected notification behavior:
   - Toast notification slides in from top-right corner
   - Shows achievement icon, name, and description
   - Plays sound effect
   - Auto-hides after 5 seconds
   - Slides out smoothly

#### Method C: Test Multiple Notifications (Queueing)
1. Quickly trigger multiple achievements
2. Expected: Notifications queue and display one at a time

### Test 4: Hidden Achievements
1. Open achievement list
2. Look for any hidden achievements (if configured)
3. Expected: Hidden achievements show "???" as name and "Hidden achievement" as description until unlocked

### Test 5: Achievement Progress
1. Open achievement list
2. Look at locked achievements
3. Expected: Each locked achievement shows "Progress: X%" based on current game stats

## Automated Tests

Run the unit test suite:
```bash
./run_tests.sh
```

This will run:
- `test_achievement_notification.gd` - Tests notification component
- `test_achievement_notification_manager.gd` - Tests queue management
- `test_achievement_list.gd` - Tests list UI

Expected: All tests pass with green checkmarks

## Manual Code Review Checklist

- [ ] All new files follow project structure conventions
- [ ] Scripts use proper class_name declarations
- [ ] Scenes are properly structured with correct node hierarchy
- [ ] Signals are properly connected
- [ ] No memory leaks (proper queue_free() usage)
- [ ] No hardcoded values where configuration should be used
- [ ] Consistent with existing UI component patterns
- [ ] Proper error handling for edge cases
- [ ] Logger statements for debugging
- [ ] Comments for complex logic

## Expected Visual Behavior

### Achievement Notification
- **Position**: Top-right corner with 20px padding
- **Animation**: Slides in from right (0.5s ease-out back)
- **Duration**: Visible for 5 seconds
- **Exit**: Slides out to right (0.5s ease-in back)
- **Size**: ~400x120 pixels
- **Content**: Icon (64x64), name (large), description (wrapped text)

### Achievement List
- **Position**: Centered on screen
- **Size**: 800x600 pixels
- **Background**: Panel with theme
- **Header**: Title on left, Close button on right
- **Stats**: Centered, shows unlock count and percentage
- **Cards**: Vertical list in scrollable container
- **Card Size**: Full width, ~100px height
- **Locked Visual**: Semi-transparent black overlay

## Common Issues and Solutions

### Issue: Notification doesn't appear
- **Check**: Is AchievementNotificationManager in the scene tree?
- **Check**: Is the notification properly connected to AchievementManager?
- **Solution**: Verify ui.tscn includes the manager as a CanvasLayer

### Issue: Sound doesn't play
- **Check**: Is AudioManager enum updated?
- **Check**: Is sound file configured in AudioManager?
- **Solution**: Add proper achievement unlock sound to Assets/Audio/SFX/

### Issue: Achievement list is empty
- **Check**: Are there achievement resources in Config/Achievements/?
- **Check**: Is AchievementManager properly loading achievements?
- **Solution**: Verify achievement .tres files exist and are valid

### Issue: Tests fail
- **Check**: Are all dependencies loaded (submodules)?
- **Check**: Is GUT properly installed in external/Gut/?
- **Solution**: Run `git submodule update --init --recursive`

## Performance Considerations

- Notifications use Tween for animations (efficient)
- Only one notification visible at a time (no performance impact)
- Achievement cards created on-demand when list opens
- Cards properly freed when list closes
- No continuous polling or checking

## Integration Points

The achievement UI integrates with:
1. **AchievementManager** - Receives unlock signals, queries achievement data
2. **AudioManager** - Plays unlock sound effect
3. **Main Menu** - Adds achievements button
4. **Pause Menu** - Adds achievements button
5. **Main UI** - Hosts notification manager

All integration points use existing autoload systems and signal patterns.
