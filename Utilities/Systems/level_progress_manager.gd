extends Node

## Manages level progression and completion tracking
## Handles level unlocking logic and persistence

# Save constants
const LEVEL_PROGRESS_SAVE_PATH = "user://level_progression.save"
const SAVE_VERSION = 1

# Level completion tracking
var completed_levels: Array[String] = []  # Array of completed level IDs ["level_1", "level_2"]
var level_best_times: Dictionary = {}  # level_id -> best time in seconds
var level_best_scores: Dictionary = {}  # level_id -> best score

# Level metadata (can be extended to load from resources in the future)
var level_metadata: Dictionary = {
  "level_1": {
    "name": "Bridge Defense",
    "scene_path": "res://Stages/Game/main/main.tscn",
    "description": "Defend a person on top of a car.",
    "thumbnail": "",  # Optional icon path
  },
  # Level 2-4 placeholders for future content
  "level_2": {
    "name": "Campfire Survivors",
    "scene_path": "",  # To be created
    "description": "Protect two survivors next to a campfire.",
    "thumbnail": "",
  },
  "level_3": {
    "name": "Hammock Defense",
    "scene_path": "",  # To be created
    "description": "Guard a survivor in a hammock between two poles.",
    "thumbnail": "",
  },
  "level_4": {
    "name": "Pool Party",
    "scene_path": "",  # To be created
    "description": "Defend survivors in an inflatable pool.",
    "thumbnail": "",
  },
}

# Signals
signal level_completed(level_id: String)
signal level_unlocked(level_id: String)
signal progression_saved()
signal progression_loaded()

func _ready():
  _load_progression()
  Logger.info("LevelProgressManager", "Level Progress Manager initialized")

## Mark a level as completed
func mark_level_complete(level_id: String, time: float = 0.0, score: int = 0) -> void:
  if level_id not in completed_levels:
    completed_levels.append(level_id)
    level_completed.emit(level_id)
    Logger.info("LevelProgressManager", "Level %s marked as complete" % level_id)
    
    # Check if we unlocked the next level
    var next_level = _get_next_level_id(level_id)
    if next_level and is_level_unlocked(next_level):
      level_unlocked.emit(next_level)
  
  # Update best time (if better or first time)
  if time > 0.0:
    if level_id not in level_best_times or time < level_best_times[level_id]:
      level_best_times[level_id] = time
      Logger.info("LevelProgressManager", "New best time for %s: %.2f seconds" % [level_id, time])
  
  # Update best score (if better or first time)
  if score > 0:
    if level_id not in level_best_scores or score > level_best_scores[level_id]:
      level_best_scores[level_id] = score
      Logger.info("LevelProgressManager", "New best score for %s: %d" % [level_id, score])
  
  _save_progression()

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
    return ""  # No requirement
  return "level_%d" % (level_num - 1)

## Helper to get next level ID
func _get_next_level_id(current_level_id: String) -> String:
  var level_num = int(current_level_id.replace("level_", ""))
  var next_level = "level_%d" % (level_num + 1)
  if next_level in level_metadata:
    return next_level
  return ""

## Save progression to disk
func _save_progression() -> void:
  var save_file = FileAccess.open(LEVEL_PROGRESS_SAVE_PATH, FileAccess.WRITE)
  if not save_file:
    Logger.error("LevelProgressManager", "Could not open save file for writing: %s" % LEVEL_PROGRESS_SAVE_PATH)
    return
  
  var save_data = {
    "version": SAVE_VERSION,
    "completed_levels": completed_levels,
    "level_best_times": level_best_times,
    "level_best_scores": level_best_scores,
  }
  
  save_file.store_string(JSON.stringify(save_data))
  save_file.close()
  
  Logger.info("LevelProgressManager", "Level progression saved - Completed: %s" % str(completed_levels))
  progression_saved.emit()

## Load progression from disk
func _load_progression() -> bool:
  if not FileAccess.file_exists(LEVEL_PROGRESS_SAVE_PATH):
    Logger.info("LevelProgressManager", "No level progress save file found, starting fresh")
    return false
  
  var save_file = FileAccess.open(LEVEL_PROGRESS_SAVE_PATH, FileAccess.READ)
  if not save_file:
    Logger.error("LevelProgressManager", "Could not open save file for reading: %s" % LEVEL_PROGRESS_SAVE_PATH)
    return false
  
  var json_string = save_file.get_as_text()
  save_file.close()
  
  var json = JSON.new()
  var parse_result = json.parse(json_string)
  
  if parse_result != OK:
    Logger.error("LevelProgressManager", "Error parsing save file: %s" % json.get_error_message())
    return false
  
  var save_data = json.get_data()
  
  if not (save_data is Dictionary):
    Logger.error("LevelProgressManager", "Save file contains invalid data")
    return false
  
  # Load the data with fallbacks
  var loaded_completed: Array = save_data.get("completed_levels", [])
  completed_levels.clear()
  for level in loaded_completed:
    if level is String:
      completed_levels.append(level)
  
  level_best_times = save_data.get("level_best_times", {})
  level_best_scores = save_data.get("level_best_scores", {})
  
  Logger.info("LevelProgressManager", "Level progression loaded - Completed: %s" % str(completed_levels))
  progression_loaded.emit()
  return true

## Manual save method for external use
func save_progression_now() -> void:
  _save_progression()

## Delete save file (for complete reset)
func delete_saved_progression() -> bool:
  if FileAccess.file_exists(LEVEL_PROGRESS_SAVE_PATH):
    var dir = DirAccess.open("user://")
    if dir:
      var filename = LEVEL_PROGRESS_SAVE_PATH.replace("user://", "")
      dir.remove(filename)
      Logger.info("LevelProgressManager", "Level progression save file deleted")
      
      # Reset in-memory data
      completed_levels.clear()
      level_best_times.clear()
      level_best_scores.clear()
      return true
    else:
      Logger.error("LevelProgressManager", "Could not access user directory to delete save file")
      return false
  return true
