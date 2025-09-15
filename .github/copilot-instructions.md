# GitHub Copilot Instructions for Godot Tower Defense

This document provides comprehensive instructions for GitHub Copilot to work effectively with this Godot 4.4 tower defense game project.

## Project Overview

This is a **3D tower defense game** built with **Godot 4.4**. The project uses a feature-based folder structure with clear separation of concerns and follows a Template + Config pattern for game entities.

### Key Project Details
- **Engine**: Godot 4.4
- **Project Type**: 3D Tower Defense Game
- **Main Scene**: `Stages/Game/main/main.tscn`
- **Total Scenes**: 17 scenes
- **Total Scripts**: 12 scripts
- **Architecture**: Template + Config pattern for entities

## Critical Setup Requirements

### ⚠️ CRITICAL: Asset Import Timing
**NEVER cancel the initial asset import process!** The first-time asset import takes **15+ minutes minimum**. Cancelling this process will break 3D model rendering and require starting over.

### Godot 4.4 Installation

1. **Download Godot 4.4** (verified URL):
   ```bash
   wget https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_linux.x86_64.zip
   unzip Godot_v4.4-stable_linux.x86_64.zip
   chmod +x Godot_v4.4-stable_linux.x86_64
   mv Godot_v4.4-stable_linux.x86_64 ./godot
   ```

2. **Verify Installation**:
   ```bash
   ./godot --version
   # Expected output: 4.4.stable.official
   ```

### Project Setup

1. **Initial Asset Import** (⚠️ CRITICAL - DO NOT CANCEL):
   ```bash
   # This takes 15+ minutes minimum - be patient!
   ./godot --headless --import --path .
   ```
   - Wait for complete import before proceeding
   - Script class registration happens during this process

2. **Quick Validation**:
   ```bash
   # Test headless execution (should exit cleanly)
   ./godot --headless --path . "res://Stages/Game/main/main.tscn"
   ```

## Project Structure

### Directory Organization
```
├── Assets/                 # Asset files (models, icons)
│   ├── Icons/             # UI icons (PNG or SVG files)
│   ├── Textures/          # Textures (PNG, JPG files)
│   ├── Sounds/            # Audio files (WAV, OGG files)
│   ├── Animations/        # Animation files (if any)
│   ├── Shaders/           # Shader files (if any)
│   ├── Materials/         # Material files (if any)
│   ├── Fonts/             # Font files (if any)
│   └── Models/            # 3D models (*.blend files, etc)
├── Common/                # Shared components and systems
│   ├── Components/        # Reusable components (attack, health)
│   ├── Effects/          # Visual/audio effects (shake_effect)
│   ├── Systems/          # Game systems (spawner)
│   └── UI/               # Common UI components (health_display)
├── Config/               # Configuration files
│   └── Environments/     # Environment configurations
├── Entities/             # Game entities organized by type
│   ├── Enemies/          # Enemy templates and configurations
│   ├── Obstacles/        # Obstacle templates and configurations
│   └── Targets/          # Target templates and configurations
├── Localization/         # Internationalization files
├── Stages/               # Game stages/scenes
│   ├── Game/             # Main game scenes
│   └── UI/               # UI scenes
└── Utilities/            # Utility scripts and tools
```

### Key Files
- **Main Scene**: `Stages/Game/main/main.tscn` - Primary game scene
- **Project File**: `project.godot` - Godot project configuration
- **Enemy Template**: `Entities/Enemies/Templates/base_enemy/enemy.tscn`
- **UI Scene**: `Stages/UI/main_ui/ui.tscn`

## Game Testing and Controls

### Manual Testing Scenarios

1. **Basic Game Launch**:
   ```bash
   ./godot --path . "res://Stages/Game/main/main.tscn"
   ```

2. **Game Controls**:
   - **Mouse**: Camera movement and targeting
   - **Left Click**: Place obstacles/towers
   - **WASD**: Alternative camera controls (if implemented)
   - **ESC**: Pause/menu (if implemented)

3. **Testing Checklist**:
   - [ ] Game loads without errors
   - [ ] 3D models render correctly
   - [ ] Enemy spawning works
   - [ ] Obstacle placement functions
   - [ ] Health system responds correctly
   - [ ] UI elements display properly

## Development Guidelines

### Template + Config Pattern
The project uses a Template + Config architecture:
- **Templates**: Base entity scenes in `Entities/*/Templates/`
- **Configs**: Configuration resources in `Config/`
- **Components**: Reusable components in `Common/Components/`

### Script Class Registration
- Scripts use proper class_name declarations
- Registration happens during asset import
- Restart Godot if class recognition issues occur

### Coding Standards (Enforced by CI/CD)
- **Indentation**: 2 spaces (no tabs)
- **Line Length**: Maximum 100 characters
- **Naming Conventions**:
  - Variables/functions: `snake_case`
  - Classes: `PascalCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Signals: `snake_case`
- **Class Organization**: Follow gdlint order (extends, exports, signals, etc.)
- **No Trailing Whitespace**: Automatically enforced
- **File Encoding**: UTF-8 with LF line endings

### Asset Management
- **Large Assets**: Excluded from git (*.blend, *.blend1)
- **Import Files**: Keep .import files for proper asset handling
- **3D Models**: Require full asset import for proper rendering

## Troubleshooting

### Common Issues and Solutions

1. **"Script class not found" errors**:
   - Ensure complete asset import finished
   - Restart Godot editor
   - Check class_name declarations in scripts

2. **3D models not rendering**:
   - Verify asset import completed (15+ minutes)
   - Check suzanne.blend exists in Assets/Models/
   - Ensure .import files are present

3. **Performance Issues**:
   - Asset import: 15+ minutes (normal)
   - Game launch: 2-3 seconds (normal)
   - Scene loading: < 1 second (normal)

### Build and Test Commands

1. **Asset Import Validation**:
   ```bash
   # Check for import completion
   ls -la .godot/imported/
   ```

2. **Headless Testing**:
   ```bash
   # Test scene loading without GUI
   ./godot --headless --path . "res://Stages/Game/main/main.tscn"
   ```

3. **Error Checking**:
   ```bash
   # Run with debug output
   ./godot --path . --verbose "res://Stages/Game/main/main.tscn"
   ```

## CI/CD Notes

### Automated Quality Checks

The project now includes comprehensive CI/CD pipelines for code quality assurance:

#### Linting and Static Analysis Workflow
- **Workflow File**: `.github/workflows/lint.yml`
- **Triggers**: Push/PR to `main` or `develop` branches
- **Jobs**:
  1. **GDScript Syntax Check**: Uses Godot 4.4's built-in `--check-only` to validate script syntax
  2. **GDScript Formatting**: Uses `gdformat` to ensure consistent code formatting
  3. **GDScript Linting**: Uses `gdlint` for style and best practice enforcement
  4. **EditorConfig Compliance**: Validates files follow `.editorconfig` rules
  5. **Project Validation**: Tests that the main scene loads without errors

#### Code Quality Tools

1. **gdformat** (GDScript Formatter):
   - Configuration: `gdformatrc`
   - Enforces 2-space indentation, 100-character line length
   - Removes trailing whitespace, ensures consistent spacing
   - Run locally: `gdformat --check --diff .` or `gdformat .` to fix

2. **gdlint** (GDScript Linter):
   - Configuration: `gdlintrc`
   - Validates naming conventions, class structure, complexity metrics
   - Checks for code smells and best practices
   - Run locally: `gdlint .`

3. **EditorConfig**:
   - Configuration: `.editorconfig`
   - Enforces consistent indentation, encoding, line endings
   - Supports GDScript, TSCN, TRES, and documentation files

### Local Development Workflow

1. **Setup Development Tools**:
   ```bash
   pip install gdtoolkit  # Installs gdformat and gdlint
   ```

2. **Pre-commit Checks** (recommended):
   ```bash
   # Format code
   gdformat .
   
   # Check linting
   gdlint .
   
   # Validate with Godot
   ./godot --headless --check-only --script path/to/file.gd
   ```

3. **Fix Common Issues**:
   - **Formatting**: Run `gdformat .` to auto-fix spacing and indentation
   - **Trailing Whitespace**: Automatically handled by gdformat
   - **Naming Conventions**: Follow snake_case for variables/functions, PascalCase for classes
   - **Class Structure**: Organize class members in the order defined by gdlint

### CI/CD Integration

- **Status Checks**: All jobs must pass before merging
- **Automated Asset Import**: CI handles Godot asset import for script validation
- **Parallel Execution**: Multiple quality checks run simultaneously for faster feedback
- **Detailed Reporting**: Clear error messages with suggestions for fixes

**Manual testing still required** - use validation scenarios below for comprehensive testing.

**Build and validation scripts** - use the CI workflow commands locally for testing.

## Important Reminders

1. **Asset Import**: Always allow 15+ minutes for initial import
2. **Large Files**: Excluded from git via .gitignore
3. **Manual Testing**: Required for all changes
4. **Class Registration**: Happens during asset import
5. **3D Models**: Require complete import for rendering

This project requires patience during setup but provides a solid foundation for 3D tower defense development with Godot 4.4.