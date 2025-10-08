# Buildable Area System

## Overview

The buildable area system restricts where players can place obstacles/towers in a level. This ensures gameplay balance and prevents placing obstacles in unintended locations such as near enemy spawners or map edges.

## How It Works

The buildable area is defined by an **Area3D** node in each level. Obstacles can only be placed within this area's collision shape. This approach allows level designers to create buildable zones that are **smaller** than the navigation region, keeping spawners and map edges clear for enemy pathfinding.

### Why Area3D?

Using Area3D for the buildable area has several advantages:
- **Precise control**: Define exact boundaries separate from navigation mesh
- **Smaller than navigation**: Keep enemy spawners and map edges clear
- **Visual editing**: Level designers can see and edit the buildable area in the Godot editor
- **Flexible shapes**: Use any collision shape (box, polygon, compound shapes)
- **Optional**: If not defined, placement is allowed anywhere (backward compatible)
- **Performance**: Uses efficient physics point queries

## For Level Designers

### Setting Up a Buildable Area

The buildable area is now **automatically coordinated per-level** through the GameManager singleton. Each level registers its buildable area with GameManager when it loads, and ObstaclePlacement retrieves it automatically.

**Simple Setup (Recommended):**

1. **Add an Area3D** to your level scene as a child of the Level node
   ```
   Level (Level.gd)
   ├── BuildableArea (Area3D)
   │   └── CollisionShape3D (BoxShape3D, or any shape)
   ├── NavigationRegion3D
   ├── EnemySpawner
   └── ... other level components
   ```

2. **Configure the Area3D**:
   - Add a CollisionShape3D as a child
   - Choose an appropriate shape (BoxShape3D for rectangular areas, or custom polygon shapes)
   - Set the collision layer (e.g., layer 8 for buildable areas)
   - Position and scale the shape to define your buildable zone
   - **Important**: Make this area **smaller** than the NavigationRegion3D to keep spawners and edges clear

3. **Assign to Level**: 
   - Select the Level node
   - In the inspector, find the `buildable_area` export variable
   - Assign your BuildableArea node

4. **That's it!** Level automatically registers with GameManager, and ObstaclePlacement retrieves it

**Advanced Setup (Manual Override):**

If you need to override the buildable area for a specific ObstaclePlacement instance, you can still manually assign it:
- Select the ObstaclePlacement node
- In the inspector, assign a different Area3D to its `buildable_area` property

Example scene structure:
```
Level (Level.gd with buildable_area export)
├── NavigationRegion3D (defines enemy pathfinding area - larger)
├── BuildableArea (Area3D - smaller, inset from edges)
│   └── CollisionShape3D (BoxShape3D)
├── EnemySpawner (outside buildable area)
└── ... other level components
```

**How Coordination Works:**
1. Level loads and calls GameManager.set_level_buildable_area() in _ready()
2. GameManager stores the buildable area and emits buildable_area_changed signal
3. ObstaclePlacement retrieves buildable area from GameManager in _ready()
4. ObstaclePlacement listens for buildable_area_changed signal for dynamic updates
5. This centralized coordination through GameManager ensures clean separation of concerns!

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

**If a Level has buildable_area set:**
- Level registers it with GameManager in _ready()
- ObstaclePlacement retrieves it from GameManager
- Placement restricted to the defined area
- Green preview inside, red preview outside

**If no buildable area is defined:**
- GameManager stores null for buildable area
- ObstaclePlacement receives null from GameManager
- System allows placement anywhere (backward compatible)
- Existing levels without Area3D continue to work
- New levels can opt-in by adding an Area3D and assigning it to the Level's buildable_area property

## For Programmers

### Coordination Flow

The buildable area system uses **GameManager as a central coordinator** for cleaner separation of concerns:

**Level Registration:**
```gdscript
# In Level._ready()
func _ready() -> void:
  # Register buildable area with GameManager for centralized coordination
  GameManager.set_level_buildable_area(buildable_area)
  # ... other initialization
```

**GameManager API:**
```gdscript
# In GameManager (singleton)
var current_level_buildable_area: Area3D = null
signal buildable_area_changed(buildable_area: Area3D)

func set_level_buildable_area(buildable_area: Area3D):
  if current_level_buildable_area != buildable_area:
    current_level_buildable_area = buildable_area
    buildable_area_changed.emit(buildable_area)

func get_level_buildable_area() -> Area3D:
  return current_level_buildable_area
```

**ObstaclePlacement Retrieval:**
```gdscript
# In ObstaclePlacement._ready()
func _ready():
  # Get buildable area from GameManager if not explicitly set
  if not buildable_area:
    buildable_area = GameManager.get_level_buildable_area()
    if buildable_area:
      Logger.info("Placement", "Retrieved buildable area from GameManager")
  
  # Listen for buildable area changes from GameManager
  GameManager.buildable_area_changed.connect(_on_buildable_area_changed)

func _on_buildable_area_changed(new_buildable_area: Area3D):
  # Update buildable area when GameManager signals a change
  if not buildable_area or buildable_area == GameManager.get_level_buildable_area():
    buildable_area = new_buildable_area
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

The `_is_within_buildable_area()` method uses physics point queries:

```gdscript
func _is_within_buildable_area(target_position: Vector3) -> bool:
  # If no buildable area is defined, allow placement anywhere (legacy behavior)
  if not buildable_area:
    return true
  
  # Use physics point query to check if position is within the buildable area
  var space_state = get_world_3d().direct_space_state
  var query = PhysicsPointQueryParameters3D.new()
  query.position = target_position
  query.collision_mask = buildable_area.collision_layer
  
  var results = space_state.intersect_point(query)
  
  # Check if any of the results is our buildable area
  for result in results:
    if result.collider == buildable_area:
      return true
  
  return false
```

**Key Points:**
1. Returns `true` if no buildable area is set (backward compatible)
2. Uses GameManager as central coordinator instead of searching scene tree
3. Listens for buildable_area_changed signal for dynamic updates
4. Uses `PhysicsPointQueryParameters3D` for efficient point-in-area check
5. Checks collision layer match to ensure correct area is detected
6. Works with any collision shape (box, sphere, polygon, compound)
7. Can be manually overridden per-ObstaclePlacement instance if needed

### Extending the System

To implement more advanced buildable areas:

1. **Multiple regions**: Use multiple Area3D nodes with compound collision shapes
2. **Dynamic shapes**: Modify collision shapes at runtime and call GameManager.set_level_buildable_area() to update
3. **Exclusion zones**: Use negative space or additional validation checks
4. **Custom validation**: Override `_is_within_buildable_area()` for custom logic
5. **Level transitions**: GameManager automatically coordinates buildable area when levels change

### Error Handling

If buildable area is set in Level but placement is outside:
- `_is_within_buildable_area()` returns `false`
- Placement validation fails with `OUTSIDE_NAVIGATION_REGION` error
- User sees red preview and cannot place obstacle

If no buildable area is set in Level:
- Level registers null with GameManager
- ObstaclePlacement receives null from GameManager
- `_is_within_buildable_area()` returns `true` (backward compatible)
- No restriction on placement area

## Testing

### Manual Testing

1. **Without buildable area** (legacy mode):
   - Load a level without a buildable area defined
   - Attempt to place an obstacle anywhere → Should work (backward compatible)

2. **With buildable area**:
   - Create an Area3D with a BoxShape3D collision shape
   - Assign it to ObstaclePlacement's `buildable_area` property
   - Inside the area: Should show green preview and allow placement
   - Outside the area: Should show red preview and prevent placement

3. **Design verification**:
   - Ensure buildable area is smaller than navigation region
   - Check spawners are outside the buildable area
   - Verify map edges have clearance from buildable area

## Performance Considerations

- **Validation frequency**: Called on every mouse movement during placement (via `_update_visual_feedback`)
- **Performance impact**: Minimal - uses efficient physics point query
- **Optimization**: Consider caching buildable area checks if performance issues arise

## Related Systems

- **ObstaclePlacement**: Main placement system (`Utilities/Placement/obstacle_placement/`)
- **PlacementResult**: Validation result with error types (`placement_result.gd`)
- **NavigationRegion3D**: Godot's built-in navigation system
- **ObstaclePreview**: Visual feedback during placement (`obstacle_preview.gd`)

## Configuration Options

Available in `GameManager` singleton (automatic coordination):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `current_level_buildable_area` | Area3D | null | Current level's buildable area (set by Level) |

Available in `Level` node (per-level configuration):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `buildable_area` | Area3D | null | Defines the buildable area (optional, smaller than navigation region) |
| `enemy_spawner` | EnemySpawner | null | Reference to enemy spawner |
| `ui` | Control | null | Reference to UI |

Available in `ObstaclePlacement` node (usually auto-configured):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `buildable_area` | Area3D | null | Defines the buildable area (retrieved from GameManager, or manually set) |
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
