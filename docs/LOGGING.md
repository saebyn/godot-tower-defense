# Logging Framework Documentation

This document describes the logging framework implemented for the Tower Defense game, providing scoped logging with configurable log levels.

## Overview

The logging framework provides:
- **Scoped Logging**: Messages organized by scope (e.g., "Economy", "Combat", "UI")
- **Log Levels**: DEBUG, INFO, WARN, ERROR, NONE
- **Runtime Configuration**: Change log levels and scopes at runtime via console commands
- **Rich Output**: Colored, timestamped log messages
- **Project Settings Integration**: Configure defaults in project settings

## Basic Usage

### Simple Logging
```gdscript
# Basic logging at different levels
MyLogger.debug("Combat", "Calculating damage: %d" % damage)
MyLogger.info("Player", "Player spawned with %d health" % health)
MyLogger.warn("Economy", "Currency running low: %d remaining" % currency)
MyLogger.error("System", "Failed to load config: %s" % config_path)
```

### Hierarchical Scopes
```gdscript
# Use dot notation for hierarchical scopes
MyLogger.debug("Enemy.AI", "Choosing target")
MyLogger.debug("Enemy.Combat", "Attacking target")
MyLogger.debug("Enemy.Animation", "Playing attack animation")
MyLogger.info("UI.Health", "Updating health display")
```

## Log Levels

| Level | Description | When to Use |
|-------|-------------|-------------|
| `DEBUG` | Detailed diagnostic information | Development debugging, verbose tracing |
| `INFO` | General informational messages | Important game events, state changes |
| `WARN` | Warning conditions | Recoverable errors, deprecated usage |
| `ERROR` | Error conditions | Unrecoverable errors, critical failures |
| `NONE` | Disable all logging | Production builds, performance testing |

## Scope Filtering

### Wildcard Patterns
```gdscript
# Enable all Combat-related logging
MyLogger.set_enabled_scopes(["Combat*"])
# This will show: "Combat", "Combat.Attack", "Combat.Defense", etc.

# Enable specific scopes
MyLogger.set_enabled_scopes(["Player", "Economy", "UI"])
# Only these exact scopes will be shown

# Enable everything
MyLogger.set_enabled_scopes(["*"])
```

### Common Scope Conventions

| Scope | Usage |
|-------|-------|
| `Player` | Player actions, input handling |
| `Enemy` | Enemy behavior, AI |
| `Combat` | Damage, attacks, health |
| `Economy` | Currency, resources |
| `UI` | User interface updates |
| `Navigation` | Pathfinding, movement |
| `Spawner` | Enemy/object spawning |
| `Placement` | Object placement validation |
| `System` | Core system operations |

## Project Settings Configuration

Add these settings to your `project.godot`:

```ini
[logging]

log_level=1  # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR, 4=NONE
enabled_scopes="*"  # Comma-separated scopes or "*" for all
```

## Runtime Configuration

### Console Commands

The MyLogger provides console commands for runtime configuration:

| Command | Example | Description |
|---------|---------|-------------|
| `log_level` | `log_level DEBUG` | Set current log level |
| `log_scopes` | `log_scopes Economy,Combat` | Set enabled scopes |
| `log_info` | `log_info` | Show current configuration |

### Programmatic Configuration

```gdscript
# Change log level at runtime
MyLogger.set_log_level(MyLogger.LogLevel.DEBUG)

# Change enabled scopes
MyLogger.set_enabled_scopes(["Economy", "Combat"])

# Add/remove individual scopes
MyLogger.enable_scope("NewFeature")
MyLogger.disable_scope("OldFeature")

# Get current configuration
var config = MyLogger.get_config()
print("Current level: ", config.log_level_name)
print("Enabled scopes: ", config.enabled_scopes)
```

## Integration Example

Here's how to integrate the MyLogger with your existing console system:

```gdscript
extends Node

func handle_console_input(command_line: String):
    var parts = command_line.split(" ")
    var command = parts[0]
    var args = PackedStringArray(parts.slice(1))
    
    # Try MyLogger commands first
    if MyLogger.handle_console_command(command, args):
        return true
    
    # Handle other game commands
    match command:
        "spawn":
            # Your spawn command
            pass
        "teleport":
            # Your teleport command
            pass
    
    return false
```

## Performance Considerations

- Log level checking is very fast - disabled levels have minimal overhead
- Scope checking uses string operations - use sparingly in tight loops
- Consider using DEBUG level for verbose logging that can be disabled in production
- The framework emits signals for custom log handlers (file logging, network logging, etc.)

## Migration from print()

Replace existing print statements:

```gdscript
# Before
print("Enemy spawned at: ", position)
print("Currency earned: ", amount)

# After  
MyLogger.info("Spawner", "Enemy spawned at: %s" % position)
MyLogger.info("Economy", "Currency earned: %d" % amount)
```

## Advanced Features

### Signal-Based Logging
```gdscript
func _ready():
    # Connect to log signals for custom handling
    MyLogger.log_message_emitted.connect(_on_log_message)

func _on_log_message(level: MyLogger.LogLevel, scope: String, message: String, timestamp: String):
    # Custom handling (save to file, send to server, etc.)
    pass
```

### Conditional Logging
```gdscript
# Expensive operations only when debug logging is enabled
if MyLogger.current_log_level <= MyLogger.LogLevel.DEBUG:
    var detailed_info = expensive_debug_calculation()
    MyLogger.debug("System", "Detailed info: %s" % detailed_info)
```

## Examples from Codebase

The framework is already integrated throughout the codebase:

- **Currency System**: `MyLogger.info("Economy", "Earned %d currency")` 
- **Enemy Spawning**: `MyLogger.info("Spawner", "Starting wave %d")`
- **Combat**: `MyLogger.debug("Enemy.Combat", "Enemy took %d damage")`
- **Navigation**: `MyLogger.debug("Navigation", "Rebaking navigation mesh")`
- **Placement**: `MyLogger.warn("Placement", "Cannot place obstacle")`

## Testing

Use the provided test scenes:
- `test_logger.tscn` - Basic logging functionality test
- `console_test.tscn` - Console command interface test

Run these to verify the logging framework is working correctly in your environment.