# Tower Defense - Godot 4.4 Project

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Installation
- Download and install Godot 4.4+ from the official website: `wget https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_linux.x86_64.zip`
- Extract and install: `unzip Godot_v4.4-stable_linux.x86_64.zip && chmod +x Godot_v4.4-stable_linux.x86_64 && sudo mv Godot_v4.4-stable_linux.x86_64 /usr/local/bin/godot`
- Verify installation: `godot --version` (should show `4.4.stable.official.4c311cbee`)

### Project Setup and Execution
- **NEVER CANCEL**: Initial project import takes 5-10 minutes. Set timeout to 15+ minutes.
- Open project in Godot editor: `godot --editor --path .` 
- **NEVER CANCEL**: First-time project loading and asset import takes 10-15 minutes. Wait for completion.
- Run the game: Press F5 in editor or `godot --path .` (requires display)
- **Headless limitations**: Game cannot run fully headless due to 3D rendering requirements. Use `godot --headless --editor --quit` for validation only.
- **Important**: Project validation may show progress dialog errors in headless mode - this is normal and can be ignored.

### Building and Testing
- **No traditional build system**: This is a Godot game project - no Make, npm, or similar build tools
- **No automated tests**: Manual validation required for all changes
- Project validation: `godot --headless --editor --quit` - takes 5+ minutes, NEVER CANCEL. May show progress dialog errors - ignore these.
- Check for script errors: All GDScript files auto-validate when opening in Godot editor
- **Full functionality testing requires display**: Core game testing requires running with graphics enabled

## Validation Requirements

### Manual Testing Scenarios
After making ANY changes, ALWAYS test these core scenarios:

1. **Camera Controls Validation**:
   - Open game in Godot editor and run (F5)
   - Test WASD movement (W=up, A=left, S=right, R=down)
   - Test Q/F rotation (Q=rotate left 90°, F=rotate right 90°) 
   - Test mouse wheel zoom in/out
   - Test +/- key zoom with Shift for fast zoom

2. **Enemy AI and Navigation**:
   - Verify enemies spawn and move toward targets
   - Check enemy pathfinding around obstacles
   - Confirm enemies attack targets when in range
   - Validate target destruction and enemy target switching

3. **Core Game Systems**:
   - Enemy spawning continues at regular intervals
   - Navigation mesh updates correctly when obstacles change
   - Physics simulation runs without errors
   - All script console output shows expected behavior

### Performance Validation
- Game should maintain stable framerate at 60 FPS
- Enemy count should not exceed reasonable limits (default max 10)
- Navigation mesh rebuilds should complete within 2-3 seconds

## Project Structure and Key Files

### Core Game Logic
- `main.gd` - Scene controller, camera management, obstacle creation. ALWAYS modify camera behavior here.
- `enemy.gd` - Enemy AI, navigation, attack logic. Modify for enemy behavior changes.
- `target.gd` - Destructible target logic. Simple hit/die system.
- `enemy_spawner.gd` - Controls enemy spawning intervals and limits. Modify for spawn behavior.
- `avoidance_obstacle.gd` - Navigation obstacle setup for AI pathfinding.

### Scene Files
- `main.tscn` - Main game scene with navigation, camera, ground plane, and initial setup
- `enemy.tscn` - Enemy prefab with 3D model, navigation, collision, and attack timer

### Project Configuration  
- `project.godot` - Godot project settings, input mappings, physics engine config
- Input mappings: Camera controls (WASD, QF, mouse wheel, +/-), zoom modifiers
- Physics: Uses Jolt Physics engine, 3D navigation enabled
- Rendering: GL Compatibility mode for broader hardware support

### Assets
- `suzanne.blend` - 3D model asset (Blender file, auto-imported by Godot)
- `icon.svg` - Project icon
- `new_environment.tres` - 3D environment settings

## Troubleshooting Common Issues

### UID Recognition Errors
If you see "Unrecognized UID" errors:
- Run `godot --headless --editor --quit` to regenerate asset UIDs (takes 5+ minutes, may show progress dialog errors)
- Delete `.godot/` folder and reimport: `rm -rf .godot && godot --headless --import` (takes 10+ minutes)
- These errors are common in headless environments but don't prevent development work

### Navigation and AI Issues
- Navigation mesh may need rebaking after scene changes
- Check console output for navigation warnings
- Enemies require physics frames to initialize - expect brief delay on spawn

### Performance Issues  
- Monitor enemy count - adjust `max_enemies` in EnemySpawner if needed
- Navigation mesh complexity affects performance - keep level geometry simple
- 3D rendering requires GPU - cannot fully test in headless environments

## Development Workflow

### Making Changes
1. Always open project in Godot editor first: `godot --editor --path .`
2. Make code changes to `.gd` files using any text editor
3. Scene changes require Godot editor - auto-reloads on file changes
4. Test changes immediately using F5 in editor or validation scenarios above
5. Check console output for script errors or warnings

### Common Modification Patterns
- **Camera adjustments**: Modify exports in `main.gd` (speeds, zoom limits, etc.)
- **Enemy behavior**: Adjust exports in `enemy.gd` (movement speed, damage, etc.)  
- **Spawning changes**: Modify `enemy_spawner.gd` exports (intervals, limits)
- **New game mechanics**: Add to main scene via editor, reference from `main.gd`

### Code Style and Conventions
- Use GDScript typed variables: `var speed: float = 5.0`
- Export important parameters: `@export var camera_speed: float = 5.0`
- Group nodes with `@onready`: `@onready var camera: Camera3D = $Camera3D`
- Print debug info liberally: `print("Enemy spawned at: ", position)`

## Timing Expectations and Timeouts

- **CRITICAL**: Set timeouts of 15+ minutes for initial project operations
- **NEVER CANCEL**: Godot editor startup: 5-10 minutes first time
- **NEVER CANCEL**: Asset import and indexing: 10-15 minutes  
- **NEVER CANCEL**: Project validation: 5+ minutes
- Scene loading: 10-30 seconds
- Script recompilation: 1-5 seconds
- Navigation mesh rebuild: 2-3 seconds

Remember: This is a 3D game project with complex asset processing. Long initial load times are NORMAL and expected.