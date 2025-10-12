# Buildable Area System

## Overview

The buildable area system restricts where players can place obstacles/towers in a level. This ensures gameplay balance and prevents placing obstacles in unintended locations such as near enemy spawners or map edges.

## How It Works

The buildable area is defined by a **2D bounding box (Rect2)** in the XZ plane. Obstacles can only be placed within this rectangular area. This approach allows level designers to create buildable zones that are **smaller** than the navigation region, keeping spawners and map edges clear for enemy pathfinding.

### Why 2D Bounding Box?

Using a simple Rect2 for the buildable area has several advantages:
- **Simple and efficient**: No physics engine queries needed, just basic 2D point-in-rectangle check
- **Easy to configure**: Just define min/max X and Z coordinates
- **Smaller than navigation**: Keep enemy spawners and map edges clear
- **Visual editing**: Level designers can easily set bounds in the Godot inspector
- **Optional**: If not defined, placement is allowed anywhere (backward compatible)
- **Performance**: Lightweight AABB check instead of physics queries

## For Level Designers

### Setting Up a Buildable Area

The buildable area is now **automatically coordinated per-level** through the GameManager singleton. Each level registers its buildable area with GameManager when it loads, and ObstaclePlacement retrieves it automatically.

**Simple Setup (Recommended):**

1. **Define the bounding box** in your Level scene
   - Select the Level node
   - In the inspector, find the `buildable_area_bounds` property (Rect2)
   - Set the values:
     - **Position (x, y)**: Minimum X and Z coordinates (bottom-left corner)
     - **Size (width, height)**: Width and depth of the buildable area
   
   Example: `Rect2(-20, -15, 40, 30)` creates a 40x30 area centered roughly at the origin

2. **Calculate from your level**:
   - Measure your navigation region size
   - Inset by 5-10 units from spawners and edges
   - **Important**: Make this area **smaller** than the NavigationRegion3D

3. **That's it!** Level automatically registers with GameManager, and ObstaclePlacement retrieves it

**Advanced Setup (Manual Override):**

If you need to override the buildable area for a specific ObstaclePlacement instance, you can still manually set it:
- Select the ObstaclePlacement node
- In the inspector, set a different Rect2 to its `buildable_area_bounds` property

Example scene structure:
```
Level (Level.gd with buildable_area_bounds: Rect2)
├── NavigationRegion3D (defines enemy pathfinding area - larger)
├── EnemySpawner (outside buildable area)
└── ... other level components
```

**How Coordination Works:**
1. Level loads and calls GameManager.set_level_buildable_area() in _ready()
2. GameManager stores the buildable area bounds (Rect2) and emits buildable_area_changed signal
3. ObstaclePlacement retrieves buildable area bounds from GameManager in _ready()
4. ObstaclePlacement listens for buildable_area_changed signal for dynamic updates
5. This centralized coordination through GameManager ensures clean separation of concerns!

**Visual Layout:**
```
┌─────────────────────────────────────┐
│ NavigationRegion3D (Full Area)      │
│  ┌───────────────────────────────┐  │
│  │ Buildable Bounds (Rect2)     │  │
│  │  [Players place towers here]  │  │
│  └───────────────────────────────┘  │
│ [Enemy Spawner]      [Map Edge]     │
└─────────────────────────────────────┘
```

### Design Guidelines

**Size Relationship:**
- NavigationRegion3D: Full walkable area for enemies
- BuildableArea: Inset from edges and spawners
- Recommended: Keep at least 5-10 units clearance from spawners and map edges

**Example Layout:**
```
┌─────────────────────────────────────┐
│ NavigationRegion3D (Full Area)      │
│  ┌───────────────────────────────┐  │
│  │ BuildableArea (Inset)         │  │
│  │                               │  │
│  │  [Players place towers here]  │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│ [Enemy Spawner]      [Map Edge]     │
└─────────────────────────────────────┘
```

### Visual Feedback

When a player attempts to place an obstacle:
- **Green preview**: Valid placement (inside buildable area)
- **Red preview**: Invalid placement (outside buildable area or other validation failure)

### Optional Feature

The buildable area system is **automatically coordinated per-level through GameManager** but remains optional:

**If a Level has buildable_area_bounds set:**
- Level registers it with GameManager in _ready()
- ObstaclePlacement retrieves it from GameManager
- Placement restricted to the defined rectangular area
- Green preview inside, red preview outside

**If no buildable area is defined (Rect2 is empty):**
- GameManager stores empty Rect2 for buildable area
- ObstaclePlacement receives empty Rect2 from GameManager
- System allows placement anywhere (backward compatible)
- Existing levels without bounds continue to work
- New levels can opt-in by setting buildable_area_bounds in the Level's inspector

## For Programmers

### Coordination Flow

The buildable area system uses **GameManager as a central coordinator** for cleaner separation of concerns:

**Level Registration:**
```gdscript
# In Level._ready()
func _ready() -> void:
  # Register buildable area with GameManager for centralized coordination
  GameManager.set_level_buildable_area(buildable_area_bounds)
  # ... other initialization
```

**GameManager API:**
```gdscript
# In GameManager (singleton)
var current_level_buildable_area: Rect2 = Rect2()
signal buildable_area_changed(buildable_area: Rect2)

func set_level_buildable_area(buildable_area: Rect2):
  if current_level_buildable_area != buildable_area:
    current_level_buildable_area = buildable_area
    buildable_area_changed.emit(buildable_area)

func get_level_buildable_area() -> Rect2:
  return current_level_buildable_area
```

**ObstaclePlacement Retrieval:**
```gdscript
# In ObstaclePlacement._ready()
func _ready():
  # Get buildable area from GameManager if not explicitly set
  if buildable_area_bounds == Rect2():
    buildable_area_bounds = GameManager.get_level_buildable_area()
    if buildable_area_bounds != Rect2():
      Logger.info("Placement", "Retrieved buildable area from GameManager: %s" % buildable_area_bounds)
  
  # Listen for buildable area changes from GameManager
  GameManager.buildable_area_changed.connect(_on_buildable_area_changed)

func _on_buildable_area_changed(new_buildable_area: Rect2):
  # Update buildable area when GameManager signals a change
  if buildable_area_bounds == Rect2() or buildable_area_bounds == GameManager.get_level_buildable_area():
    buildable_area_bounds = new_buildable_area
```

The validation then checks:
```gdscript
func _validate_placement(target_position: Vector3) -> PlacementResult:
  if not _preview:
    return PlacementResult.new(false, ValidationError.NO_PLACEABLE_OBSTACLE, ...)
  
  # ✓ Buildable area check (coordinated through GameManager)
  if not _is_within_buildable_area(target_position):
    return PlacementResult.new(false, ValidationError.OUTSIDE_NAVIGATION_REGION, "Outside buildable area")
  
  # Other validations...
  if _has_obstacle_collision(target_position): ...
  if not _has_terrain_support(target_position): ...
  if not _has_sufficient_clearance(target_position): ...
  if insufficient_funds: ...
  
  return PlacementResult.new(true)
```

### Implementation Details

The `_is_within_buildable_area()` method uses simple 2D AABB math:

```gdscript
func _is_within_buildable_area(target_position: Vector3) -> bool:
  # If no buildable area is defined, allow placement anywhere (legacy behavior)
  if buildable_area_bounds == Rect2():
    return true
  
  # Simple 2D bounding box check in XZ plane (Y is vertical)
  # Convert 3D position to 2D point in XZ plane
  var point_2d = Vector2(target_position.x, target_position.z)
  
  # Check if point is within the rectangle bounds
  return buildable_area_bounds.has_point(point_2d)
```

**Key Points:**
1. Returns `true` if no buildable area is set (backward compatible)
2. Uses GameManager as central coordinator instead of searching scene tree
3. Listens for buildable_area_changed signal for dynamic updates
4. Simple 2D point-in-rectangle check - no physics engine needed
5. Lightweight and efficient - just basic AABB math
6. Works in XZ plane (horizontal), ignores Y coordinate (vertical)
7. Can be manually overridden per-ObstaclePlacement instance if needed

### Extending the System

To implement more advanced buildable areas:

1. **Multiple regions**: Use multiple Rect2 and check against each
2. **Dynamic bounds**: Modify buildable_area_bounds at runtime and call GameManager.set_level_buildable_area() to update
3. **Exclusion zones**: Use negative space or additional validation checks
4. **Custom validation**: Override `_is_within_buildable_area()` for custom logic
5. **Level transitions**: GameManager automatically coordinates buildable area when levels change

### Error Handling

If buildable area is set in Level but placement is outside:
- `_is_within_buildable_area()` returns `false`
- Placement validation fails with `OUTSIDE_BUILDABLE_AREA` error
- User sees red preview and cannot place obstacle

If no buildable area is set in Level:
- Level registers null with GameManager
- ObstaclePlacement receives null from GameManager
- `_is_within_buildable_area()` returns `true` (backward compatible)
- No restriction on placement area

## Testing

### Manual Testing

1. **Without buildable area** (legacy mode):
   - Load a level without buildable_area_bounds defined (empty Rect2)
   - Attempt to place an obstacle anywhere → Should work (backward compatible)

2. **With buildable area**:
   - Set buildable_area_bounds in Level node (e.g., `Rect2(-20, -15, 40, 30)`)
   - Inside the bounds: Should show green preview and allow placement
   - Outside the bounds: Should show red preview and prevent placement

3. **Design verification**:
   - Ensure buildable area bounds are smaller than navigation region
   - Check spawners are outside the buildable area bounds
   - Verify map edges have clearance from buildable area bounds

## Performance Considerations

- **Validation frequency**: Called on every mouse movement during placement (via `_update_visual_feedback`)
- **Performance impact**: Minimal - simple 2D point-in-rectangle check (no physics engine)
- **Optimization**: Already optimized - basic AABB math is very fast

## Related Systems

- **ObstaclePlacement**: Main placement system (`Utilities/Placement/obstacle_placement/`)
- **PlacementResult**: Validation result with error types (`placement_result.gd`)
- **NavigationRegion3D**: Godot's built-in navigation system
- **ObstaclePreview**: Visual feedback during placement (`obstacle_preview.gd`)
- **GameManager**: Singleton for centralized coordination

## Configuration Options

Available in `GameManager` singleton (automatic coordination):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `current_level_buildable_area` | Rect2 | Rect2() | Current level's buildable area bounds (set by Level) |

Available in `Level` node (per-level configuration):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `buildable_area_bounds` | Rect2 | Rect2() | Defines the buildable area (optional, 2D rectangle in XZ plane) |
| `enemy_spawner` | EnemySpawner | null | Reference to enemy spawner |
| `ui` | Control | null | Reference to UI |

Available in `ObstaclePlacement` node (usually auto-configured):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `buildable_area_bounds` | Rect2 | Rect2() | Defines the buildable area (retrieved from GameManager, or manually set) |
| `navigation_region` | NavigationRegion3D | null | Reference to navigation region for enemy pathfinding |
| `placement_clearance` | float | 3.0 | Minimum distance from other obstacles |

## Future Enhancements

Possible improvements:
- [ ] Multiple buildable regions per level (e.g., separate zones with different costs)
- [ ] Visual debug overlay showing buildable area boundaries in-game
- [ ] Per-obstacle-type buildable area restrictions
- [ ] Dynamic buildable areas that expand/shrink during gameplay
- [ ] Cost multipliers for different buildable zones
- [ ] Buildable area editor tool for easier level design
