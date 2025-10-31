# Zom Nom Defense - Development Task Planning

**Document Version**: 1.2  
**Date**: October 31, 2025  
**Current Implementation**: ~60% Complete
**Target**: Full GDD Implementation

---

## Executive Summary

This document outlines the roadmap to complete Zom Nom Defense according to the Game Design Document. The work is organized into phases, with each phase containing bite-sized tasks suitable for GitHub issues.

### Realistic Completion Assessment

**Overall Completion: ~60%**

Significant progress has been made on core progression systems. Phase 1 (Foundation Systems) is now complete!

| Category | Weight | Completion | Weighted Score |
|----------|--------|------------|----------------|
| Core Systems (Health, Attack, Nav, Currency) | 25% | 90% | 22.5% |
| Progression (Achievements + Tech Tree + Saves) | 30% | 100% | 30% |
| Content (Levels, Enemies, Towers) | 20% | 15% | 3% |
| Game Modes (Challenge, Endless) | 10% | 0% | 0% |
| Polish (Audio, Visuals, UI Flow) | 10% | 40% | 4% |
| Advanced Features (Upgrades, Support) | 5% | 0% | 0% |
| **TOTAL** | **100%** | - | **~59.5%** |

### What's Actually Complete ✅
- ✅ **Core game loop** - Click-to-damage, scrap earning, obstacle placement working
- ✅ **Enemy AI** - Pathfinding, navigation, targeting fully functional
- ✅ **Wave spawning** - Enemy spawn system with wave progression
- ✅ **Component architecture** - Health, Attack components working well
- ✅ **Basic obstacles** - Walls and turrets (ShootingObstacle) functional
- ✅ **UI framework** - Hotbar, minimap, currency display, stats display, FPS overlay
- ✅ **XP/Level system** - CurrencyManager tracks player level with persistence
- ✅ **Scrap economy** - Currency earning and spending works
- ✅ **Camera system** - Orthographic dimetric projection (45° tilt) with smooth movement, rotation, and zoom
- ✅ **Achievement system** - Complete with toast notifications, achievement list UI, and progress tracking
- ✅ **Tech tree system** - Full implementation with mutually exclusive branches, prerequisites, and unlock conditions
- ✅ **Tech tree UI** - Visual interface with node states, detail panel, and unlock functionality
- ✅ **Obstacle tech tree integration** - Dynamic obstacle availability based on tech unlocks
- ✅ **Save system** - Multi-slot SaveManager with atomic saves, backups, and corruption recovery
- ✅ **Save slot UI** - Selection screen with create/load/delete functionality
- ✅ **Color palette** - Standardized UI theme across all screens

### Critical Missing Systems ❌
- ❌ **Support towers** - None exist (0% - GDD core feature)
- ❌ **Tower upgrades** - Not implemented (0% - GDD core feature)
- ❌ **Multiple levels** - Only 1 level exists (need 5+ per GDD)
- ❌ **Enemy variety** - Only 2 basic zombie types (need 5+ per GDD)
- ❌ **Game over conditions** - Survivor death doesn't end game properly
- ❌ **Challenge modes** - Not started (0%)
- ❌ **Endless mode** - Not started (0%)
- ❌ **Tutorial/onboarding** - Not started (0%)

### Partial Implementations 🟡
- 🟡 **Obstacles** - Basic walls and turrets exist, but no variety or upgrades
- 🟡 **Audio** - Minimal sounds, missing survivor yelps, zombie groans, comedy soundtrack
- 🟡 **Visual style** - Generic 3D models/textures, missing modern lo-fi aesthetic (stylized low-poly with painterly textures) and comedic tone
- 🟡 **Survivors** - Exist as static targets, missing flee behavior and personality


---

## Phase 1: Foundation Systems (Critical Path)

**Goal**: Implement the core progression systems that unlock content  
**Priority**: CRITICAL  
**Status**: ✅ **COMPLETE** (October 2025)

### 1.1 Achievement System ✅ COMPLETE

#### Issue #1: Create Achievement Resource Type
**GitHub Issue**: [#110](https://github.com/saebyn/zom-nom-defense/issues/110) ✅ CLOSED  
**Status**: ✅ Complete

#### Issue #2: Implement AchievementManager Autoload
**GitHub Issue**: [#111](https://github.com/saebyn/zom-nom-defense/issues/111) ✅ CLOSED  
**Status**: ✅ Complete

#### Issue #3: Create Achievement Notification UI
**GitHub Issue**: [#112](https://github.com/saebyn/zom-nom-defense/issues/112) ✅ CLOSED  
**Status**: ✅ Complete

#### Issue #4: Create Starter Achievements
**GitHub Issue**: [#113](https://github.com/saebyn/zom-nom-defense/issues/113) ✅ CLOSED  
**Status**: ✅ Complete

#### Issue #4.5: Implement Player Progression Persistence
**GitHub Issue**: [#114](https://github.com/saebyn/zom-nom-defense/issues/114) ✅ CLOSED  
**Status**: ✅ Complete (superseded by SaveManager)

---

### 1.2 Tech Tree System ✅ COMPLETE

#### Issue #5: Design Tech Tree Structure
**GitHub Issue**: [#115](https://github.com/saebyn/zom-nom-defense/issues/115) ✅ CLOSED
**Status**: ✅ Complete

#### Issue #6: Implement TechTreeManager Autoload
**GitHub Issue**: [#116](https://github.com/saebyn/zom-nom-defense/issues/116) ✅ CLOSED  
**Status**: ✅ Complete

#### Issue #7: Connect Obstacle Unlocks to Tech Tree
**GitHub Issue**: [#117](https://github.com/saebyn/zom-nom-defense/issues/117) ✅ CLOSED  
**Status**: ✅ Complete

#### Issue #8: Create Tech Tree UI Screen
**GitHub Issue**: [#118](https://github.com/saebyn/zom-nom-defense/issues/118) ✅ CLOSED  
**Status**: ✅ Complete

#### Issue #8.5: Create Example Tech Tree Configurations
**GitHub Issue**: [#119](https://github.com/saebyn/zom-nom-defense/issues/119) ✅ CLOSED
**Status**: ✅ Complete

---

### 1.3 Multiple Levels Implementation

#### Issue #9: Create Level Selection System
**GitHub Issue**: [#120](https://github.com/saebyn/zom-nom-defense/issues/120) ✅ CLOSED
**Status**: ✅ Complete (ScenarioManager implemented)

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
**GitHub Issue**: [#144](https://github.com/saebyn/zom-nom-defense/issues/144) ✅ CLOSED

**Type**: Feature  
**Priority**: Medium (but foundational for Option A tech tree)  
**Effort**: XL
**Status**: ✅ Complete
**Description**:
Create unified save system with multiple save slots (minimum 3, like Factorio). Each save slot maintains independent progression with its own tech tree choices and in-game achievements. Steam achievements unlock globally when first earned.

**Implementation Summary**:
- ✅ SaveManager autoload with slot management
- ✅ Support for 10 save slots (configurable)
- ✅ Save slot file structure: `user://saves/save_slot_N.save`
- ✅ Global persistent data: `user://settings.cfg`
- ✅ Save slot metadata tracking (timestamp, playtime, last scenario, player level)
- ✅ Save slot selection UI with create/load/delete functionality
- ✅ Atomic writes with automatic backups (.save.bak)
- ✅ Corruption recovery from backup files
- ✅ Auto-save every 5 minutes + on scenario completion
- ✅ SaveableSystem interface for all managers
- ✅ Per-slot data: CurrencyManager, StatsManager, AchievementManager, TechTreeManager, ScenarioManager
- ✅ Global data: SettingsManager (audio, video, input settings)

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
- [ ] Add difficulty indicator to scenario select

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

Based on the 60% completion assessment:

| Phase | Issues | Completion | Status |
|-------|--------|------------|--------|
| **Phase 1: Foundation** | 11 | 100% | ✅ **COMPLETE** - All core progression systems implemented |
| **Phase 2: Content** | 15 | 10% | 🔨 IN PROGRESS - Need tower upgrades, support towers, enemy variety |
| **Phase 3: Game Modes** | 7 | 0% | 🔜 PLANNED - Requires content from Phase 2 |
| **Phase 4: Advanced** | 9 | 0% | 🔜 PLANNED - Polish and expansion |
| **Phase 5: Content Creation** | 8 | 10% | 🔄 ONGOING - Continuous content development |
| **Phase 6: Launch Prep** | 6 | 0% | 🔜 PLANNED - Final polish and release |
| **TOTAL** | **56** | **~60%** | Phase 1 complete, Phase 2 in progress |

### T-Shirt Size Reference

- **S**: Quick task, straightforward implementation
- **M**: Moderate complexity, some planning needed
- **L**: Complex feature, requires design and testing
- **XL**: Major system or significant content creation
- **XXL**: Large-scale feature affecting multiple systems

### Critical Path Status

✅ **Phase 1 Complete** - All foundation systems implemented:

1. **✅ Issue #4.5** - Player Progression Persistence - COMPLETE (SaveManager)
2. **✅ Issue #1-4** - Achievement System - COMPLETE
3. **✅ Issue #5-8.5** - Tech Tree System - COMPLETE
4. **✅ Issue #38** - Multiple Save Slots - COMPLETE

**Next Priority: Phase 2 - Content Expansion**

Now that foundational systems are complete, focus shifts to:
1. **Tower Upgrade System** (Issue #15) - Add depth to tower progression
2. **Support Tower System** (Issues #17-21) - Implement buff/synergy mechanics
3. **Enemy Variety** (Issues #22-24) - Add Scouts, Tanks, and more enemy types
4. **Additional Levels** (Issues #10-12) - Create Levels 2-4 with unique scenarios


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
