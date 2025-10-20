# Tech Tree Design

The tree begins with **three starter nodes** (one per main branch) that are immediately available to unlock, then branches into five base categories:

* **Offensive** – Damage-dealing turrets and traps (starter: Scrap Shooter)
* **Defensive** – Obstacles/walls, path control, debuffs (starter: Stacked Crates)
* **Economy** – Scrap generation/harvest boosts (starter: Scrap Recycler)
* **Support** – Buff auras, repairs, synergy amplifiers (all require progression)
* **Click** – Player's manual damage & click perks (all require progression)

**Unlock Model:** Nodes require **Player Level (XP)** and/or **Achievements** (e.g., *Place 3 defenses*, *Survive 3 waves*). Some nodes are **mutually exclusive** with alternatives. **Tech tree unlocking is free** - no scrap cost.

**Starting State:** Players begin with **zero techs unlocked** in each save slot. The three starter nodes (`tur_scrap_shooter`, `ob_crates`, `eco_scrap_recycler`) have level 1 requirements with no prerequisites, making them **immediately available to unlock** at the start of a new game. This provides an introduction to the tech tree mechanic - players must actively unlock these starter techs before they can place those obstacles during gameplay. Tech unlocks are **persistent per save slot** and carry forward across all levels within that save.

**Scrap Economy:** Scrap is earned and spent **during gameplay** to place instances of unlocked obstacles/turrets. The tech tree itself never costs scrap to interact with.

---

## 1) Purpose & Scope

Design the complete tech tree with **mutually exclusive branches**, mapping gameplay elements (obstacles, turrets, support, economy, click upgrades) to tech nodes and defining unlock requirements (level, prerequisites, achievements, costs). This spec guides content authoring and UI/UX but does **not** prescribe engine code.

### Goals

* Meaningful choices that change playstyle
* Permanent consequences per run (no mid-run respec)
* Replayability via distinct specializations
* Clear, readable data model (JSON/tres friendly)

### Scope Summary

* **Total Nodes**: 25 (5 Offensive, 5 Defensive, 4 Economy, 4 Support, 4 Click, 3 Advanced)
* **Mutually Exclusive Pairs**: 3 (Boom Barrel/Molotov Mortar, Industrial/Drone, Shock Click/Double Tap)
* **Branch Completion Gates**: 3 Advanced nodes require full branch mastery
* **Starting State**: Players begin with **no techs unlocked** - must unlock everything through progression
* **Starter Techs**: 3 level-1 nodes available immediately (Scrap Shooter, Stacked Crates, Scrap Recycler)
* **Max Level Requirement**: 6 (Synergy Hub)

### Tech Tree vs Gameplay Economy

* **Tech Tree Unlocking**: Based on player level, achievements, and prerequisites. **No scrap cost** - unlocking is progression-based.
* **Gameplay Placement**: Once unlocked in tech tree, obstacles/turrets become **available to place** during levels. Placing instances **costs scrap** (defined per obstacle type, not in tech tree).

---

## 2) Branch Overview

The tree begins at the **Root: Basic Survival** and branches into five base categories:

* **Offensive** – Damage-dealing turrets and traps
* **Defensive** – Obstacles/walls, path control, debuffs (non-damaging unless stated)
* **Economy** – Scrap generation/harvest boosts
* **Support** – Buff auras, repairs, synergy amplifiers
* **Click** – Player’s manual damage & click perks

> **Unlock Model:** Nodes may require **Player Level (XP)** and/or **Achievements** (e.g., *Place 3 defenses*, *Survive 3 waves*). Some nodes are **mutually exclusive** with alternatives.

---

## 3) Full Graph (High-Level ASCII)

```
Starter Techs (level 1, no prerequisites - immediately available):
├─ Scrap Shooter (T1) [Offensive]
├─ Stacked Crates (T1) [Defensive]
└─ Scrap Recycler (T1) [Economy]

Tech Tree:
├─ Offensive
│  ├─ Scrap Shooter (T1) [STARTER - Level 1, no prerequisites]
│  │  ├─ Boom Barrel (T2) ──[EXC]── Molotov Mortar (T4)
│  │  └─ Saw Spitter (T3) ──► Zed Zapper (T4)
│  └─ (future) Spitter Nest / Piercing Rail
│
├─ Defensive
│  ├─ Stacked Crates (T1) [STARTER - Level 1, no prerequisites]
│  │  ├─ Oil Slick (T2) ──► (Synergy: ignites with Molotov)
│  │  └─ Spike Barricade (T2) ──► Electric Fence (T3) [needs Zed Zapper]
│  └─ Zombie Bait Sign (T3)
│
├─ Economy
│  ├─ Scrap Recycler (T1) [STARTER - Level 1, no prerequisites]
│  │  └─ [EXC] Industrial Recycler (T2)  ⟂  Drone Salvager (T2)
│  └─ Harvest Boosts (T2+)
│
├─ Support
│  ├─ Overcharger (T2)
│  │  ├─ Range Amplifier (T3)
│  │  └─ Cooldown Beacon (T3) ──► Auto‑Repair Drone (T4)
│  └─ (future) Target Painter
│
└─ Click
   ├─ Hydraulic Mouse (T2)
   │  ├─ [EXC] Double Tap (T3)  ⟂  Shock Click (T3)
   │  └─ Recoil Dampener (T3)
   └─ (future) Click Splash+, Chain Click

Advanced (requires branch completion):
├─ Experimental Weapons (T5) [requires: Offensive completion]
│  └─ Unlocks: Railgun Turret, EMP Mine
├─ Fortification Mastery (T5) [requires: Defensive completion]
│  └─ Unlocks: Reinforced Walls, Kill Zone Trap
└─ Synergy Hub (T6) [requires: Support + Economy completion]
   └─ Unlocks: Power Grid, Resource Amplifier Network
```

Legend: **T#** = Tier; **[EXC]** = mutually exclusive pair; **⟂** = exclusivity marker; **►** = linear prerequisite; **Synergy** = combo dependency.

---

## 4) Node Catalog (Representative Set)

> **Note:** IDs are lowercase with prefixes: `tur_` (turret), `ob_` (obstacle), `sup_` (support), `eco_` (economy), `clk_` (click), `adv_` (advanced).

### Offensive

| id                   | display_name   | description                         | level | prerequisites       | achievements   | mutually_exclusive_with | branch_name | unlocked_obstacle_ids | requires_branch_completion | notes |
| -------------------- | -------------- | ----------------------------------- | ----: | ------------------- | -------------- | ----------------------- | ----------- | --------------------- | -------------------------- | ----- |
| `tur_scrap_shooter`  | Scrap Shooter  | Basic bolt-firing turret.           |     1 | []                  | []             | []                      | Offensive   | [turret]              | []                         | **Starter tech** - Available immediately |
| `tur_boom_barrel`    | Boom Barrel    | One-shot AoE explosive trap.        |     2 | [tur_scrap_shooter] | [ach_place_3]  | [tur_molotov_mortar]    | Offensive   | [boom_barrel]         | []                         | |
| `tur_saw_spitter`    | Saw Spitter    | High damage, short range, piercing. |     3 | [tur_scrap_shooter] | []             | []                      | Offensive   | [saw_spitter]         | []                         | |
| `tur_zed_zapper`     | Zed Zapper     | Chains lightning between targets.   |     4 | [tur_saw_spitter]   | []             | []                      | Offensive   | [zed_zapper]          | []                         | |
| `tur_molotov_mortar` | Molotov Mortar | Lobbed fire; ignites Oil Slick.     |     4 | [tur_scrap_shooter] | [ach_kill_100] | [tur_boom_barrel]       | Offensive   | [molotov_mortar]      | []                         | |

### Defensive

| id                    | display_name     | description                         | level | prerequisites        | achievements    | mutually_exclusive_with | branch_name | unlocked_obstacle_ids | requires_branch_completion | notes |
| --------------------- | ---------------- | ----------------------------------- | ----: | -------------------- | --------------- | ----------------------- | ----------- | --------------------- | -------------------------- | ----- |
| `ob_crates`           | Stacked Crates   | Simple wall; minor slow on contact. |     1 | []                   | []              | []                      | Defensive   | [wall]                | []                         | **Starter tech** - Available immediately |
| `ob_oil_slick`        | Oil Slick        | Ground slow; flammable synergy.     |     2 | [ob_crates]          | []              | []                      | Defensive   | [oil_slick]           | []                         | |
| `ob_spike_barricade`  | Spike Barricade  | Blocks and deals contact damage.    |     2 | [ob_crates]          | [ach_place_3]   | []                      | Defensive   | [spike_barricade]     | []                         | |
| `ob_electric_fence`   | Electric Fence   | DoT fence; **requires Zed Zapper**. |     3 | [ob_spike_barricade] | [ach_survive_3] | []                      | Defensive   | [electric_fence]      | []                         | |
| `ob_zombie_bait_sign` | Zombie Bait Sign | Lure that manipulates pathing.      |     3 | [ob_crates]          | []              | []                      | Defensive   | [zombie_bait_sign]    | []                         | |

### Economy

| id                        | display_name        | description                   | level | prerequisites        | achievements | mutually_exclusive_with   | branch_name | unlocked_obstacle_ids | requires_branch_completion | notes |
| ------------------------- | ------------------- | ----------------------------- | ----: | -------------------- | ------------ | ------------------------- | ----------- | --------------------- | -------------------------- | ----- |
| `eco_scrap_recycler`      | Scrap Recycler      | Generates Scrap over time.    |     1 | []                   | []           | []                        | Economy     | [scrap_recycler]      | []                         | **Starter tech** - Available immediately |
| `eco_industrial_recycler` | Industrial Recycler | Higher income generator.      |     2 | [eco_scrap_recycler] | []           | [eco_drone_salvager]      | Economy     | [industrial_recycler] | []                         | |
| `eco_drone_salvager`      | Drone Salvager      | Sends drones to harvestables. |     2 | [eco_scrap_recycler] | []           | [eco_industrial_recycler] | Economy     | [drone_salvager]      | []                         | |
| `eco_harvest_boost`       | Harvest Boost       | +% yield from world nodes.    |     3 | [eco_scrap_recycler] | []           | []                        | Economy     | []                    | []                         | |

### Support

| id                    | display_name      | description                  | level | prerequisites         | achievements          | mutually_exclusive_with | branch_name | unlocked_obstacle_ids | requires_branch_completion | notes |
| --------------------- | ----------------- | ---------------------------- | ----: | --------------------- | --------------------- | ----------------------- | ----------- | --------------------- | -------------------------- | ----- |
| `sup_overcharger`     | Overcharger       | Aura: +fire rate to turrets. |     2 | []                    | []                    | []                      | Support     | [overcharger]         | []                         | |
| `sup_range_amp`       | Range Amplifier   | Aura: +range to turrets.     |     3 | [sup_overcharger]     | []                    | []                      | Support     | [range_amplifier]     | []                         | |
| `sup_cooldown_beacon` | Cooldown Beacon   | Aura: −reload/cooldowns.     |     3 | [sup_overcharger]     | []                    | []                      | Support     | [cooldown_beacon]     | []                         | |
| `sup_repair_drone`    | Auto‑Repair Drone | Repairs nearby defenses.     |     4 | [sup_cooldown_beacon] | [ach_lose_5_defenses] | []                      | Support     | [repair_drone]        | []                         | |

### Click

| id                    | display_name    | description                                                | level | prerequisites         | achievements         | mutually_exclusive_with | branch_name | unlocked_obstacle_ids | requires_branch_completion | notes |
| --------------------- | --------------- | ---------------------------------------------------------- | ----: | --------------------- | -------------------- | ----------------------- | ----------- | --------------------- | -------------------------- | ----- |
| `clk_hydraulic_mouse` | Hydraulic Mouse | +25% click damage.                                         |     2 | []                    | []                   | []                      | Click       | []                    | []                         | |
| `clk_shock_click`     | Shock Click     | Clicks splash in small AoE.                                |     3 | [clk_hydraulic_mouse] | [ach_click_kills_25] | [clk_double_tap]        | Click       | []                    | []                         | |
| `clk_double_tap`      | Double Tap      | 10% crit chance on clicks.                                 |     3 | [clk_hydraulic_mouse] | [ach_click_100]      | [clk_shock_click]       | Click       | []                    | []                         | |
| `clk_recoil_dampener` | Recoil Dampener | Mitigates nearby turret accuracy penalties while clicking. |     3 | [clk_hydraulic_mouse] | []                   | []                      | Click       | []                    | []                         | |

### Advanced

| id                          | display_name          | description                                                          | level | prerequisites | achievements   | mutually_exclusive_with | branch_name | unlocked_obstacle_ids            | requires_branch_completion | notes |
| --------------------------- | --------------------- | -------------------------------------------------------------------- | ----: | ------------- | -------------- | ----------------------- | ----------- | -------------------------------- | -------------------------- | ----- |
| `adv_experimental_weapons`  | Experimental Weapons  | Unlocks cutting-edge offensive tech after mastering basic weaponry.  |     5 | []            | [ach_kill_500] | []                      | Advanced    | [railgun_turret, emp_mine]       | [Offensive]                | |
| `adv_fortification_mastery` | Fortification Mastery | Advanced defensive structures for veterans of defensive strategy.    |     5 | []            | [ach_survive_10] | []                    | Advanced    | [reinforced_wall, kill_zone]     | [Defensive]                | |
| `adv_synergy_hub`           | Synergy Hub           | Combines economic and support systems for ultimate efficiency.       |     6 | []            | [ach_place_50] | []                      | Advanced    | [power_grid, resource_amplifier] | [Support, Economy]         | |

---

## 5) Mapping Gameplay Elements → Tech Nodes

* **Walls/Obstacles:** `ob_crates`, `ob_spike_barricade`, `ob_oil_slick`, `ob_electric_fence`, `ob_zombie_bait_sign`, `adv_fortification_mastery` (reinforced_wall, kill_zone)
* **Turrets/Damage:** `tur_scrap_shooter`, `tur_boom_barrel`, `tur_saw_spitter`, `tur_zed_zapper`, `tur_molotov_mortar`, `adv_experimental_weapons` (railgun_turret, emp_mine)
* **Support:** `sup_overcharger`, `sup_range_amp`, `sup_cooldown_beacon`, `sup_repair_drone`, `adv_synergy_hub` (power_grid)
* **Economy:** `eco_scrap_recycler`, `eco_industrial_recycler`, `eco_drone_salvager`, `eco_harvest_boost`, `adv_synergy_hub` (resource_amplifier)
* **Click Upgrades:** `clk_hydraulic_mouse`, `clk_shock_click`, `clk_double_tap`, `clk_recoil_dampener`
* **Advanced Cross-Branch:** `adv_experimental_weapons`, `adv_fortification_mastery`, `adv_synergy_hub`

---

## 6) Mutually Exclusive Branch Points

* **Offensive:** `tur_boom_barrel` ⟂ `tur_molotov_mortar` (choose explosives trap line **or** lobbed fire artillery)
* **Economy:** `eco_industrial_recycler` ⟂ `eco_drone_salvager` (high passive income **or** active world-harvest play)
* **Click:** `clk_shock_click` ⟂ `clk_double_tap` (splash control **or** crit focus)

> Choosing one locks the other for the duration of the run/save. UI must clearly warn the player.

---

## 7) Unlock Requirements (Model)

Each node defines:

* **`level_requirement`** – Player level threshold (from XP via zombie kills)
* **`prerequisites`** – Techs that must be unlocked first
* **`achievements`** – Optional gating (e.g., `ach_place_3`, `ach_survive_3`, `ach_kill_100`, `ach_click_100`, `ach_click_kills_25`, `ach_lose_5_defenses`)
* **`branch_name`** – Category/branch identifier (Offensive, Defensive, Economy, Support, Click, Advanced)
* **`unlocked_obstacle_ids`** – Array of obstacle IDs that become available when this tech is unlocked
* **`requires_branch_completion`** – Array of branch names that must be fully completed before this tech unlocks
  - A branch is "fully completed" when all non-Advanced techs in that branch are unlocked
  - Example: `[Offensive]` means all Offensive nodes (excluding mutually exclusive alternatives) must be unlocked
  - Example: `[Support, Economy]` means BOTH branches must be fully completed
  - Advanced tier nodes use this to gate late-game content behind mastery of core branches

> **Note on Tiers vs Levels:** "Tier" (T1, T2, etc.) in the ASCII tree refers to visual/logical grouping for design purposes. The actual unlock gate is the `level_requirement` field, which checks the player's current level from XP.

> **Note on Cross-Branch Dependencies:** Some nodes have implicit synergies with other branches (e.g., Electric Fence works better with Zed Zapper, Oil Slick ignites with Molotov Mortar). These are design recommendations, not hard prerequisites in the data model. Implement as gameplay synergies rather than unlock gates.

> **Note on Scrap Economy:** Tech tree unlocking is **free** and based purely on progression (level/achievements/prerequisites). Scrap is only spent **during gameplay** to place instances of unlocked obstacles/turrets. Placement costs are defined in `ObstacleTypeResource`, not in the tech tree data.

---

## 8) Player Warnings & UX Copy (Exclusivity)

When the player clicks an exclusive node:

**Title:** "Make Your Choice"
**Body:** "Unlocking **{TECH}** will permanently lock **{CONFLICTING_TECHS}** for this run. This choice cannot be undone. Proceed?"
**Options:** `Cancel` / `Unlock`
**Tooltip (hover on locked tech):** "Locked due to prior choice: {CHOSEN_TECH}."

---

## 9) Example JSON Snippets (Authoring Format)

```json
{
  "id": "tur_boom_barrel",
  "display_name": "Boom Barrel",
  "description": "One-shot explosive trap that damages all zombies in a small radius.",
  "level_requirement": 2,
  "prerequisites": ["tur_scrap_shooter"],
  "achievements": ["ach_place_3"],
  "mutually_exclusive_with": ["tur_molotov_mortar"],
  "branch_name": "Offensive",
  "unlocked_obstacle_ids": ["boom_barrel"],
  "requires_branch_completion": []
}
```

```json
{
  "id": "clk_double_tap",
  "display_name": "Double Tap",
  "description": "10% chance for clicks to deal double damage.",
  "level_requirement": 3,
  "prerequisites": ["clk_hydraulic_mouse"],
  "achievements": ["ach_click_100"],
  "mutually_exclusive_with": ["clk_shock_click"],
  "branch_name": "Click",
  "unlocked_obstacle_ids": [],
  "requires_branch_completion": []
}
```

```json
{
  "id": "eco_harvest_boost",
  "display_name": "Harvest Boost",
  "description": "Increases yield from world scrap nodes by 25%.",
  "level_requirement": 3,
  "prerequisites": ["eco_scrap_recycler"],
  "achievements": [],
  "mutually_exclusive_with": [],
  "branch_name": "Economy",
  "unlocked_obstacle_ids": [],
  "requires_branch_completion": []
}
```

**Advanced Tier Example (Branch Completion Required):**

```json
{
  "id": "adv_synergy_hub",
  "display_name": "Synergy Hub",
  "description": "Combines economic and support systems for ultimate efficiency. Unlocks Power Grid and Resource Amplifier.",
  "level_requirement": 6,
  "prerequisites": [],
  "achievements": ["ach_place_50"],
  "mutually_exclusive_with": [],
  "branch_name": "Advanced",
  "unlocked_obstacle_ids": ["power_grid", "resource_amplifier"],
  "requires_branch_completion": ["Support", "Economy"]
}
```

> **Note:** The Synergy Hub requires completing BOTH the Support and Economy branches. This means all techs in those branches must be unlocked (excluding mutually exclusive alternatives that were not chosen).

> **Reminder:** No `scrap_cost` field exists in tech tree nodes. Unlocking is free and progression-based. Scrap is spent during gameplay to place obstacles.

---

## 10) Balance Notes & Next Steps

* **Progression Model**: Tech unlocks are **persistent per save slot**. Each new save starts with zero unlocked techs, forcing players to unlock even starter techs. This introduces the tech tree mechanic early and creates a sense of progression across levels within a save.
* Tech tree unlocking is **free** and progression-based - no scrap costs. This focuses the tech tree on strategic choices rather than resource management.
* Gate high-impact combos behind both **level** and **achievements** (e.g., `ob_electric_fence` requires level 3 + achievement).
* **Advanced tier nodes** require branch completion, creating natural progression gates for late-game content.
* Branch completion logic must account for mutually exclusive choices (completing one path counts toward branch completion).
* Advanced nodes have higher level requirements (5-6) to reflect their position as late-game unlocks.
* Scrap economy balancing happens in `ObstacleTypeResource` placement costs, not tech tree.

---

## 11) Appendix – Achievements Reference

**Basic Achievements (used for early tech unlocks):**
* `ach_place_3` – Place 3 defenses in a single level.
* `ach_survive_3` – Survive 3 waves.
* `ach_kill_100` – Defeat 100 zombies.
* `ach_click_100` – Click 100 times total.
* `ach_click_kills_25` – Defeat 25 zombies via clicks.
* `ach_lose_5_defenses` – Lose 5 placed defenses in one level.

**Advanced Achievements (used for late-game tech unlocks):**
* `ach_kill_500` – Defeat 500 zombies total. (Required for Experimental Weapons)
* `ach_survive_10` – Survive 10 waves in a single level. (Required for Fortification Mastery)
* `ach_place_50` – Place 50 defenses total across all playthroughs. (Required for Synergy Hub)
