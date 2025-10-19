# Tech Tree: Mutually Exclusive Branch Design

## Overview

The tech tree system implements **mutually exclusive branch choices** that create meaningful decisions and encourage multiple playthroughs. Players must choose between competing specializations, permanently locking out alternate paths.

---

## Design Philosophy

### Core Principles

1. **Meaningful Choice**: Each branch offers distinct playstyles
2. **Permanent Consequences**: Choices matter and can't be undone mid-run
3. **Replayability**: Different branches encourage new playthroughs
4. **Strategic Depth**: Players must commit to a strategy early

### Balance Goals

- No branch is objectively better
- Each branch counters different enemy types
- Branches complement different playstyles (aggressive vs defensive)
- Late-game content accessible regardless of early choices

---

## Implementation Approaches

### Option A: Permanent Exclusive Choices ⭐ RECOMMENDED

**Description**: At decision points, choosing one branch permanently locks others.

**Pros**:
- Highest replayability
- Most meaningful choices
- Clear strategic commitment
- Encourages experimentation across runs

**Cons**:
- Players might feel "locked out" of content
- Requires careful balance
- Need clear communication of consequences

**Example Flow**:
```
Level 1-2: Basic turret + wall (everyone gets these)
Level 3: CHOICE POINT
  → Rapid Fire Specialization (unlock fast turrets, lock Heavy branch)
  → Heavy Damage Specialization (unlock powerful turrets, lock Rapid branch)
Level 5: Continue down chosen path
Level 8: Advanced weapons (available to both paths)
```

### Option B: Sequential Unlocking

**Description**: Complete one branch to unlock the next.

**Pros**:
- All content accessible in one run
- Guided progression
- Less confusion

**Cons**:
- Lower replayability
- Less strategic choice
- Linear progression

### Option C: Hybrid

**Description**: Combine both systems - early exclusive choices, late sequential unlocks.

**Implementation**:
- **Early Game (Levels 1-5)**: Mutually exclusive branches
- **Mid Game (Levels 6-10)**: Branch-specific upgrades
- **Late Game (Levels 10+)**: Universal upgrades after branch completion

---

## CHOSEN APPROACH: Option A - Permanent Exclusive Choices ✅

**Rationale**:
- Maximizes replayability (like Factorio)
- Each playthrough feels distinct and meaningful
- Encourages experimentation across multiple saves
- Clear strategic commitment creates engaging gameplay
- Players can restart with different builds to explore all content

**Save System Integration**:
- Support **multiple save slots** (like Factorio)
- Each save maintains its own tech tree choices
- **In-game achievements reset per save** (per-run progression)
- **Steam achievements unlock globally** (account-wide, permanent)
- Players can have parallel runs with different tech choices

---

## Technical Implementation

### TechNodeResource Fields

```gdscript
class_name TechNodeResource
extends Resource

# Standard fields
@export var id: String
@export var name: String
@export var description: String
@export var icon: Texture2D
@export var branch_name: String

# Unlock conditions
@export var unlock_level_requirement: int
@export var unlock_achievement_ids: Array[String]
@export var prerequisite_tech_ids: Array[String]

# Exclusive branch system (NEW)
@export var mutually_exclusive_with: Array[String] = []
## List of tech_ids that become permanently locked when this is unlocked

@export var requires_branch_completion: Array[String] = []
## List of branch_names that must be fully completed first

@export var unlocked_obstacle_ids: Array[String]
```

### TechTreeManager Logic

```gdscript
var unlocked_tech_ids: Array[String] = []
var locked_tech_ids: Array[String] = []  # Permanently locked

func unlock_tech(tech_id: String) -> bool:
  var tech_node = _get_tech_node_by_id(tech_id)
  
  # Unlock this tech
  unlocked_tech_ids.append(tech_id)
  
  # Lock mutually exclusive techs and their entire branches
  for exclusive_id in tech_node.mutually_exclusive_with:
    locked_tech_ids.append(exclusive_id)
    _lock_branch_recursively(exclusive_id)
    emit_signal("tech_locked", exclusive_id)
  
  return true

func _lock_branch_recursively(tech_id: String):
  # Find all techs that depend on this locked tech
  for node in all_tech_nodes:
    if tech_id in node.prerequisite_tech_ids:
      if node.id not in locked_tech_ids:
        locked_tech_ids.append(node.id)
        _lock_branch_recursively(node.id)
```

---

## Example Tech Tree Structure

### Phase 1: Basic Defense (Levels 1-2)
All players get these:
- Basic Turret (level 1)
- Basic Wall (level 1)

### Phase 2: Offensive Specialization (Level 3) - EXCLUSIVE CHOICE

**Option A: Rapid Fire Path**
- Rapid Fire Turret (level 3)
- Multi-Target Turret (level 5)
- Gatling Turret (level 7)
- **Locks**: Heavy Damage Path

**Option B: Heavy Damage Path**
- Heavy Turret (level 3)
- Sniper Turret (level 5)
- Cannon Turret (level 7)
- **Locks**: Rapid Fire Path

### Phase 3: Defensive Specialization (Level 6) - EXCLUSIVE CHOICE

**Option A: Fortress Strategy**
- Reinforced Walls (level 6)
- Barrier Towers (level 8)
- Regenerating Walls (level 10)
- **Locks**: Mobile Defense Path

**Option B: Mobile Defense**
- Support Towers (level 6)
- Slow Fields (level 8)
- Buff Amplifiers (level 10)
- **Locks**: Fortress Strategy Path

### Phase 4: Advanced Weapons (Level 12)
Requires completing one offensive AND one defensive branch:
- Laser Turret
- Missile Launcher
- Tesla Coil

---

## UI/UX Considerations

### Visual Indicators

1. **Unlocked**: ✅ Green checkmark, full color
2. **Available**: 💡 Yellow glow, clickable
3. **Locked (prerequisites)**: 🔒 Gray, shows requirements tooltip
4. **Permanently Locked**: ❌ Red X, strikethrough, "Locked due to [choice]"
5. **Exclusive Choice**: ⚠️ Yellow warning border

### Warning Dialog

When hovering over an exclusive choice:
```
┌─────────────────────────────────────────┐
│  ⚠️  IMPORTANT CHOICE                    │
├─────────────────────────────────────────┤
│  Unlocking "Rapid Fire Specialization"  │
│  will PERMANENTLY LOCK:                 │
│                                         │
│  ❌ Heavy Damage Specialization         │
│  ❌ Sniper Turret                       │
│  ❌ Cannon Turret                       │
│                                         │
│  This choice cannot be undone!          │
│                                         │
│  [Cancel]              [Confirm Unlock] │
└─────────────────────────────────────────┘
```

### Branch Completion Display

```
Offensive Branch: ████████░░ 80% (4/5 nodes)
Defensive Branch: Not Started
Advanced Branch: 🔒 Requires Offensive completion
```

---

## Balancing Considerations

### Rapid Fire vs Heavy Damage

| Attribute | Rapid Fire | Heavy Damage |
|-----------|------------|--------------|
| DPS (vs many enemies) | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| DPS (vs single target) | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Scrap efficiency | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Best vs | Swarms | Tanks/Bosses |

### Fortress vs Mobile Defense

| Attribute | Fortress | Mobile Defense |
|-----------|----------|----------------|
| Enemy delay | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Turret buffing | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Flexibility | ⭐⭐ | ⭐⭐⭐⭐ |
| Best vs | Linear attacks | Multi-path attacks |

---

## Player Communication

### First-Time Experience

1. **Tutorial mentions choices**: "You'll face strategic decisions..."
2. **First exclusive node**: Show detailed explanation
3. **Confirmation dialog**: Always require explicit confirmation
4. **Post-choice feedback**: "You chose Rapid Fire! Heavy Damage path is now locked."

### Tech Tree Screen

- **Legend/Key**: Explain all icons and states
- **Filter options**: "Show available only" vs "Show all"
- **Branch overview**: Birds-eye view of all branches
- **Reset warning**: "Starting new game resets all tech choices"

---

## Testing Checklist

- [ ] Exclusive choices lock correct techs
- [ ] Locked techs cannot be unlocked
- [ ] Recursive branch locking works (entire chains lock)
- [ ] Warning dialogs display before locking
- [ ] Save/load preserves locked state
- [ ] Branch completion detection works
- [ ] UI clearly shows locked vs available states
- [ ] Tooltips explain why techs are locked
- [ ] Multiple playthroughs show different content
- [ ] Both paths are balanced and viable

---

## Future Expansion

### Meta-Progression (Optional)

Could add persistent unlocks across runs:
- Unlock ability to respec mid-game (one-time use)
- Unlock "hybrid" nodes that work with both branches
- Unlock third branch options

### Challenge Runs

- "Pure Rapid Fire" - complete game without walls
- "Fortress Only" - no offensive turrets allowed
- These would have achievement rewards

---

## Save Game System Requirements

### Multiple Save Slots

Like Factorio, support multiple parallel saves:
- Minimum 3 save slots (expandable)
- Each slot is independent
- Display: Save name, playtime, level, last played date
- Quick save / Quick load (F5 / F9)
- Auto-save every level completion

### Achievement System Split

**In-Game Achievements** (per save slot):
- Reset when starting new game in a slot
- Track per-run progress ("Defeated 50 zombies")
- Used for tech tree unlock conditions
- Stored in save file

**Steam Achievements** (global, permanent):
- Unlock once, stay unlocked forever
- Track across all save slots
- Milestones: "Reached level 10", "Completed Rapid Fire path"
- Never reset

### Save File Structure

```
user://saves/
├── save_slot_1.save
│   ├── player_progression (level, XP, scrap)
│   ├── tech_tree_state (unlocked, locked)
│   ├── in_game_achievements (progress, unlocked)
│   ├── level_completion_status
│   └── stats (per-run stats)
├── save_slot_2.save
└── save_slot_3.save

user://global.save
├── steam_achievements (permanent)
├── global_stats (all-time totals)
└── settings (shared across saves)
```

## Implementation Priority

1. ✅ **Issue #5**: Design tech tree structure (includes exclusive branches) - OPTION A CHOSEN
2. ✅ **Issue #6**: Implement TechTreeManager with locking logic (Option A approach)
3. ✅ **Issue #8.5**: Create example exclusive branch configs
4. **Issue #4.5**: Player progression persistence (UPDATE: multiple save slots)
5. **Issue #38**: Save game system (UPDATE: multiple slots + achievement split)
6. **Issue #8**: Build UI with exclusive choice warnings
7. **Issue #7**: Connect to ObstacleRegistry
8. **NEW**: Main menu save slot selection UI

---

## Notes

- **DECISION LOCKED**: Option A (Permanent Exclusive Choices)
- Start simple: 2 exclusive choices in early tech tree
- Gather player feedback on choice difficulty
- Balance can be adjusted via .tres files (no code changes)
- Each save slot can explore different tech paths
- Steam achievements provide account-wide progression sense
- In-game achievements drive tech unlocks per run
