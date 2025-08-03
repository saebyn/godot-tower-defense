# Tower Defense

A 3D tower defense game built with Godot 4.4.

## Overview

This is a work-in-progress 3D tower defense game featuring:
- 3D environment with dynamic camera controls
- Enemy AI with pathfinding navigation
- Destructible targets
- Orthogonal camera view optimized for strategy gameplay

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

- `main.gd` - Main scene controller with camera management
- `enemy.gd` - Enemy AI behavior and navigation
- `target.gd` - Destructible target objects
- `main.tscn` - Main game scene
- `enemy.tscn` - Enemy prefab
- `suzanne.blend` - 3D model asset

## Development

This project is in early development. Current features include basic camera controls and enemy AI pathfinding. Future planned features may include:
- Tower placement and management
- Multiple enemy types
- Wave-based gameplay
- Resource management
- Level progression

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

This is a personal learning project, but feedback and suggestions are welcome through issues.
