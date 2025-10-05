# Tower Defense

A 3D tower defense game built with Godot 4.4.

## Overview

This is a work-in-progress 3D tower defense game featuring:
- 3D environment with dynamic camera controls
- Enemy AI with pathfinding navigation
- Destructible targets
- Orthogonal camera view optimized for strategy gameplay
- Obstacle/tower placement system with buildable area restrictions

## Controls

- **Camera Movement**: WASD keys
  - W: Move camera up
  - A: Move camera left  
  - S: Move camera right
  - R: Move camera down
- **Camera Rotation**: Q/F keys
  - Q: Rotate camera left (90°)
  - F: Rotate camera right (90°)
- **Camera Zoom**: Mouse wheel
  - Mouse wheel up: Zoom in
  - Mouse wheel down: Zoom out

## Getting Started

### Prerequisites

- [Godot Engine 4.4](https://godotengine.org/download) or later

### Running the Game

1. Clone this repository
2. Open the project in Godot by importing the `project.godot` file
3. Press F5 or click the "Play" button to run the game

## Project Structure

### Overview

This project uses a feature-based folder structure that prioritizes intuitive organization and co-location of related files. The structure is designed to scale from prototype to full game with 15+ enemy types, 20+ obstacle types, multiple levels, and complex progression systems.

### Top-Level Folders

```
Assets/         # Pure art and audio assets
Common/         # Reusable components and shared UI elements
Config/         # Data-driven configuration files (.tres resources)
Entities/       # Game objects (enemies, obstacles, player systems)
Localization/   # Translation files
Stages/         # Scenes and levels (main game, menus, levels)
Utilities/      # Systems, autoloads, and helper scripts
```

### Key Design Principles

#### 1. **Co-location of Coupled Files**
Related files stay together in their own folders:
```
Common/Effects/shake_effect/
├── shake_effect.tscn
└── shake_effect.gd
```

#### 2. **Template + Config Pattern**
Game entities use a composition approach:
- **Templates** (`Entities/*/Templates/`) - Reusable scene structure and behavior
- **Configs** (`Config/*/`) - Data-driven parameters and stats
- **Concrete** (`Entities/*/Concrete/`) - Specific instances combining templates with configs

#### 3. **Clear Separation by Purpose**
- `Assets/` - Art, audio, models (no code)
- `Config/` - Pure data files for balancing and content
- `Common/` - Truly reusable components across entities
- `Utilities/` - Global systems and autoloads
- `Entities/` - Game-specific objects with their logic
- `Stages/` - Complete scenes and levels

#### 4. **Centralized Game State Management**
Game state and coordination is handled through autoloaded singletons:
- **Logger** - Centralized logging with scope-based filtering
- **CurrencyManager** - Player currency tracking and transactions
- **GameManager** - Game state transitions and high-level coordination

### Example Structure

```
Config/Enemies/
├── grunt_config.tres      # Health: 100, Speed: 2.0, Damage: 15
└── scout_config.tres      # Health: 50, Speed: 4.0, Damage: 10

Entities/Enemies/
├── Templates/
│   └── base_enemy/
│       ├── base_enemy.tscn    # Common enemy structure
│       └── base_enemy.gd      # Common enemy behavior
└── Concrete/
    ├── grunt/
    │   └── grunt.tscn         # base_enemy + grunt_config
    └── scout/
        └── scout.tscn         # base_enemy + scout_config
```

### Benefits

- **Intuitive navigation** - Related files are always together
- **Scalable** - Easy to add new enemy types, levels, and features
- **Data-driven** - Non-programmers can create content via config files
- **Team-friendly** - Clear separation of artist, designer, and programmer work areas
- **Maintainable** - No hunting across multiple folders for related files

This structure supports the planned features including multiple levels, wave-based enemies, tech trees, economy systems, and sandbox mode while keeping the codebase organized and approachable.

## Development

This project is in early development. Current features include:
- Basic camera controls
- Enemy AI pathfinding
- Obstacle/tower placement with buildable area validation
- Visual feedback for valid/invalid placement

Future planned features may include:
- Tower upgrading and management
- Multiple enemy types
- Wave-based gameplay
- Resource management
- Level progression

See [docs/BUILDABLE_AREA.md](docs/BUILDABLE_AREA.md) for information about the buildable area system.

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

This is a personal learning project, but feedback and suggestions are welcome through issues.
