# Tech Tree Editor Plugin - Quick Start Guide

## 5-Minute Setup

### Step 1: Enable the Plugin
1. Open your project in Godot 4.4
2. Go to **Project** → **Project Settings** → **Plugins**
3. Find **Tech Tree Editor** in the list
4. Check the **Enable** checkbox
5. Close the Project Settings window

### Step 2: Open the Editor
- The **Tech Tree Editor** dock will appear in the **top-left corner** of the editor
- You should see a graph with existing tech nodes

### Step 3: Your First Edit
1. **Click on any node** in the graph to select it
2. The **Inspector Panel** will appear at the bottom
3. Try changing the **Display Name** field
4. Click **Save Changes**
5. The graph will update automatically

### Step 4: Create a New Node
1. Click the **Add Node** button in the toolbar (or press **Ctrl+N**)
2. Fill in the required fields:
   - **ID**: `tur_my_turret` (must be unique)
   - **Display Name**: `My Custom Turret`
   - **Branch**: Select `Offensive`
   - **Level**: `1`
3. Click **OK**
4. Your new node appears in the graph!

### Step 5: Validate Your Changes
1. Click the **Validate** button (or press **Ctrl+V**)
2. Check for any errors in the validation panel
3. Fix any issues and validate again
4. Green checkmark = ready to commit!

## Common Tasks

### Connect Prerequisites
**Drag from prerequisite node → to dependent node**

Example: Drag from `tur_scrap_shooter` to `tur_boom_barrel` to make the shooter a prerequisite.

### Search for a Node
1. Type in the **search box** (top-right)
2. Or press **Ctrl+F** to focus search
3. Enter node ID or name

### Filter by Branch
Use the **branch dropdown** (next to search) to show only nodes from one branch.

### Export Documentation
1. Click **Export Markdown** (or press **Ctrl+E**)
2. Click **Copy to Clipboard**
3. Paste into your design doc!

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+R** | Refresh from disk |
| **Ctrl+N** | Create new node |
| **Ctrl+V** | Validate tree |
| **Ctrl+E** | Export markdown |
| **Ctrl+F** | Focus search |
| **Ctrl+L** | Auto-layout graph |
| **Delete** | Delete selected node(s) |

## Tips

💡 **Use Auto-Layout** - Right-click in the graph → Auto-Layout to organize messy nodes

💡 **Color Legend** - Node colors represent branches:
- 🔴 Red = Offensive
- 🔵 Blue = Defensive  
- 🟢 Green = Economy
- 🟡 Yellow = Support
- 🟣 Purple = Click
- 🟡 Gold = Advanced

💡 **Save Often** - Changes are only saved when you click "Save Changes" in the inspector

💡 **Validate Before Commit** - Always run validation before committing changes to git

## Troubleshooting

**Plugin doesn't appear?**
- Make sure you enabled it in Project Settings → Plugins
- Restart the Godot editor

**Changes not saving?**
- Did you click "Save Changes" in the inspector?
- Check the status bar for error messages

**Graph is messy?**
- Right-click → Auto-Layout Graph
- Or use search/filter to focus on specific nodes

## Need Help?

📖 See the full [README.md](README.md) for detailed documentation  
🧪 See [TESTING.md](TESTING.md) for the complete testing guide

## Example Workflow

1. **Morning**: Enable plugin and review existing tech tree
2. **Create**: Add 3 new tech nodes for a new feature
3. **Connect**: Link prerequisites by dragging connections
4. **Validate**: Run validation to catch errors
5. **Export**: Generate markdown for design review
6. **Commit**: Save .tres files to git

Happy editing! 🎮
