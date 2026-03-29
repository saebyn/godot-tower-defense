# Zom Nom Defense — Ubiquitous Language

This document is the **single source of truth** for domain terminology in Zom Nom Defense.
Use the canonical terms in all code identifiers, comments, documentation, and UI text.
When in doubt, consult this document before introducing or reusing a term.

> **Proposing changes:** Open a GitHub issue referencing this file. Update the document in the same PR as any code changes.

---

## Core Entities

| Canonical Term | Code Identifier(s) | Player-Facing Label | Do Not Use |
|---|---|---|---|
| **Survivor** | `Entity_Survivor`, group `"survivors"`, `survivor_group`, `on_survivor_died()` | "Survivor" | "target"[^e1], "victim", "civilian" |
| **Enemy** | `Resource_EnemyType`, `System_EnemySpawner`, `enemy_type` | "Zombie" | "zom" in code, "mob", "creature" |
| **Building** | `Entity_PlaceableBuilding`, `Entity_ShootingBuilding` | "Building" | "obstacle" when referring to the concept generically, "tower", "defense", "structure" in code/API |
| **Turret** | `Entity_ShootingBuilding` | "Turret" | "tower", "gun tower", "shooter" |
| **Scrap Pickup** | `Entity_Scrap` | "Scrap" | "loot", "drop", "pickup" |

[^e1]: "target" was the original name for Survivor before the rename tracked in issue #317. The code identifier `current_target` in `enemy.gd` is intentionally kept — it refers to the attack target (any entity), not a Survivor specifically.

---

## Economy & Progression

| Canonical Term | Code Identifier(s) | Player-Facing Label | Do Not Use |
|---|---|---|---|
| **Scrap** | `current_scrap`, `earn_scrap()`, `spend_scrap()`, `scrap_reward`, `scrap_changed` | "Scrap" | "currency", "gold", "money", "coins" |
| **XP** | `current_xp`, `xp_earned` | "XP" | "experience", "exp", "points" |
| **Player Level** | `current_level` | "Player Level" | "level" alone[^p1] |
| **Tech Node** | `Resource_TechNode`, `TechTreeManager` | "Tech" / "Research" | "upgrade", "skill" |
| **Achievement** | `Resource_Achievement`, `AchievementManager` | "Achievement" | "badge", "trophy", "unlock" |
| **Save Slot** | slot index in `SaveManager` | "Save Slot" | "save file", "profile", "run" |

[^p1]: "level" alone is ambiguous — it historically referred to a playable map (now called Scenario). Always qualify: "Player Level" for progression rank, "Scenario" for a playable map.

---

## Gameplay Sessions

| Canonical Term | Code Identifier(s) | Player-Facing Label | Do Not Use |
|---|---|---|---|
| **Scenario** | `Stage_Scenario`, `scenario_id`, `completed_scenarios`, `ScenarioManager` | "Scenario" | "level"[^g1], "map", "stage", "mission" |
| **Wave** | `System_Wave`, `wave_changed`, `waves_completed` | "Wave" | "round", "spawn event", "horde" |
| **Game Over** | `GameState.GAME_OVER` | "Game Over" | "defeat", "lose", "fail" |
| **Victory** | `GameState.VICTORY` | "Victory" | "win", "success", "complete" |
| **Paused** | `GameState.IN_GAME_MENU` | "Paused" | "suspended", "stopped" |

[^g1]: "level" was the original term for a playable map and appears in older docs and some test comments. The migration to "Scenario" is tracked in issue #317. Note: "Player Level" (progression rank) is a distinct concept — see Economy & Progression.

---

## Autoloaded Systems (Singletons)

| Canonical Term | Singleton Name | Responsibility | Do Not Use |
|---|---|---|---|
| **Currency Manager** | `CurrencyManager` | Scrap and XP balances | — |
| **Stats Manager** | `StatsManager` | Lifetime play statistics | — |
| **Game Manager** | `GameManager` | Game state machine and speed | — |
| **Scenario Manager** | `ScenarioManager` | Scenario progression and runtime session | "LevelManager" |
| **Tech Tree Manager** | `TechTreeManager` | Tech node unlocks and exclusivity | — |
| **Achievement Manager** | `AchievementManager` | Achievement tracking | — |
| **Building Registry** | `BuildingRegistry` | Catalogue of available buildings | "ObstacleManager" |
| **Audio Manager** | `AudioManager` | SFX and music playback | — |
| **Settings Manager** | `SettingsManager` | User preferences | — |
| **Save Manager** | `SaveManager` | Multi-slot save/load | — |
| **Survivor Name Manager** | `SurvivorNameManager` | Persistent survivor name profiles | "TargetNameManager" |
| **Logger** | `MyLogger` | Centralised logging with scope filtering | — |

---

## Components

| Canonical Term | Code Identifier | Responsibility | Do Not Use |
|---|---|---|---|
| **Health Component** | `Component_Health` | Hitpoints, damage, death, unit frame display | — |
| **Attack Component** | `Component_Attack` | Attack cooldown and damage application | — |
| **AttackEffect Component** | `Component_AttackEffect` | Attack damage multipliers, AoE damage, status effects | "damage type component", "attack modifier" |
| **DoT Effect** | `Component_DotEffect` | Damage-over-time area | "poison component", "fire component" |
| **Passive Damage** | `Component_PassiveDamage` | Instant contact damage | — |
| **Panic Behavior** | `Component_PanicBehavior` | Survivor flee/panic animation | — |
| **Damage Numbers** | `Component_DamageNumbers` | Floating damage and scrap-gain labels | "floating text", "hit numbers" |

---

## UI Concepts

| Canonical Term | Code Identifier(s) | Player-Facing Label | Do Not Use |
|---|---|---|---|
| **Unit Frame** | `unit_frame_enabled`, `show_unit_frame()`, `hide_unit_frame()` | "Health Bar" | "health bar" in code/exports[^u1], "HP bar" |
| **Health Bar** | `health_bar` (`ProgressBar` node within the unit frame) | — | Do not use for the whole overlay |
| **Hotbar** | `UI_Hotbar` | "Hotbar" | "toolbar", "building bar", "action bar" |
| **Minimap** | `UI_Minimap` | "Minimap" | "map", "radar" |
| **Wave Indicator** | `UI_SpawnIndicator` | "Wave Indicator" | "spawn timer", "enemy counter" |
| **Enemy Indicator** | `UI_OffscreenIndicator` | "Enemy Indicator" | "arrow indicator", "offscreen marker" |
| **Resource Display** | `UI_CurrencyDisplay` | "Resource Display" | "HUD", "currency bar" |
| **Scenario Select** | `UI_ScenarioSelect` | "Scenario Selection" | "Level Select"[^g1], "Map Select" |

[^u1]: `bar_color` and `use_custom_bar_color` exports in `Component_Health` are **pending rename** to `fill_color` / `use_custom_fill_color`. See [Pending Code Renames](#pending-code-renames).

---

## Sound Effect Categories

| Canonical Term | SFX Enum Prefix | Do Not Use |
|---|---|---|
| **Player SFX** | `PLAYER_*` | — |
| **Zombie SFX** | `ZOMBIE_*` | `ENEMY_*` |
| **Survivor SFX** | `SURVIVOR_*` | `TARGET_*` |
| **Building SFX** | `BUILDING_*` | `OBSTACLE_*` |
| **Turret SFX** | `TURRET_*` | — |
| **Wave SFX** | `WAVE_*` | `ROUND_*` |
| **UI SFX** | `UI_*` | — |
| **Scenario SFX** | `SCENARIO_*` | `LEVEL_*` |

---

## Pending Code Renames

These identifiers use the old terminology and are scheduled for renaming. Use the canonical term in new code; do not introduce further uses of the old names.

| Current Identifier | Canonical Replacement | Scope | Priority |
|---|---|---|---|
| `bar_color` / `use_custom_bar_color` | `fill_color` / `use_custom_fill_color` | `Component_Health` exports | Low |
