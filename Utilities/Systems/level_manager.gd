extends Node

## Manages all level-related state: runtime session state and persistent progression
## Implements SaveableSystem interface for centralized save management
## 
## Runtime State (per gameplay session):
## - Current level being played
## - Current wave within that level
## 
## Persistent State (saved across sessions):
## - Completed levels
## - Best times and scores per level
## - Level unlocking logic

# Runtime state (resets each session)
var current_level_id: String = "" # Currently active level (e.g., "level_1")
var current_wave: int = 0 # Current wave number within the active level

# Persistent state (saved across sessions)
var completed_levels: Array[String] = [] # Array of completed level IDs ["level_1", "level_2"]
var level_best_times: Dictionary = {} # level_id -> best time in seconds
var level_best_scores: Dictionary = {} # level_id -> best score

# Level metadata (can be extended to load from resources in the future)
var level_metadata: Dictionary = {
  "level_1": {
    "name": "Bridge Defense",
    "scene_path": "res://Stages/Game/main/main.tscn",
    "description": "Defend a person on top of a car.",
    "thumbnail": "", # Optional icon path
  },
  # Level 2-4 placeholders for future content
  "level_2": {
    "name": "Campfire Survivors",
    "scene_path": "", # To be created
    "description": "Protect two survivors next to a campfire.",
    "thumbnail": "",
  },
  "level_3": {
    "name": "Hammock Defense",
    "scene_path": "", # To be created
    "description": "Guard a survivor in a hammock between two poles.",
    "thumbnail": "",
  },
  "level_4": {
    "name": "Pool Party",
    "scene_path": "", # To be created
    "description": "Defend survivors in an inflatable pool.",
    "thumbnail": "",
  },
}

# Signals - Persistent progression
signal level_completed(level_id: String)
signal level_unlocked(level_id: String)
signal progression_saved()
signal progression_loaded()

# Signals - Runtime state
signal level_started(level_id: String)
signal wave_changed(level_id: String, wave: int)
signal level_ended(level_id: String)

func _ready():
  # Register with SaveManager
  SaveManager.register_system(self)
  
  Logger.info("LevelManager", "Level Manager initialized")

## Runtime State Management

## Set the current level being played
func set_current_level_id(level_id: String) -> void:
  if current_level_id != level_id:
    current_level_id = level_id
    current_wave = 0 # Reset wave when changing levels
    level_started.emit(level_id)
    Logger.info("LevelManager", "Current level set to: %s" % level_id)

## Get the current level ID being played
func get_current_level_id() -> String:
  return current_level_id

## Clear the current level (e.g., when returning to menu)
func clear_current_level() -> void:
  if not current_level_id.is_empty():
    var old_level = current_level_id
    current_level_id = ""
    current_wave = 0
    level_ended.emit(old_level)
    Logger.info("LevelManager", "Cleared current level: %s" % old_level)

## Set the current wave number (within the current level)
func set_current_wave(wave: int) -> void:
  if current_wave != wave:
    current_wave = wave
    wave_changed.emit(current_level_id, wave)
    Logger.info("LevelManager", "Wave changed to %d in level %s" % [wave, current_level_id])

## Get the current wave number
func get_current_wave() -> int:
  return current_wave

## Persistent Progression Management

## Mark a level as completed
func mark_level_complete(level_id: String, time: float = 0.0, score: int = 0) -> void:
  if level_id not in completed_levels:
    completed_levels.append(level_id)
    level_completed.emit(level_id)
    Logger.info("LevelManager", "Level %s marked as complete" % level_id)
    
    # Check if we unlocked the next level
    var next_level = _get_next_level_id(level_id)
    if next_level and is_level_unlocked(next_level):
      level_unlocked.emit(next_level)
  
  # Update best time (if better or first time)
  if time > 0.0:
    if level_id not in level_best_times or time < level_best_times[level_id]:
      level_best_times[level_id] = time
      Logger.info("LevelManager", "New best time for %s: %.2f seconds" % [level_id, time])
  
  # Update best score (if better or first time)
  if score > 0:
    if level_id not in level_best_scores or score > level_best_scores[level_id]:
      level_best_scores[level_id] = score
      Logger.info("LevelManager", "New best score for %s: %d" % [level_id, score])

## Check if a level is unlocked
func is_level_unlocked(level_id: String) -> bool:
  # Level 1 always unlocked
  if level_id == "level_1":
    return true
  
  # Extract level number
  var level_num = int(level_id.replace("level_", ""))
  if level_num <= 1:
    return true
  
  # Check if previous level is completed
  var prev_level = "level_%d" % (level_num - 1)
  return completed_levels.has(prev_level)

## Check if a level is completed
func is_level_completed(level_id: String) -> bool:
  return completed_levels.has(level_id)

## Get best time for a level (0.0 if not played)
func get_best_time(level_id: String) -> float:
  return level_best_times.get(level_id, 0.0)

## Get best score for a level (0 if not played)
func get_best_score(level_id: String) -> int:
  return level_best_scores.get(level_id, 0)

## Get level metadata
func get_level_metadata(level_id: String) -> Dictionary:
  return level_metadata.get(level_id, {})

## Get all available level IDs
func get_all_level_ids() -> Array[String]:
  var ids: Array[String] = []
  for key in level_metadata.keys():
    ids.append(key)
  ids.sort()
  return ids

## Get the previous level requirement for unlocking
func get_unlock_requirement(level_id: String) -> String:
  var level_num = int(level_id.replace("level_", ""))
  if level_num <= 1:
    return "" # No requirement
  return "level_%d" % (level_num - 1)

## Helper to get next level ID
func _get_next_level_id(level_id: String) -> String:
  var level_num = int(level_id.replace("level_", ""))
  var next_level = "level_%d" % (level_num + 1)
  if next_level in level_metadata:
    return next_level
  return ""

## SaveableSystem Interface Implementation

## Get unique save key for this system
func get_save_key() -> String:
  return "level_progression"

## Get saveable state as dictionary
func get_save_data() -> Dictionary:
  return {
    "completed_levels": completed_levels,
    "level_best_times": level_best_times,
    "level_best_scores": level_best_scores,
  }

## Load data from saved state
func load_data(data: Dictionary) -> void:
  # Load the data with fallbacks
  var loaded_completed: Array = data.get("completed_levels", [])
  completed_levels.clear()
  for level in loaded_completed:
    if level is String:
      completed_levels.append(level)
  
  level_best_times = data.get("level_best_times", {})
  level_best_scores = data.get("level_best_scores", {})
  
  Logger.info("LevelManager", "Level progression loaded - Completed: %s" % str(completed_levels))
  progression_loaded.emit()

## Reset to default state (for new game)
func reset_data() -> void:
  completed_levels.clear()
  level_best_times.clear()
  level_best_scores.clear()
  
  Logger.info("LevelManager", "Level progression reset")

## Legacy Methods (deprecated, kept for backward compatibility)

## Manual save method for external use (now delegates to SaveManager)
func save_progression_now() -> void:
  SaveManager.save_current_slot()

## Delete save file (delegates to SaveManager)
func delete_saved_progression() -> bool:
  if SaveManager.current_save_slot > 0:
    return SaveManager.delete_save_slot(SaveManager.current_save_slot)
  return true
