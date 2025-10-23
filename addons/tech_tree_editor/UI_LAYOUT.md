# Tech Tree Editor Plugin - UI Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Tech Tree Editor                                                      [X]   │
├─────────────────────────────────────────────────────────────────────────────┤
│ Toolbar:                                                                    │
│ [Refresh] [Add Node] [Validate] [Export Markdown]    Filter: [____] [All▼] │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Graph View (GraphEdit):                                                   │
│                                                                             │
│   ┌─────────────────┐       ┌─────────────────┐                           │
│   │ Scrap Shooter   │       │ Stacked Crates  │                           │
│   │ tur_scrap_shooter│──────▶│ ob_crates       │                          │
│   │ Branch: Offensive│       │ Branch: Defensive│                         │
│   │ Level: 1        │       │ Level: 1        │                           │
│   │ Prerequisites: 0│       │ Prerequisites: 0│                           │
│   └─────────────────┘       └─────────────────┘                           │
│        │                                                                    │
│        │ prerequisite connection                                           │
│        ▼                                                                    │
│   ┌─────────────────┐                                                      │
│   │ Boom Barrel     │       ┌─────────────────┐                           │
│   │ tur_boom_barrel │ ×××××▶│ Molotov Mortar  │ mutually                  │
│   │ Branch: Offensive│      │ tur_molotov_mortar│ exclusive               │
│   │ Level: 2        │      │ Branch: Offensive│                           │
│   │ Prerequisites: 1│      │ Level: 4        │                           │
│   │ ⚠ Mutually      │      │ ⚠ Mutually      │                           │
│   │   Exclusive: 1  │      │   Exclusive: 1  │                           │
│   └─────────────────┘      └─────────────────┘                           │
│                                                                             │
│   [Right-click for context menu]                 [Minimap]                 │
│                                                   ┌─────┐                   │
│                                                   │ ▪▪  │                   │
│                                                   │▪▪▪  │                   │
│                                                   └─────┘                   │
├─────────────────────────────────────────────────────────────────────────────┤
│ Validation Panel (when errors exist):                                      │
│ ┌───────────────────────────────────────────────────────────────────────┐ │
│ │ Validation Errors:                                              [Close]│ │
│ │ • tur_new_node: Prerequisite 'tur_missing' does not exist            │ │
│ │ • eco_recycler: ID prefix should be 'eco_' for branch 'Economy'      │ │
│ └───────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│ Inspector Panel (when node selected):                                      │
│ ┌───────────────────────────────────────────────────────────────────────┐ │
│ │ Editing: Scrap Shooter                                                │ │
│ │ ─────────────────────────────────────────────────────────────────────│ │
│ │ ID:                    tur_scrap_shooter                              │ │
│ │ Display Name:          [Scrap Shooter                              ] │ │
│ │ Description:           ┌──────────────────────────────────────────┐ │ │
│ │                        │Basic bolt-firing turret. Starter tech    │ │ │
│ │                        │available immediately.                    │ │ │
│ │                        └──────────────────────────────────────────┘ │ │
│ │ Branch:                [Offensive        ▼]                           │ │
│ │ Level Requirement:     [1    ] (slider 1-10)                          │ │
│ │ Prerequisites:         ┌──────────────────────────────────────────┐ │ │
│ │                        │(comma-separated tech IDs)                │ │ │
│ │                        └──────────────────────────────────────────┘ │ │
│ │ Achievements:          ┌──────────────────────────────────────────┐ │ │
│ │                        │(comma-separated achievement IDs)         │ │ │
│ │                        └──────────────────────────────────────────┘ │ │
│ │ Mutually Exclusive:    ┌──────────────────────────────────────────┐ │ │
│ │                        │(comma-separated tech IDs)                │ │ │
│ │                        └──────────────────────────────────────────┘ │ │
│ │ Unlocked Obstacles:    ┌──────────────────────────────────────────┐ │ │
│ │                        │turret                                    │ │ │
│ │                        └──────────────────────────────────────────┘ │ │
│ │ Branch Completion:     ┌──────────────────────────────────────────┐ │ │
│ │                        │(comma-separated branch names)            │ │ │
│ │                        └──────────────────────────────────────────┘ │ │
│ │                                                                       │ │
│ │                        [Save Changes]                                 │ │
│ └───────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│ Status Bar:                                                                 │
│ Tech nodes: 5 | Errors: 0                                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Color Legend

When viewing in the actual Godot Editor, nodes are color-coded:

- 🔴 **Red** (#E74C3C) - Offensive branch
- 🔵 **Blue** (#3498DB) - Defensive branch
- 🟢 **Green** (#2ECC71) - Economy branch
- 🟡 **Yellow** (#F39C12) - Support branch
- 🟣 **Purple** (#9B59B6) - Click branch
- 🟡 **Gold** (#F1C40F) - Advanced branch

## Interactions

**Mouse:**
- **Left-click node** - Select and show inspector
- **Left-click empty space** - Deselect
- **Drag node** - Move position
- **Drag from node to node** - Create prerequisite connection
- **Right-click connection** - Disconnect
- **Right-click empty space** - Show context menu
- **Mouse wheel** - Zoom in/out
- **Middle-click drag** - Pan view

**Keyboard:**
- **Ctrl+R** - Refresh from disk
- **Ctrl+N** - Create new node
- **Ctrl+V** - Validate tree
- **Ctrl+E** - Export markdown
- **Ctrl+F** - Focus search box
- **Ctrl+L** - Auto-layout
- **Delete** - Delete selected node(s)

## Context Menu (Right-click)

```
┌────────────────────────────────┐
│ Add Tech Node (Ctrl+N)         │
│ ────────────────────────────── │
│ Auto-Layout Graph (Ctrl+L)     │
│ Reset Zoom                     │
│ ────────────────────────────── │
│ Validate (Ctrl+V)              │
│ Export Markdown (Ctrl+E)       │
└────────────────────────────────┘
```

## Workflow Example

1. **Open dock** - Plugin appears in top-left
2. **Select node** - Click "Scrap Shooter"
3. **Edit properties** - Change description in inspector
4. **Save** - Click "Save Changes"
5. **Create connection** - Drag to "Boom Barrel"
6. **Validate** - Press Ctrl+V
7. **Export** - Press Ctrl+E to document changes
