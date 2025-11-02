extends Node

## Manages all scenario-related state: runtime session state and persistent progression
## Implements SaveableSystem interface for centralized save management
## 
## Runtime State (per gameplay session):
## - Current scenario being played
## - Current wave within that scenario
## 
## Persistent State (saved across sessions):
## - Completed scenarios
## - Best times and scores per scenario
## - Scenario unlocking logic

# Runtime state (resets each session)
var current_scenario_id: String = "" # Currently active scenario (e.g., "scenario_1")
var current_wave: int = 0 # Current wave number within the active scenario

# Persistent state (saved across sessions)
var completed_scenarios: Array[String] = [] # Array of completed scenario IDs ["scenario_1", "scenario_2"]
var scenario_best_times: Dictionary = {} # scenario_id -> best time in seconds
var scenario_best_scores: Dictionary = {} # scenario_id -> best score

# Scenario metadata (dynamically loaded from scene files)
var scenario_metadata: Dictionary = {}

# Signals - Persistent progression
signal scenario_completed(scenario_id: String)
signal scenario_unlocked(scenario_id: String)
signal progression_saved()
signal progression_loaded()

# Signals - Runtime state
signal scenario_started(scenario_id: String)
signal wave_changed(scenario_id: String, wave: int)
signal scenario_ended(scenario_id: String)

func _ready():
  # Scan for scenario scenes and load metadata
  _scan_scenario_scenes()
  
  # Register with SaveManager
  SaveManager.register_system(self)
  
  Logger.info("ScenarioManager", "Scenario Manager initialized with %d scenarios" % scenario_metadata.size())

## Scan the Scenarios directory for scenario scene files and load their metadata
func _scan_scenario_scenes() -> void:
  var scenarios_dir = "res://Stages/Scenarios/"
  var dir = DirAccess.open(scenarios_dir)
  
  if not dir:
    Logger.error("ScenarioManager", "Failed to open Scenarios directory: %s" % scenarios_dir)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  
  while file_name != "":
    # Look for .tscn files that match the pattern scenario_*.tscn
    if file_name.ends_with(".tscn") and file_name.begins_with("scenario_") and file_name != "scenario.tscn":
      var scene_path = scenarios_dir + file_name
      var scenario_id = file_name.get_basename()  # e.g., "scenario_1"
      
      # Parse the scene file to extract metadata
      var metadata = _parse_scenario_metadata(scene_path, scenario_id)
      if not metadata.is_empty():
        scenario_metadata[scenario_id] = metadata
        Logger.debug("ScenarioManager", "Loaded scenario metadata: %s -> %s" % [scenario_id, metadata.get("name")])
      else:
        Logger.warn("ScenarioManager", "Failed to extract metadata from: %s" % scene_path)
    
    file_name = dir.get_next()
  
  dir.list_dir_end()
  Logger.info("ScenarioManager", "Scanned %d scenario scenes" % scenario_metadata.size())

## Parse a scenario scene file to extract metadata
func _parse_scenario_metadata(scene_path: String, scenario_id: String) -> Dictionary:
  var file = FileAccess.open(scene_path, FileAccess.READ)
  if not file:
    Logger.error("ScenarioManager", "Failed to open scene file: %s" % scene_path)
    return {}
  
  var metadata = {
    "name": scenario_id.capitalize().replace("_", " "),  # Default name
    "scene_path": scene_path,
    "description": "",
    "thumbnail": "",
  }
  
  # Parse the file line by line looking for metadata fields
  while not file.eof_reached():
    var line = file.get_line().strip_edges()
    
    # Look for exported metadata properties
    if line.begins_with("scenario_name = "):
      var value = line.substr(16).strip_edges().trim_prefix('"').trim_suffix('"')
      if not value.is_empty():
        metadata["name"] = value
    elif line.begins_with("scenario_description = "):
      var value = line.substr(23).strip_edges().trim_prefix('"').trim_suffix('"')
      metadata["description"] = value
    elif line.begins_with("scenario_thumbnail = "):
      var value = line.substr(21).strip_edges().trim_prefix('"').trim_suffix('"')
      metadata["thumbnail"] = value
  
  file.close()
  return metadata

## Runtime State Management

## Set the current scenario being played
func set_current_scenario_id(scenario_id: String) -> void:
  if current_scenario_id != scenario_id:
    current_scenario_id = scenario_id
    current_wave = 0 # Reset wave when changing scenarios
    scenario_started.emit(scenario_id)
    Logger.info("ScenarioManager", "Current scenario set to: %s" % scenario_id)

## Get the current scenario ID being played
func get_current_scenario_id() -> String:
  return current_scenario_id

## Clear the current scenario (e.g., when returning to menu)
func clear_current_scenario() -> void:
  if not current_scenario_id.is_empty():
    var old_scenario = current_scenario_id
    current_scenario_id = ""
    current_wave = 0
    scenario_ended.emit(old_scenario)
    Logger.info("ScenarioManager", "Cleared current scenario: %s" % old_scenario)

## Set the current wave number (within the current scenario)
func set_current_wave(wave: int) -> void:
  if current_wave != wave:
    current_wave = wave
    wave_changed.emit(current_scenario_id, wave)
    Logger.info("ScenarioManager", "Wave changed to %d in scenario %s" % [wave, current_scenario_id])

## Get the current wave number
func get_current_wave() -> int:
  return current_wave

## Persistent Progression Management

## Mark a scenario as completed
func mark_scenario_complete(scenario_id: String, time: float = 0.0, score: int = 0) -> void:
  if scenario_id not in completed_scenarios:
    completed_scenarios.append(scenario_id)
    scenario_completed.emit(scenario_id)
    Logger.info("ScenarioManager", "Scenario %s marked as complete" % scenario_id)
    
    # Check if we unlocked the next scenario
    var next_scenario = _get_next_scenario_id(scenario_id)
    if next_scenario and is_scenario_unlocked(next_scenario):
      scenario_unlocked.emit(next_scenario)
  
  # Update best time (if better or first time)
  if time > 0.0:
    if scenario_id not in scenario_best_times or time < scenario_best_times[scenario_id]:
      scenario_best_times[scenario_id] = time
      Logger.info("ScenarioManager", "New best time for %s: %.2f seconds" % [scenario_id, time])
  
  # Update best score (if better or first time)
  if score > 0:
    if scenario_id not in scenario_best_scores or score > scenario_best_scores[scenario_id]:
      scenario_best_scores[scenario_id] = score
      Logger.info("ScenarioManager", "New best score for %s: %d" % [scenario_id, score])

## Check if a scenario is unlocked
func is_scenario_unlocked(scenario_id: String) -> bool:
  # Scenario 1 always unlocked
  if scenario_id == "scenario_1":
    return true
  
  # Extract scenario number
  var scenario_num = int(scenario_id.replace("scenario_", ""))
  if scenario_num <= 1:
    return true
  
  # Check if previous scenario is completed
  var prev_scenario = "scenario_%d" % (scenario_num - 1)
  return completed_scenarios.has(prev_scenario)

## Check if a scenario is completed
func is_scenario_completed(scenario_id: String) -> bool:
  return completed_scenarios.has(scenario_id)

## Get best time for a scenario (0.0 if not played)
func get_best_time(scenario_id: String) -> float:
  return scenario_best_times.get(scenario_id, 0.0)

## Get best score for a scenario (0 if not played)
func get_best_score(scenario_id: String) -> int:
  return scenario_best_scores.get(scenario_id, 0)

## Get scenario metadata
func get_scenario_metadata(scenario_id: String) -> Dictionary:
  return scenario_metadata.get(scenario_id, {})

## Get all available scenario IDs
func get_all_scenario_ids() -> Array[String]:
  var ids: Array[String] = []
  for key in scenario_metadata.keys():
    ids.append(key)
  ids.sort()
  return ids

## Get the previous scenario requirement for unlocking
func get_unlock_requirement(scenario_id: String) -> String:
  var scenario_num = int(scenario_id.replace("scenario_", ""))
  if scenario_num <= 1:
    return "" # No requirement
  return "scenario_%d" % (scenario_num - 1)

## Helper to get next scenario ID
func _get_next_scenario_id(scenario_id: String) -> String:
  var scenario_num = int(scenario_id.replace("scenario_", ""))
  var next_scenario = "scenario_%d" % (scenario_num + 1)
  if next_scenario in scenario_metadata:
    return next_scenario
  return ""

## SaveableSystem Interface Implementation

## Get unique save key for this system
## Note: Kept as "level_progression" for backwards compatibility with existing save files
func get_save_key() -> String:
  return "level_progression"

## Get saveable state as dictionary
func get_save_data() -> Dictionary:
  return {
    "completed_scenarios": completed_scenarios,
    "scenario_best_times": scenario_best_times,
    "scenario_best_scores": scenario_best_scores,
  }

## Load data from saved state
func load_data(data: Dictionary) -> void:
  # Load the data with fallbacks
  var loaded_completed: Array = data.get("completed_scenarios", [])
  
  # Backwards compatibility: migrate from old "completed_levels" key
  if loaded_completed.is_empty() and data.has("completed_levels"):
    loaded_completed = data.get("completed_levels", [])
    Logger.info("ScenarioManager", "Migrating old save data from 'completed_levels' to 'completed_scenarios'")
  
  completed_scenarios.clear()
  for scenario in loaded_completed:
    if scenario is String:
      completed_scenarios.append(scenario)
  
  scenario_best_times = data.get("scenario_best_times", data.get("level_best_times", {}))
  scenario_best_scores = data.get("scenario_best_scores", data.get("level_best_scores", {}))
  
  Logger.info("ScenarioManager", "Scenario progression loaded - Completed: %s" % str(completed_scenarios))
  progression_loaded.emit()

## Reset to default state (for new game)
func reset_data() -> void:
  completed_scenarios.clear()
  scenario_best_times.clear()
  scenario_best_scores.clear()
  
  Logger.info("ScenarioManager", "Scenario progression reset")

## Legacy Methods (deprecated, kept for backward compatibility)

## Manual save method for external use (now delegates to SaveManager)
func save_progression_now() -> void:
  SaveManager.save_current_slot()

## Delete save file (delegates to SaveManager)
func delete_saved_progression() -> bool:
  if SaveManager.current_save_slot > 0:
    return SaveManager.delete_save_slot(SaveManager.current_save_slot)
  return true
