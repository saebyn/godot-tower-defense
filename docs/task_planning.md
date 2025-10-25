# Zom Nom Defense - Development Task Planning

**Document Version**: 1.1  
**Date**: October 19, 2025  
**Current Implementation**: ~25-30% Complete
**Target**: Full GDD Implementation

---

## Executive Summary

This document outlines the roadmap to complete Zom Nom Defense according to the Game Design Document. The work is organized into phases, with each phase containing bite-sized tasks suitable for GitHub issues.

### Realistic Completion Assessment

**Overall Completion: ~25-30%**

While we have a solid technical foundation, the majority of game systems and content are not yet implemented.

| Category | Weight | Completion | Weighted Score |
|----------|--------|------------|----------------|
| Core Systems (Health, Attack, Nav, Currency) | 25% | 80% | 20% |
| Progression (Achievements + Tech Tree) | 30% | 0% | 0% |
| Content (Levels, Enemies, Towers) | 20% | 15% | 3% |
| Game Modes (Challenge, Endless) | 10% | 0% | 0% |
| Polish (Audio, Visuals, UI Flow) | 10% | 30% | 3% |
| Advanced Features (Upgrades, Support) | 5% | 0% | 0% |
| **TOTAL** | **100%** | - | **~26%** |

### What's Actually Complete ✅
- ✅ **Core game loop** - Click-to-damage, scrap earning, obstacle placement working
- ✅ **Enemy AI** - Pathfinding, navigation, targeting fully functional
- ✅ **Wave spawning** - Enemy spawn system with wave progression
- ✅ **Component architecture** - Health, Attack components working well
- ✅ **Basic obstacles** - Walls and turrets (ShootingObstacle) functional
- ✅ **UI framework** - Hotbar, minimap, currency display, stats display exist
- ✅ **XP/Level system** - CurrencyManager tracks player level (no persistence yet)
- ✅ **Scrap economy** - Currency earning and spending works
- ✅ **Camera system** - Orthographic dimetric projection (45° tilt) with smooth movement, rotation, and zoom

### Critical Missing Systems ❌
- ❌ **Achievement system** - Completely missing (0% - required for tech unlocks)
- ❌ **Tech tree** - Completely missing (0% - core progression mechanic)
- ❌ **Player progression persistence** - No save/load (blocks tech tree)
- ❌ **Support towers** - None exist (0% - GDD core feature)
- ❌ **Tower upgrades** - Not implemented (0% - GDD core feature)
- ❌ **Multiple levels** - Only 1 level exists (need 5+ per GDD)
- ❌ **Enemy variety** - Only 2 basic zombie types (need 5+ per GDD)
- ❌ **Game over conditions** - Survivor death doesn't end game
- ❌ **Challenge modes** - Not started (0%)
- ❌ **Endless mode** - Not started (0%)

### Partial Implementations 🟡
- 🟡 **Obstacles** - Basic walls exist, but no variety or upgrades
- 🟡 **Audio** - Minimal sounds, missing survivor yelps, zombie groans, comedy soundtrack
- 🟡 **Visual style** - Generic 3D models/textures, missing modern lo-fi aesthetic (stylized low-poly with painterly textures) and comedic tone
- 🟡 **Survivors** - Exist as static targets, missing flee behavior and personality


---

## Phase 1: Foundation Systems (Critical Path)

**Goal**: Implement the core progression systems that unlock content  
**Priority**: CRITICAL  

### 1.1 Achievement System

#### Issue #1: Create Achievement Resource Type
**GitHub Issue**: [#110](https://github.com/saebyn/zom-nom-defense/issues/110) ✅ CLOSED  
**Type**: Feature  
**Priority**: High  
**Effort**: M  
**Description**:
Create a new `AchievementResource` class to define achievements.

**Acceptance Criteria**:
- [ ] Create `Config/Achievements/achievement_resource.gd`
- [ ] Define fields: id, name, description, icon, unlock_condition_type
- [ ] Support condition types: enemy_defeats, clicks, scrap_earned, obstacles_placed, wave_completed
- [ ] Add numerical threshold field for conditions
- [ ] Include hidden/visible flag
- [ ] Add reward field (could unlock tech tree items)

**Technical Notes**:
```gdscript
class_name AchievementResource
extends Resource

enum ConditionType {
  ENEMIES_DEFEATED_TOTAL,
  ENEMIES_DEFEATED_BY_TYPE,
  CLICKS_PERFORMED,
  SCRAP_EARNED,
  OBSTACLES_PLACED,
  WAVE_COMPLETED,
  GAME_LEVEL_REACHED,
  PLAYER_LEVEL_REACHED
}
```

---

#### Issue #2: Implement AchievementManager Autoload
**GitHub Issue**: [#111](https://github.com/saebyn/zom-nom-defense/issues/111) ✅ CLOSED  
**Type**: Feature  
**Priority**: High  
**Effort**: L  
**Description**:
Create a singleton system to track and unlock achievements during gameplay.

**Acceptance Criteria**:
- [ ] Create `Utilities/Systems/achievement_manager.gd`
- [ ] Add as autoload in project settings
- [ ] Track achievement progress and completion
- [ ] Persist achievement state to save file
- [ ] Emit signals when achievements unlock
- [ ] Connect to StatsManager for stat-based achievements
- [ ] Connect to CurrencyManager for level-based achievements
- [ ] Support checking multiple conditions
- [ ] Load achievements from `Config/Achievements/` folder
- [ ] Progress updated signal not sent for hidden achievements until unlocked

**Signals**:
- `achievement_unlocked(achievement: AchievementResource)`
- `achievement_progress_updated(achievement: AchievementResource, progress: float)`

---

#### Issue #3: Create Achievement Notification UI
**GitHub Issue**: [#112](https://github.com/saebyn/zom-nom-defense/issues/112) ✅ CLOSED  
**Type**: Feature  
**Priority**: Medium  
**Effort**: M  
**Description**:
Display toast notifications when achievements are unlocked.

**Acceptance Criteria**:
- [ ] Create `Common/UI/achievement_notification/` component
- [ ] Animated slide-in from top-right corner
- [ ] Display achievement icon, name, and description
- [ ] Auto-hide after 5 seconds
- [ ] Queue multiple notifications if unlocked simultaneously
- [ ] Play achievement unlock sound effect

---

#### Issue #4: Create Starter Achievements
**GitHub Issue**: [#113](https://github.com/saebyn/zom-nom-defense/issues/113) ✅ CLOSED  
**Type**: Content  
**Priority**: Medium  
**Effort**: S  
**Description**:
Create 5-10 basic achievements to test the system.

**Acceptance Criteria**:
- [ ] "First Blood" - Defeat 1 zombie by clicking
- [ ] "Click Happy" - Click 5 times
- [ ] "Constructor" - Place your first obstacle
- [ ] "Scrap Collector" - Earn 100 scrap total
- [ ] "Wave Rider" - Complete your first wave
- [ ] "Level Up" - Reach level 2
- [ ] "Tower Master" - Place 10 obstacles
- [ ] "Zombie Slayer" - Defeat 50 zombies
- [ ] Save achievements as .tres resources in `Config/Achievements/`

---

#### Issue #4.5: Implement Player Progression Persistence
**GitHub Issue**: [#1c](https://github.com/saebyn/zom-nom-defense/issues/114) ✅ CLOSED  
**Type**: Feature  
**Priority**: CRITICAL  
**Effort**: M  
**Description**:
Add save/load functionality to CurrencyManager to persist player level, XP, and scrap across game sessions. **Note**: This issue implements single-slot progression; will be refactored to multiple save slots in Issue #38.

**Acceptance Criteria**:
- [ ] Add save/load methods to CurrencyManager
- [ ] Save player level (current_level)
- [ ] Save current XP (current_xp)
- [ ] Save current scrap (current_scrap)
- [ ] Use save file path: "user://player_progression.save" (temporary, will become "user://saves/save_slot_1.save" in Issue #38)
- [ ] Only saves when a level is completed (failing or quitting mid-level does not save)
- [ ] Load progression data on game start (_ready)
- [ ] Handle missing save file gracefully (new player)
- [ ] Add save file version for future compatibility

**Technical Notes**:
```gdscript
const PROGRESSION_SAVE_PATH = "user://player_progression.save"
const SAVE_VERSION = 1

func _save_progression() -> void:
  var save_data = {
    "version": SAVE_VERSION,
    "current_level": current_level,
    "current_xp": current_xp,
    "current_scrap": current_scrap
  }
  # ... save to file

func _load_progression() -> void:
  if not FileAccess.file_exists(PROGRESSION_SAVE_PATH):
    return
  # ... load from file and restore values
```

**Dependencies**:
- Must be implemented before tech tree (Issue #6) as tech unlocks depend on player level
- Should coordinate with StatsManager which already has persistence
- Will be refactored by SaveManager (Issue #38) for multiple save slots
- IMPORTANT: This is a temporary single-slot implementation to unblock tech tree development

---

### 1.2 Tech Tree System

#### Issue #5: Design Tech Tree Structure
**GitHub Issue**: [#115](https://github.com/saebyn/zom-nom-defense/issues/115) ✅ CLOSED

**Type**: Design  
**Priority**: High  
**Effort**: M  
**Description**:
Document the tech tree layout and unlock requirements, including mutually exclusive branch choices.

**Acceptance Criteria**:
- [ ] Create `docs/tech_tree_design.md`
- [ ] Define 3-5 tech tree branches (e.g., Offensive, Defensive, Economy, Support)
- [ ] Map existing obstacles to tech tree nodes
- [ ] Define unlock requirements (level + achievement) for each node
- [ ] Sketch visual layout of tech tree with branch points
- [ ] Define dependencies between nodes (prerequisites)
- [ ] **Design mutually exclusive branch choices** (see Technical Notes)
- [ ] Document which branches lock each other out
- [ ] Define completion requirements to unlock locked branches
- [ ] Document data loading approach (see Technical Notes)

**Technical Notes - Mutually Exclusive Branches**:

**✅ CHOSEN APPROACH: Option A - Permanent Exclusive Choices**

At decision points, player chooses Branch A OR Branch B:
- Choice is **permanent for that save slot**
- Unlocking one branch locks out the other completely
- Players can explore alternate paths in different save slots
- Maximizes replayability (like Factorio)
- Each playthrough feels distinct and strategic

**Example Implementation**:
- Level 3: Choose "Rapid Fire Specialization" OR "Heavy Damage Specialization" (mutually exclusive)
- Level 6: Choose "Fortress Strategy" OR "Mobile Defense" (mutually exclusive)
- Level 12: Advanced weapons (available after completing any branch path)

**Save System Integration**:
- Multiple save slots (each can have different tech choices)
- In-game achievements reset per save slot (used for tech unlocks)
- Steam achievements unlock globally (permanent, account-wide)

**Data Loading Approach**:
Follow the existing resource pattern used by ObstacleRegistry:

1. **Create TechNodeResource** (extends Resource):
   - id, name, description, icon
   - unlock_level_requirement (int)
   - unlock_achievement_ids (Array[String])
   - prerequisite_tech_ids (Array[String])
   - unlocked_obstacle_ids (Array[String])
   - branch_name (String)
   - **mutually_exclusive_with (Array[String])** - List of tech_ids that become locked when this is unlocked
   - **requires_branch_completion (Array[String])** - List of branch_names that must be fully completed first
   
2. **Store as .tres files** in `Config/TechTree/`
   - Example: `basic_turret_node.tres`, `wall_node.tres`
   
3. **TechTreeManager auto-loads** all tech nodes from directory (like ObstacleRegistry does)

This keeps data as resources in the Godot editor, not hardcoded in scripts.

---

#### Issue #6: Implement TechTreeManager Autoload
**GitHub Issue**: [#116](https://github.com/saebyn/zom-nom-defense/issues/116) ✅ CLOSED  
**Type**: Feature  
**Priority**: High  
**Effort**: L  
**Description**:
Create system to manage tech tree state and unlocks, including mutually exclusive branch logic.

**Acceptance Criteria**:
- [ ] Create `Config/TechTree/tech_node_resource.gd` (Resource class)
- [ ] Create `Utilities/Systems/tech_tree_manager.gd` (Autoload)
- [ ] Add as autoload in project settings
- [ ] Auto-load all `.tres` files from `Config/TechTree/` directory on startup
- [ ] Track which tech nodes are unlocked (save to file)
- [ ] Track which tech nodes are permanently locked due to exclusive choices
- [ ] Check unlock conditions (level + achievements + prerequisites)
- [ ] **Implement mutually exclusive branch locking**
- [ ] **Implement branch completion requirements**
- [ ] Persist tech tree state to save file (`user://tech_tree.save`)
- [ ] Emit signals when tech unlocks or locks
- [ ] Connect to AchievementManager and CurrencyManager for condition checking
- [ ] Update ObstacleRegistry when obstacles unlock
- [ ] Provide method to check if branch is locked/available
- [ ] Display warnings before locking out branches permanently

**Signals**:
- `tech_unlocked(tech_id: String)`
- `tech_locked(tech_id: String)` - When tech becomes permanently unavailable due to exclusive choice
- `tech_available(tech_id: String)` - requirements met but not purchased yet
- `branch_locked(branch_name: String)` - When entire branch becomes locked

**Technical Notes**:
```gdscript
# TechTreeManager pattern
@export var tech_tree_directory: String = "res://Config/TechTree/"
var all_tech_nodes: Array[TechNodeResource] = []
var unlocked_tech_ids: Array[String] = []
var locked_tech_ids: Array[String] = []  # Permanently locked due to exclusive choices

func _ready() -> void:
  _load_tech_nodes_from_directory()
  _load_unlocked_state()
  _check_unlock_availability()

func unlock_tech(tech_id: String) -> bool:
  # Check if already unlocked or locked
  if tech_id in unlocked_tech_ids or tech_id in locked_tech_ids:
    return false
  
  var tech_node = _get_tech_node_by_id(tech_id)
  if not tech_node:
    return false
  
  # Unlock this tech
  unlocked_tech_ids.append(tech_id)
  
  # Lock mutually exclusive techs
  for exclusive_tech_id in tech_node.mutually_exclusive_with:
    if exclusive_tech_id not in locked_tech_ids:
      locked_tech_ids.append(exclusive_tech_id)
      emit_signal("tech_locked", exclusive_tech_id)
      _lock_branch_recursively(exclusive_tech_id)
  
  _save_state()
  emit_signal("tech_unlocked", tech_id)
  return true

func _lock_branch_recursively(tech_id: String) -> void:
  # Lock all dependent techs in the branch
  for node in all_tech_nodes:
    if tech_id in node.prerequisite_tech_ids and node.id not in locked_tech_ids:
      locked_tech_ids.append(node.id)
      emit_signal("tech_locked", node.id)
      _lock_branch_recursively(node.id)

func is_branch_completion_met(branch_name: String) -> bool:
  # Check if all techs in branch are unlocked
  var branch_techs = _get_techs_by_branch(branch_name)
  for tech in branch_techs:
    if tech.id not in unlocked_tech_ids:
      return false
  return true
```

---

#### Issue #7: Connect Obstacle Unlocks to Tech Tree
**GitHub Issue**: [#117](https://github.com/saebyn/zom-nom-defense/issues/117) ✅ CLOSED  
**Type**: Feature  
**Priority**: High  
**Effort**: M  
**Description**:
Integrate existing obstacle unlock system with tech tree.

**Acceptance Criteria**:
- [ ] Update ObstacleTypeResource to include tech_tree_id field
- [ ] Modify ObstacleRegistry to check TechTreeManager for unlocks
- [ ] Update UI hotbar to show locked obstacles (greyed out)
- [ ] Add tooltip showing unlock requirements
- [ ] Update turret.tres and wall.tres with tech requirements
- [ ] Ensure obstacles start locked and unlock via tech tree

---

#### Issue #8: Create Tech Tree UI Screen
**GitHub Issue**: [#118](https://github.com/saebyn/zom-nom-defense/issues/118) ✅ CLOSED  
**Type**: Feature  
**Priority**: Medium  
**Effort**: XL  
**Description**:
Build visual interface for viewing and unlocking tech tree with exclusive branch choices.

**Acceptance Criteria**:
- [ ] Create `Stages/UI/tech_tree/` scene
- [ ] Display tech nodes as connected graph
- [ ] Show locked/unlocked/available/permanently-locked states visually
- [ ] Display unlock requirements on hover
- [ ] Highlight available-to-unlock nodes
- [ ] **Show mutually exclusive choices with visual indicators** (e.g., red/yellow border)
- [ ] **Display warning dialog before choosing exclusive branch** ("This will lock Branch X")
- [ ] **Show permanently locked techs with X or lock icon**
- [ ] Add button to unlock tech (if requirements met)
- [ ] Show current level and achievements
- [ ] Display branch completion progress bars
- [ ] Accessible from pause menu or hotkey (T)

**Visual States**:
- **Unlocked**: Green checkmark, full color
- **Available**: Yellow glow, clickable
- **Locked (conditions not met)**: Gray, shows requirements
- **Permanently Locked (exclusive choice)**: Red X, strikethrough, tooltip explains why
- **Mutually Exclusive Choice**: Yellow warning triangle on hover

---

#### Issue #8.5: Create Example Tech Tree Configurations
**GitHub Issue**: [#119](https://github.com/saebyn/zom-nom-defense/issues/119) ✅ CLOSED

**Type**: Content  
**Priority**: High  
**Effort**: M  
**Description**:
Create initial tech tree node resources demonstrating the exclusive branch system.

**Acceptance Criteria**:
- [ ] Create `Config/TechTree/` directory
- [ ] Create example tech nodes demonstrating mutually exclusive branches
- [ ] **Example 1: Offensive Specialization Choice**
  - `rapid_fire_turret_branch.tres` (fast, low damage)
  - `heavy_damage_turret_branch.tres` (slow, high damage)
  - These are mutually exclusive
- [ ] **Example 2: Defensive Strategy Choice**
  - `fortress_strategy.tres` (walls and barriers)
  - `mobile_defense.tres` (support towers, no walls)
  - These are mutually exclusive
- [ ] **Example 3: Sequential Unlocking**
  - `advanced_weapons.tres` requires completion of chosen offensive branch
- [ ] Test that exclusive locking works in-game
- [ ] Document the example tree in `docs/tech_tree_design.md`

**Example Configuration**:
```gdscript
# rapid_fire_turret_branch.tres
[resource]
id = "rapid_fire_branch"
name = "Rapid Fire Specialization"
description = "Unlock fast-firing turrets. Locks Heavy Damage path."
unlock_level_requirement = 3
mutually_exclusive_with = ["heavy_damage_branch"]
unlocked_obstacle_ids = ["rapid_fire_turret"]
branch_name = "Offensive"

# heavy_damage_turret_branch.tres
[resource]
id = "heavy_damage_branch"
name = "Heavy Damage Specialization"
description = "Unlock high-damage turrets. Locks Rapid Fire path."
unlock_level_requirement = 3
mutually_exclusive_with = ["rapid_fire_branch"]
unlocked_obstacle_ids = ["heavy_turret"]
branch_name = "Offensive"

# advanced_weapons.tres
[resource]
id = "advanced_weapons"
name = "Advanced Weapons"
description = "Requires completing either offensive specialization."
unlock_level_requirement = 8
prerequisite_tech_ids = ["rapid_fire_branch", "heavy_damage_branch"] # OR relationship
requires_branch_completion = ["Offensive"]
unlocked_obstacle_ids = ["laser_turret", "missile_launcher"]
branch_name = "Advanced"
```

---

### 1.3 Multiple Levels Implementation

#### Issue #9: Create Level Selection System
**GitHub Issue**: [#120](https://github.com/saebyn/zom-nom-defense/issues/120) ✅ CLOSED

**Type**: Feature  
**Priority**: Medium  
**Effort**: M  
**Description**:
Implement level selection screen and progression tracking.

**Acceptance Criteria**:
- [ ] Create `Stages/UI/level_select/` scene
- [ ] Display available levels (unlocked via progression)
- [ ] Show level preview image and description
- [ ] Track which levels are completed
- [ ] Display best performance stats per level
- [ ] Unlock next level when previous completed
- [ ] Add "Return to Level Select" option in pause menu

---

#### Issue #10: Level 2 - Campfire Survivors
**GitHub Issue**: [#121](https://github.com/saebyn/zom-nom-defense/issues/121) 🔓 OPEN

**Type**: Content  
**Priority**: Medium  
**Effort**: L  
**Description**:
Create Level 2 as described in GDD (two survivors next to campfire).

**Acceptance Criteria**:
- [ ] Create `Stages/Levels/level_2.tscn` based on level.tscn template
- [ ] Design terrain with campfire area
- [ ] Place 2 survivor targets
- [ ] Configure 3-5 waves with increasing difficulty
- [ ] Add environmental decorations (campfire, rocks, trees)
- [ ] Set multiple spawn areas for enemy variety
- [ ] Test and balance difficulty curve
- [ ] Add level description and preview image

---

#### Issue #11: Level 3 - Hammock Defense
**GitHub Issue**: [#122](https://github.com/saebyn/zom-nom-defense/issues/122) 🔓 OPEN

**Type**: Content  
**Priority**: Low  
**Effort**: L  
**Description**:
Create Level 3 with absurd hammock scenario from GDD.

**Acceptance Criteria**:
- [ ] Create `Stages/Levels/level_3.tscn`
- [ ] Design terrain with two poles/trees
- [ ] Create hammock 3D model or use placeholder
- [ ] Place 1 survivor target in hammock
- [ ] Configure 5+ waves with higher difficulty
- [ ] Add comedic environmental elements
- [ ] Test and balance difficulty
- [ ] Add level description emphasizing absurdity

---

#### Issue #12: Level 4 - Inflatable Pool Party
**GitHub Issue**: [#123](https://github.com/saebyn/zom-nom-defense/issues/123) 🔓 OPEN

**Type**: Content  
**Priority**: Low  
**Effort**: L  
**Description**:
Create Level 4 with inflatable pool scenario.

**Acceptance Criteria**:
- [ ] Create `Stages/Levels/level_4.tscn`
- [ ] Design terrain with pool area
- [ ] Create inflatable pool 3D model or use placeholder
- [ ] Place 2-3 survivor targets around pool
- [ ] Configure 6+ waves with high difficulty
- [ ] Add pool toys and summer-themed decorations
- [ ] Test and balance difficulty
- [ ] Add level description

---

## Phase 2: Content Expansion (High Priority)

**Goal**: Add variety and depth to gameplay  
**Priority**: HIGH  

### 2.1 Tower Upgrade System


#### Issue #15: Basic tower upgrade system (2-3 tiers)
**GitHub Issue**: [#147](https://github.com/saebyn/zom-nom-defense/issues/147) 🔓 OPEN

**Type**: Feature  
**Priority**: High  
**Effort**: L  
**Description**:
Build interface for upgrading placed towers.

**Acceptance Criteria**:
- [ ] Create `Common/UI/upgrade_menu/` component
- [ ] Show when player clicks on upgradeable obstacle
- [ ] Display current tier and stats
- [ ] Show next tier stats and cost
- [ ] Add "Upgrade" button (enabled if affordable)
- [ ] Add "Sell" button (refund based on tier)
- [ ] Display upgrade history
- [ ] Close on click away or ESC

### 2.2 Support Tower System

**GitHub Issue**: [#146](https://github.com/saebyn/zom-nom-defense/issues/146) 🔓 OPEN

#### Issue #17: Design Support Tower Types
**Type**: Design  
**Priority**: Medium  
**Effort**: M  
**Description**:
Define support tower abilities and mechanics.

**Acceptance Criteria**:
- [ ] Create `docs/support_tower_design.md`
- [ ] Define 3-5 support tower types:
  - Range Booster: +20% range to nearby turrets
  - Fire Rate Booster: +30% fire rate to nearby turrets
  - Damage Amplifier: +25% damage to nearby turrets
  - Slow Field: Slows enemies in area
  - Scrap Generator: Passive scrap income
- [ ] Define support radius for each
- [ ] Define costs and unlock requirements
- [ ] Specify visual indicators (aura, particles)
- [ ] Document stacking rules (do buffs stack?)

---

#### Issue #18: Implement BuffSystem Component
**Type**: Feature  
**Priority**: Medium  
**Effort**: L  
**Description**:
Create system for applying buffs to obstacles in range.

**Acceptance Criteria**:
- [ ] Create `Common/Components/buff/` component
- [ ] Define buff types (range, fire_rate, damage, speed)
- [ ] Track active buffs on buffable objects
- [ ] Detect obstacles/enemies in support radius
- [ ] Apply/remove buffs when in/out of range
- [ ] Handle multiple overlapping buffs
- [ ] Visual indicator on buffed objects
- [ ] Emit buff_applied/buff_removed signals

---

#### Issue #19: Create Support Tower Base Class
**Type**: Feature  
**Priority**: Medium  
**Effort**: L  
**Description**:
Implement base support tower that applies buffs.

**Acceptance Criteria**:
- [ ] Create `Entities/Obstacles/Templates/support_obstacle/`
- [ ] Extend PlaceableObstacle
- [ ] Add support radius and buff type parameters
- [ ] Detect nearby obstacles in radius
- [ ] Apply buffs via BuffSystem component
- [ ] Update when obstacles move in/out of range
- [ ] Visual radius indicator (toggle on/off)
- [ ] Particle effects for active support

---

#### Issue #20: Create Range Booster Tower
**Type**: Content  
**Priority**: Medium  
**Effort**: M  
**Description**:
First concrete support tower implementation.

**Acceptance Criteria**:
- [ ] Create scene in `Entities/Obstacles/Concrete/range_booster/`
- [ ] Configure: 15 unit radius, +20% range buff
- [ ] Cost: 150 scrap
- [ ] 3D model or placeholder with blue aura
- [ ] Create obstacle_type_resource config
- [ ] Add to tech tree (tier 2 support branch)
- [ ] Test with multiple turrets in range
- [ ] Add tooltip showing buff effect

---

#### Issue #21: Create Fire Rate Booster Tower
**Type**: Content  
**Priority**: Low  
**Effort**: M  
**Description**:
Second support tower for variety.

**Acceptance Criteria**:
- [ ] Create scene in `Entities/Obstacles/Concrete/fire_rate_booster/`
- [ ] Configure: 12 unit radius, +30% fire rate buff
- [ ] Cost: 200 scrap
- [ ] 3D model or placeholder with red aura
- [ ] Create obstacle_type_resource config
- [ ] Add to tech tree (tier 3 support branch)
- [ ] Test with multiple turrets
- [ ] Add tooltip showing buff effect

---

### 2.3 Additional Enemy Types

#### Issue #22: Design Enemy Variety
**GitHub Issue**: [#145](https://github.com/saebyn/zom-nom-defense/issues/145) 🔓 OPEN

**Type**: Design  
**Priority**: Medium  
**Effort**: M  
**Description**:
Plan 5-10 additional enemy types with unique behaviors.

**Acceptance Criteria**:
- [ ] Create `docs/enemy_design.md`
- [ ] Fast Scout: Low HP, high speed, low reward
- [ ] Tank: High HP, slow, high reward
- [ ] Sprinter: Normal HP, speed increases near target
- [ ] Armored: Takes reduced damage, medium speed
- [ ] Swarm: Low HP, spawns in groups
- [ ] Boss: Very high HP, special abilities
- [ ] Define stats, rewards, and spawn frequencies
- [ ] Plan visual designs or placeholders

---

#### Issue #23: Implement Fast Scout Enemy
**Type**: Content  
**Priority**: Medium  
**Effort**: M  
**Description**:
Create fast, weak enemy type.

**Acceptance Criteria**:
- [ ] Create EnemyTypeResource for Scout
- [ ] Stats: 30 HP, 4.0 speed, 5 scrap reward, 5 XP
- [ ] Use existing humanoid model with different texture
- [ ] Add to later waves in existing levels
- [ ] Test pathfinding at high speed
- [ ] Balance difficulty curve

---

#### Issue #24: Implement Tank Enemy
**Type**: Content  
**Priority**: Medium  
**Effort**: M  
**Description**:
Create slow, tanky enemy type.

**Acceptance Criteria**:
- [ ] Create EnemyTypeResource for Tank
- [ ] Stats: 300 HP, 1.0 speed, 50 scrap reward, 25 XP
- [ ] Use existing model with larger scale (2.0x)
- [ ] Add to mid-to-late waves
- [ ] Test against turrets (should require focus fire)
- [ ] Balance difficulty

---

### 2.4 Audio & Polish

#### Issue #25: Add Combat Sound Effects
**GitHub Issue**: [#149](https://github.com/saebyn/zom-nom-defense/issues/149) 🔓 OPEN

**Type**: Polish  
**Priority**: Low  
**Effort**: M  
**Description**:
Enhance audio feedback for combat actions.

**Acceptance Criteria**:
- [ ] Add turret firing sounds (laser, gun, etc.)
- [ ] Add zombie death sounds (multiple variations)
- [ ] Add click attack sound
- [ ] Add obstacle placement sound
- [ ] Add obstacle removal sound
- [ ] Configure AudioManager for sound variations
- [ ] Balance audio levels

---

#### Issue #26: Add UI Sound Effects
**Type**: Polish  
**Priority**: Low  
**Effort**: M  
**Description**:
Add audio feedback for UI interactions.

**Acceptance Criteria**:
- [ ] Button click sound
- [ ] Hover sound (subtle)
- [ ] Achievement unlock sound (celebratory)
- [ ] Tech unlock sound
- [ ] Level complete sound
- [ ] Game over sound
- [ ] Purchase sound (placing obstacle)
- [ ] Insufficient funds sound (error)

---

#### Issue #27: Add Background Music
**Type**: Content  
**Priority**: Low  
**Effort**: M  
**Description**:
Implement adaptive music system.

**Acceptance Criteria**:
- [ ] Find/create 2-3 music tracks (menu, gameplay, boss)
- [ ] Implement music manager or use AudioManager
- [ ] Fade between tracks on state changes
- [ ] Add music volume control in settings
- [ ] Loop tracks seamlessly
- [ ] Intensity increases with wave number (optional)

---

## Phase 3: Game Modes and Polish

**Goal**: Add replay value with alternate modes and challenges, improve overall polish and user experience.
**Priority**: MEDIUM  

### 3.0 Overall Polish


#### Issue #40: Implement Tutorial/Onboarding
**GitHub Issue**: [#74](https://github.com/saebyn/zom-nom-defense/issues/74) 🔓 OPEN
**Type**: Feature  
**Priority**: Medium  
**Effort**: L  
**Description**:
Create first-time player experience.

**Acceptance Criteria**:
- [ ] Create tutorial level (Tutorial.tscn)
- [ ] Step-by-step instructions with highlights
- [ ] Teach clicking to attack
- [ ] Teach obstacle placement
- [ ] Teach reading UI (scrap, XP, wave info)
- [ ] Introduce tech tree and achievements
- [ ] Skip tutorial option for returning players
- [ ] Mark tutorial as completed in save file

---

#### Issue #51: Implement Lo-Fi Visual Style Pass
**GitHub Issue**: [#148](https://github.com/saebyn/zom-nom-defense/issues/148)
**Type**: Polish  
**Priority**: High (near launch)  
**Effort**: XL  
**Description**:
Apply modern lo-fi aesthetic to game visuals - stylized low-poly models with simple, painterly textures.

**Visual Style Guidelines**:
- **Modern Lo-Fi** aesthetic (NOT retro/blocky)
- Smooth, organic low-poly forms (~500-2000 polys per character)
- Hand-painted or simple gradient textures
- Stylized proportions supporting comedic tone
- Clear, readable silhouettes
- Think: Firewatch, A Short Hike, Dorfromantik style

**Acceptance Criteria**:
- [ ] Review visual style guide document (`docs/visual_style_guide.md`)
- [ ] Define color palette (10-20 core colors)
- [ ] Create example assets demonstrating target style
- [ ] Update zombie models: smooth low-poly (~800 polys), painted textures, comedic proportions
- [ ] Update survivor models: similar style, easily distinguishable
- [ ] Update environment props (campfire, trees, pool, hammock) with consistent style
- [ ] Apply simple shader (toon/cel-shaded or custom painterly shader)
- [ ] Update terrain textures to painted/stylized look
- [ ] Ensure all assets follow consistent visual language
- [ ] Test readability in gameplay - ensure clarity at camera distance

**Reference Style**:
- Organic shapes, not blocky/cubic
- "Saturday morning cartoon" quality, not photorealistic
- Intentionally simple, not technically limited
- Charming and inviting, not jarring or retro

**Technical Specs**:
- Character models: 500-2000 polygons
- Texture resolution: 512x512 to 1024x1024 max
- Simple lighting (ambient + directional)
- Minimal use of normal maps
- Soft shadows preferred

---


### 3.1 Challenge Levels

#### Issue #28: Design Challenge Level System
**GitHub Issue**: [#150](https://github.com/saebyn/zom-nom-defense/issues/150) 🔓 OPEN

**Type**: Design  
**Priority**: Medium  
**Effort**: M  
**Description**:
Define challenge level mechanics and victory conditions.

**Acceptance Criteria**:
- [ ] Create `docs/challenge_level_design.md`
- [ ] Define 5-10 challenge concepts:
  - "Click Only" - No obstacles allowed
  - "No Turrets" - Only walls and support towers
  - "Budget Run" - Limited total scrap to spend
  - "Speed Run" - Complete in X time
  - "Pacifist" - Don't click enemies, turrets only
  - "Horde Mode" - Survive 10 waves of increasing intensity
- [ ] Define unique rewards for completing challenges
- [ ] Plan UI for challenge selection

---

#### Issue #29: Implement Challenge Level Framework
**GitHub Issue**: [#151](https://github.com/saebyn/zom-nom-defense/issues/151) 🔓 OPEN

**Type**: Feature  
**Priority**: Medium  
**Effort**: L  
**Description**:
Create system for challenge levels with custom rules.

**Acceptance Criteria**:
- [ ] Extend Level class to support ChallengeLevel
- [ ] Add challenge_rules field (restrict_obstacles, time_limit, etc.)
- [ ] Enforce rules during gameplay
- [ ] Track challenge-specific completion stats
- [ ] Award special achievements for challenges
- [ ] Add challenge results screen with performance metrics

---

#### Issue #30: Create "Click Only" Challenge
**GitHub Issue**: [#152](https://github.com/saebyn/zom-nom-defense/issues/152) 🔓 OPEN

**Type**: Content  
**Priority**: Low  
**Effort**: M  
**Description**:
First challenge level - no obstacles allowed.

**Acceptance Criteria**:
- [ ] Create challenge_click_only.tscn
- [ ] Disable obstacle placement UI
- [ ] 3-5 waves of moderate difficulty
- [ ] Must defend survivor(s) with clicks only
- [ ] Award "Trigger Happy" achievement on completion
- [ ] Add to challenge level list

---

#### Issue #31: Create "No Turrets" Challenge
**GitHub Issue**: [#153](https://github.com/saebyn/zom-nom-defense/issues/153) 🔓 OPEN

**Type**: Content  
**Priority**: Low  
**Effort**: M  
**Description**:
Challenge emphasizing defensive play.

**Acceptance Criteria**:
- [ ] Create challenge_no_turrets.tscn
- [ ] Allow only walls and support towers
- [ ] 5-7 waves, design around maze building
- [ ] Award "Architect" achievement on completion
- [ ] Test that walls can funnel enemies effectively

---

### 3.2 Endless Mode

#### Issue #32: Implement Endless Mode Framework
**GitHub Issue**: [#154](https://github.com/saebyn/zom-nom-defense/issues/154) 🔓 OPEN

**Type**: Feature  
**Priority**: Medium  
**Effort**: L  
**Description**:
Create infinitely scaling wave system.

**Acceptance Criteria**:
- [ ] Create `Stages/Levels/endless_mode.tscn`
- [ ] Generate waves procedurally
- [ ] Increase difficulty with each wave (HP, count, speed)
- [ ] Track high score (waves survived)
- [ ] Add leaderboard (local or online)
- [ ] No victory condition, only game over
- [ ] Award special achievements for milestone waves (10, 25, 50, 100)

---

#### Issue #33: Balance Endless Mode Difficulty Curve
**GitHub Issue**: [#155](https://github.com/saebyn/zom-nom-defense/issues/155) 🔓 OPEN

**Type**: Balance  
**Priority**: Low  
**Effort**: M  
**Description**:
Tune endless mode to be fair but increasingly challenging.

**Acceptance Criteria**:
- [ ] Test waves 1-50
- [ ] Ensure gradual difficulty increase
- [ ] Introduce new enemy types at intervals
- [ ] Increase enemy count and HP per wave
- [ ] Add boss waves every 10 waves
- [ ] Playtest and adjust scaling factors
- [ ] Document difficulty formula

---

## Phase 4: Advanced Features (Low Priority)

**Goal**: Optional features from GDD  
**Priority**: LOW  

### 4.1 Twitch Integration (Optional)

#### Issue #34: Research Twitch Integration Options
**Type**: Research  
**Priority**: Low  
**Effort**: M  
**Description**:
Investigate Twitch API and integration methods for Godot.

**Acceptance Criteria**:
- [ ] Research Twitch API documentation
- [ ] Find Godot Twitch integration libraries/plugins
- [ ] Document authentication flow
- [ ] Plan implementation strategy
- [ ] Estimate development time for full integration
- [ ] Create technical design document

---

#### Issue #35: Implement Basic Twitch Connection
**Type**: Feature  
**Priority**: Low  
**Effort**: L  
**Description**:
Connect to Twitch chat and authenticate.

**Acceptance Criteria**:
- [ ] Create TwitchManager autoload
- [ ] Implement OAuth authentication
- [ ] Connect to IRC chat
- [ ] Read chat messages
- [ ] Display Twitch connection status in UI
- [ ] Handle connection errors gracefully
- [ ] Add Twitch settings panel (enable/disable)

---

#### Issue #36: Implement Viewer Voting System
**Type**: Feature  
**Priority**: Low  
**Effort**: XL  
**Description**:
Allow viewers to vote on special zombie spawns.

**Acceptance Criteria**:
- [ ] Parse voting commands from chat (!vote1, !vote2, etc.)
- [ ] Display voting options to viewers between waves
- [ ] Count votes in real-time
- [ ] Show vote results to streamer and viewers
- [ ] Spawn winning enemy type(s) in next wave
- [ ] Add cooldown between votes
- [ ] Display vote results in-game UI

---

#### Issue #37: Implement Viewer Sabotage/Aid System
**Type**: Feature  
**Priority**: Low  
**Effort**: L  
**Description**:
Allow viewers to spend points to affect gameplay.

**Acceptance Criteria**:
- [ ] Track viewer channel points or custom currency
- [ ] Define sabotage actions (spawn elite zombie, reduce scrap, etc.)
- [ ] Define aid actions (give bonus scrap, heal survivors, etc.)
- [ ] Parse channel point redemptions
- [ ] Apply effects in-game with visual feedback
- [ ] Announce viewer's action in chat and game
- [ ] Balance cost vs impact

---

### 4.2 Quality of Life & Polish

#### Issue #38: Implement Multiple Save Slot System
**GitHub Issue**: [#144](https://github.com/saebyn/zom-nom-defense/issues/144) 🔓 OPEN

**Type**: Feature  
**Priority**: Medium (but foundational for Option A tech tree)  
**Effort**: XL
**Description**:
Create unified save system with multiple save slots (minimum 3, like Factorio). Each save slot maintains independent progression with its own tech tree choices and in-game achievements. Steam achievements unlock globally when first earned.

**Acceptance Criteria**:
- [ ] Create SaveManager autoload with slot management
- [ ] Support minimum 3 save slots (configurable to more)
- [ ] Save slot file structure: `user://saves/save_slot_N.save` (N = 1, 2, 3, ...)
- [ ] Global persistent data: `user://global.save` (Steam achievements, settings)
- [ ] Save slot metadata: timestamp, playtime, last level, player level
- [ ] Save slot selection UI in main menu (show metadata for each slot)
- [ ] "New Game" creates new save in selected slot (resets in-game achievements)
- [ ] "Continue" loads most recent save slot
- [ ] "Load Game" shows all save slots with metadata

**Per-Slot Data (Resets on New Game)**:
- [ ] Player progression (level, XP, scrap) - refactor from Issue #4.5
- [ ] Tech tree state (unlocked nodes, locked exclusive branches)
- [ ] In-game achievements (used for tech unlocks)
- [ ] Level completion status
- [ ] Player stats (StatsManager - already has persistence)

**Global Data (Persists Across All Slots)**:
- [ ] Steam achievements (unlock once, accumulate forever)
- [ ] Settings (audio, graphics, controls)
- [ ] Total playtime across all saves
- [ ] Global statistics (optional: total kills, total playtime, etc.)

**Technical Notes**:
```gdscript
# SaveManager.gd
const MAX_SAVE_SLOTS = 3
const SAVE_SLOT_PATH_TEMPLATE = "user://saves/save_slot_%d.save"
const GLOBAL_SAVE_PATH = "user://global.save"

var current_save_slot: int = -1  # -1 = no slot loaded

func load_save_slot(slot_number: int) -> bool:
  # Load per-slot data from save_slot_N.save
  # Trigger each manager to load its data
  pass

func save_current_slot() -> void:
  # Save per-slot data to current save slot
  pass

func get_save_slot_metadata(slot_number: int) -> Dictionary:
  # Return: timestamp, playtime, player_level, last_level, etc.
  pass

func create_new_game(slot_number: int) -> void:
  # Reset per-slot data, keep global data
  pass
```

**Achievement Split Pattern**:
- In-game achievements → Tracked in AchievementManager → Saved per slot → Used for tech tree unlocks
- Steam achievements → Tracked globally → Saved in `global.save` → Unlocked once, persist forever
- When in-game achievement earned → Check if corresponding Steam achievement unlocked → If not, unlock Steam achievement and save to global

**Dependencies**:
- Builds on Issue #4.5 (single-slot CurrencyManager persistence)
- Required for Issue #5, #6, #8, #8.5 (tech tree exclusive branches need save slot support)
- AchievementManager (Issue #1) must implement dual-tracking (in-game vs Steam)
- Should be implemented early in Phase 1 to avoid refactoring later

---

#### Issue #39: Add Difficulty Settings
**Type**: Feature  
**Priority**: Low  
**Effort**: M  
**Description**:
Let players choose difficulty level.

**Acceptance Criteria**:
- [ ] Add difficulty selector (Easy, Normal, Hard, Brutal)
- [ ] Easy: +50% scrap, -25% enemy HP
- [ ] Normal: Default values
- [ ] Hard: -25% scrap, +50% enemy HP, +20% enemy speed
- [ ] Brutal: -50% scrap, +100% enemy HP, +40% enemy speed
- [ ] Disable achievements on Easy mode
- [ ] Add difficulty indicator to level select

---

#### Issue #41: Add Settings Menu Enhancements
**Type**: Polish  
**Priority**: Low  
**Effort**: M  
**Description**:
Expand settings with more options.

**Acceptance Criteria**:
- [ ] Add accessibility options (color blind mode, text size)
- [ ] Add gameplay options (auto-pause on wave complete)
- [ ] Add "Reset Progress" option with confirmation
- [ ] Add credits screen
- [ ] Test all settings persist correctly

---

#### Issue #42: Improve Camera Controls
**Type**: Polish  
**Priority**: Low  
**Effort**: M  
**Description**:
Enhance camera feel and responsiveness.

**Acceptance Criteria**:
- [ ] Add camera edge scrolling (move when mouse at screen edge)
- [ ] Add configurable camera speed in settings
- [ ] Add camera bounds to prevent going off-map
- [ ] Add "Reset Camera" hotkey (Home key?)
- [ ] Improve camera rotation snapping

---

## Phase 5: Content Creation (Ongoing)

**Goal**: Continuously add content to keep game fresh  
**Priority**: ONGOING

### 5.1 Additional Content

#### Issue #43: Create Enemy Variety Pack 1
**Type**: Content  
**Priority**: Low  
**Description**: Add 3-5 more enemy types (Armored, Swarm, Boss variants)

#### Issue #44: Create Obstacle Variety Pack 1
**Type**: Content  
**Priority**: Low  
**Description**: Add 3-5 more obstacle types (Flamethrower turret, Ice tower, etc.)

#### Issue #45: Create Support Tower Variety Pack
**Type**: Content  
**Priority**: Low  
**Description**: Add remaining support tower types from design doc

#### Issue #46: Create Level Pack 2
**Type**: Content  
**Priority**: Low  
**Description**: Levels 5-8 with increasingly absurd scenarios

#### Issue #47: Create Challenge Pack 2
**Type**: Content  
**Priority**: Low  
**Description**: 5 more challenge levels with unique mechanics

#### Issue #48: Create Achievement Pack 2
**Type**: Content  
**Priority**: Low  
**Description**: 20-30 more achievements for long-term goals

---

## Phase 6: Launch Preparation (Final Phase)

**Goal**: Prepare for public release  
**Priority**: CRITICAL (when ready for launch)

### 6.1 Pre-Launch Tasks

#### Issue #49: Performance Optimization Pass
**Type**: Optimization  
**Priority**: High (near launch)  
**Effort**: XL  
**Description**:
Optimize game performance for smooth 60 FPS.

**Acceptance Criteria**:
- [ ] Profile game with many enemies/obstacles
- [ ] Optimize pathfinding updates
- [ ] Reduce draw calls where possible
- [ ] Implement object pooling for enemies/projectiles
- [ ] Test on minimum spec hardware
- [ ] Achieve 60 FPS with 50+ enemies on screen

---

#### Issue #50: Bug Fixing and QA Pass
**Type**: Testing  
**Priority**: High (near launch)  
**Effort**: XXL  
**Description**:
Comprehensive testing and bug fixing.

**Acceptance Criteria**:
- [ ] Test all levels for completion
- [ ] Test all achievements unlock correctly
- [ ] Test tech tree progression
- [ ] Test save/load functionality
- [ ] Test edge cases (100+ obstacles, 0 scrap, etc.)
- [ ] Fix all critical and high-priority bugs
- [ ] Playtest with fresh eyes (friends/testers)

---

#### Issue #51.5: Balance Pass
**Type**: Balance  
**Priority**: High (near launch)  
**Effort**: XL  
**Description**:
Final game balance adjustments.

**Acceptance Criteria**:
- [ ] Playtest all levels on all difficulties
- [ ] Adjust scrap rewards/costs
- [ ] Adjust enemy HP/damage/speed
- [ ] Adjust tower damage/range/fire rate
- [ ] Adjust level progression difficulty curve
- [ ] Ensure each obstacle type is useful
- [ ] Get external playtest feedback

---

#### Issue #52: Polish Pass - Visual Effects
**Type**: Polish  
**Priority**: Medium (near launch)  
**Effort**: L  
**Description**:
Add visual polish and juice to the game.

**Acceptance Criteria**:
- [ ] Add particle effects (enemy death, turret shots, etc.)
- [ ] Add screen shake on big events
- [ ] Add damage numbers floating from enemies
- [ ] Add impact flashes
- [ ] Improve UI animations
- [ ] Add smooth transitions between screens
- [ ] Ensure consistent art style

---

#### Issue #53: Create Marketing Assets
**Type**: Marketing  
**Priority**: Medium (near launch)  
**Effort**: XL  
**Description**:
Prepare promotional materials.

**Acceptance Criteria**:
- [ ] Create Steam header capsule (616x353)
- [ ] Create Steam library capsule (600x900)
- [ ] Record gameplay trailer (1-2 minutes)
- [ ] Take 5-10 appealing screenshots
- [ ] Write store description
- [ ] Create social media posts
- [ ] Design logo (if not already done)

---

#### Issue #54: Implement Steam Integration
**Type**: Feature  
**Priority**: High (if targeting Steam)  
**Effort**: L  
**Description**:
Integrate Steamworks SDK.

**Acceptance Criteria**:
- [ ] Set up Steamworks SDK in Godot
- [ ] Implement Steam achievements
- [ ] Implement Steam leaderboards (endless mode)
- [ ] Implement Steam cloud saves
- [ ] Add Steam overlay support
- [ ] Test Steam features in sandbox environment
- [ ] Prepare Steam store page

---

## Development Roadmap Summary

### Phase Overview

Based on the 25-30% completion assessment:

| Phase | Issues | Completion | Status |
|-------|--------|------------|--------|
| **Phase 1: Foundation** | 11 | 0% | Critical path - must complete first |
| **Phase 2: Content** | 15 | 5% | Blocked by Phase 1 |
| **Phase 3: Game Modes** | 7 | 0% | Requires content from Phase 2 |
| **Phase 4: Advanced** | 9 | 0% | Polish and expansion |
| **Phase 5: Content Creation** | 8 | 10% | Ongoing content development |
| **Phase 6: Launch Prep** | 6 | 0% | Final polish and release |
| **TOTAL** | **56** | **~3%** | See critical path below |

### T-Shirt Size Reference

- **S**: Quick task, straightforward implementation
- **M**: Moderate complexity, some planning needed
- **L**: Complex feature, requires design and testing
- **XL**: Major system or significant content creation
- **XXL**: Large-scale feature affecting multiple systems

### Critical Path (Must Complete First)

1. **Issue #4.5** - Player Progression Persistence (M) - BLOCKS tech tree
2. **Issue #1-4** - Achievement System (M-L range) - BLOCKS tech unlocks
3. **Issue #5-8.5** - Tech Tree System (L-XL range) - BLOCKS content unlocks
4. **Issue #38** - Multiple Save Slots (XL) - REQUIRED for Option A tech tree

These foundational systems must be completed before content expansion can proceed effectively.


---

## Appendix: Issue Templates

### Feature Issue Template
```markdown
**Type**: Feature
**Priority**: [High/Medium/Low]
**Effort**: [S/M/L/XL/XXL]
**Phase**: [Phase number]

## Description
[Clear description of the feature]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

## Technical Notes
[Any implementation details, gotchas, or dependencies]

## Testing Notes
[How to verify this works]

## Dependencies
- Depends on issue #X
- Blocks issue #Y
```

### Content Issue Template
```markdown
**Type**: Content
**Priority**: [High/Medium/Low]
**Effort**: [S/M/L/XL/XXL]
**Phase**: [Phase number]

## Description
[What content is being created]

## Specifications
- Property 1: [value]
- Property 2: [value]

## Assets Needed
- [ ] 3D model / 2D sprite
- [ ] Texture / Material
- [ ] Sound effects
- [ ] Configuration file

## Acceptance Criteria
- [ ] Content created and integrated
- [ ] Tested in-game
- [ ] Balanced appropriately
```

---

## Priority Legend

- **CRITICAL**: Must have for MVP, blocks other work
- **HIGH**: Important for core gameplay experience
- **MEDIUM**: Enhances experience, should have
- **LOW**: Nice to have, polish, or optional features

---

## Effort Size Guide

- **S**: Quick task, straightforward implementation
- **M**: Moderate complexity, some planning needed
- **L**: Complex feature, requires design and testing
- **XL**: Major system or significant content creation
- **XXL**: Large-scale feature affecting multiple systems


---

## Next Steps

1. **Review this document** with team/stakeholders
2. **Prioritize phases** based on goals and resources
3. **Create GitHub issues** for Phase 1 tasks
4. **Assign issues** to developers
5. **Set milestones** for each phase completion
6. **Begin development** with Issue #1

---

## Notes

- All effort estimates are approximate and may vary based on developer experience
- This is a part-time project worked on inconsistently - no timeline expectations
- Some tasks can be parallelized, others have dependencies
- Content creation (levels, enemies, obstacles) can happen in parallel with system development
- Regular playtesting should occur throughout development
- This plan is living document and should be updated as work progresses

**Total Estimated Tasks**: 56 issues
**Estimated Total Time**: As long as it takes!
