# Tech Tree Editor Plugin

A visual graph-based editor for authoring and managing the tech tree in Zom Nom Defense.

## Features

### Visual Graph Editor
- **Interactive Graph**: Drag and drop tech nodes, zoom, and pan
- **Branch Color Coding**: Each branch has a distinct color
  - Offensive: Red (#E74C3C)
  - Defensive: Blue (#3498DB)
  - Economy: Green (#2ECC71)
  - Support: Yellow (#F39C12)
  - Click: Purple (#9B59B6)
  - Advanced: Gold (#F1C40F)
- **Connection Management**: Click and drag to create prerequisite connections
- **Auto-Layout**: Automatically organize nodes by branch and level

### Node Inspector
Edit all properties of a selected tech node:
- ID (unique identifier)
- Display Name
- Description
- Branch (dropdown selection)
- Level Requirement (1-10)
- Prerequisites (comma-separated tech IDs)
- Achievements (comma-separated achievement IDs)
- Mutually Exclusive (comma-separated tech IDs)
- Unlocked Obstacles (comma-separated obstacle IDs)
- Branch Completion Requirements (comma-separated branch names)

### Validation Engine
Comprehensive validation checks:
- ✓ ID uniqueness
- ✓ Circular dependency detection
- ✓ Prerequisite existence verification
- ✓ Mutual exclusivity bidirectional validation
- ✓ Branch completion reference validation
- ✓ ID prefix consistency

### Export & Documentation
- Export tech tree to Markdown format
- Includes validation report
- Copy to clipboard or save to file

## Usage

### Opening the Editor
1. Enable the plugin in Project Settings → Plugins
2. The Tech Tree Editor dock will appear in the top-left corner of the editor

### Creating a New Tech Node
1. Click the "Add Node" button in the toolbar, or
2. Right-click in the graph and select "Add Tech Node"
3. Fill in the required fields (ID, Display Name, Branch, Level)
4. Click OK

### Editing a Tech Node
1. Click on a node in the graph to select it
2. The inspector panel will appear at the bottom
3. Edit any property
4. Click "Save Changes" to persist

### Adding Prerequisites
1. Click and drag from one node to another in the graph
2. The connection represents a prerequisite relationship
3. Changes are automatically saved

### Deleting Prerequisites
1. Right-click a connection line
2. Select "Disconnect"
3. Or edit the Prerequisites field in the inspector

### Deleting a Tech Node
1. Select one or more nodes
2. Press Delete key or right-click and select Delete
3. Confirm the deletion (warnings will show if dependencies exist)

### Validating the Tech Tree
1. Click the "Validate" button in the toolbar
2. Review any errors in the validation panel
3. Fix errors and validate again

### Exporting to Markdown
1. Click "Export Markdown" in the toolbar
2. Review the generated documentation
3. Copy to clipboard or save to file

### Search and Filter
- Use the search box to filter by ID or name
- Use the branch dropdown to show only specific branches
- Click "Refresh" to reload from disk

### Auto-Layout
1. Right-click in the graph
2. Select "Auto-Layout Graph"
3. Nodes will be organized by branch and level

## File Structure

```
addons/tech_tree_editor/
├── plugin.cfg              # Plugin metadata
├── plugin.gd               # EditorPlugin entry point
├── ui/
│   ├── tech_tree_editor_dock.tscn   # Main UI scene
│   └── tech_tree_editor_dock.gd     # Main UI logic
└── icons/
    └── plugin_icon.svg     # Plugin icon
```

## Data Model

Tech nodes are stored as `.tres` resource files in `Config/TechTree/`. Each file contains a `TechNodeResource` with the following properties:

```gdscript
@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var branch_name: String
@export var level_requirement: int
@export var scrap_cost: int
@export var prerequisite_tech_ids: Array[String]
@export var achievement_ids: Array[String]
@export var mutually_exclusive_with: Array[String]
@export var requires_branch_completion: Array[String]
@export var unlocked_obstacle_ids: Array[String]
```

## ID Naming Conventions

Tech node IDs should follow these prefixes based on branch:
- **Offensive**: `tur_` (e.g., `tur_scrap_shooter`)
- **Defensive**: `ob_` (e.g., `ob_crates`)
- **Economy**: `eco_` (e.g., `eco_scrap_recycler`)
- **Support**: `sup_` (e.g., `sup_overcharger`)
- **Click**: `clk_` (e.g., `clk_hydraulic_mouse`)
- **Advanced**: `adv_` (e.g., `adv_experimental_weapons`)

## Validation Rules

1. **ID Uniqueness**: No duplicate node IDs
2. **Prerequisite Existence**: All prerequisite IDs must reference existing nodes
3. **No Circular Dependencies**: Prerequisite chains cannot loop back
4. **Mutual Exclusivity**: If A excludes B, B must exclude A
5. **Branch Completion**: Branch names must be valid (Offensive/Defensive/Economy/Support/Click/Advanced)
6. **ID Prefix Consistency**: IDs should follow branch naming conventions

## Tips

- Use the minimap (bottom-right of graph) for navigation in large trees
- Save frequently - changes are only persisted when you click "Save Changes"
- Run validation before committing changes
- Use the export feature to document the tech tree for designers
- The validation panel can be closed without fixing all errors, but it's recommended to address them

## Troubleshooting

**Plugin doesn't appear after enabling:**
- Restart the Godot editor
- Check the console for error messages

**Changes not saving:**
- Make sure to click "Save Changes" in the inspector
- Check file permissions on Config/TechTree/

**Validation errors:**
- Review the validation panel for detailed error messages
- Fix one error at a time and re-validate

**Graph is cluttered:**
- Use the search/filter to focus on specific nodes
- Use Auto-Layout to organize nodes
- Adjust zoom level

## Future Enhancements

Potential improvements for future versions:
- Undo/redo support
- Keyboard shortcut for Save (Ctrl+S)
- Batch editing of multiple nodes
- Import from Markdown
- Diff viewer for comparing tree versions
- Custom node templates
- Visual indicators for achievement requirements
- Branch completion gate visualization
