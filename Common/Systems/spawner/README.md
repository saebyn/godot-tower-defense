# Wave-Based Enemy Spawning System

The EnemySpawner now supports wave-based enemy spawning through child Wave nodes.

## How It Works

The EnemySpawner automatically detects its mode:
- **Legacy Mode**: No Wave children → uses the original timer-based spawning
- **Wave Mode**: Has Wave children → executes waves sequentially from top to bottom

## Using Wave Mode

1. Add Wave nodes as children to your EnemySpawner
2. Configure each Wave's properties:
   - `duration`: How long the wave lasts (seconds)
   - `start_delay`: Optional delay before wave starts (seconds)
   - `enemy_scenes`: Array of enemy PackedScenes to spawn
   - `enemy_counts`: Array of how many of each enemy type to spawn
   - `spawn_interval`: Time between individual enemy spawns (seconds)

## Example Setup

```
EnemySpawner
├── Wave1 (5 enemies over 10 seconds, 2 second delay)
├── Wave2 (8 enemies over 15 seconds, 1 second delay)
└── Wave3 (12 enemies over 20 seconds, no delay)
```

## Signals

The EnemySpawner emits these signals in wave mode:
- `wave_started(wave: Wave)`: When a wave begins
- `wave_completed(wave: Wave)`: When a wave finishes
- `all_waves_completed()`: When all waves are done
- `enemy_spawned(enemy: Node3D)`: When any enemy is spawned

## Wave Properties

Each Wave node can be configured with:
- Multiple enemy types (different PackedScenes)
- Different spawn counts for each enemy type
- Wave duration and spawn intervals
- Start delays for wave timing

## Backward Compatibility

Existing EnemySpawner usage continues to work unchanged. The system only switches to wave mode when Wave child nodes are detected.