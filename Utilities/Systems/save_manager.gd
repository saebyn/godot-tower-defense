extends Node

## SaveManager - Centralized save system with multi-slot support
##
## Orchestrates all game persistence, replacing decentralized save/load in individual managers.
## Provides atomic saves, multi-slot support, and separation between per-slot and global data.
##
## Usage:
##   # In manager _ready():
##   SaveManager.register_system(self)
##   
##   # Implement SaveableSystem interface:
##   func get_save_key() -> String:
##     return "player_progression"
##   
##   func get_save_data() -> Dictionary:
##     return {"current_level": current_level}
##   
##   func load_data(data: Dictionary) -> void:
##     current_level = data.get("current_level", 1)
##   
##   func reset_data() -> void:
##     current_level = 1

# Save slot configuration
const MAX_SAVE_SLOTS = 10  # Expandable, minimum 3
const SAVE_SLOT_DIR = "user://saves/"
const SAVE_SLOT_PATH = "user://saves/save_slot_%d.save"
const SAVE_SLOT_BACKUP_PATH = "user://saves/save_slot_%d.save.bak"
const GLOBAL_SAVE_PATH = "user://global.save"
const GLOBAL_SAVE_BACKUP_PATH = "user://global.save.bak"
const SAVE_VERSION = 1

# Auto-save configuration
const AUTO_SAVE_INTERVAL = 300.0  # 5 minutes in seconds
var auto_save_timer: float = 0.0

# Current state
var current_save_slot: int = -1  # -1 = no slot loaded
var managed_systems: Array = []  # Array of objects implementing SaveableSystem interface

# Signals
signal save_started()
signal save_completed()
signal save_failed(error: String)
signal load_started()
signal load_completed()
signal load_failed(error: String)
signal slot_created(slot_number: int)
signal slot_deleted(slot_number: int)

func _ready() -> void:
  # Ensure save directory exists
  _ensure_save_directory()
  Logger.info("SaveManager", "Save Manager initialized - Max slots: %d" % MAX_SAVE_SLOTS)

func _process(delta: float) -> void:
  # Auto-save timer (only when a slot is loaded)
  if current_save_slot > 0:
    auto_save_timer += delta
    if auto_save_timer >= AUTO_SAVE_INTERVAL:
      auto_save_timer = 0.0
      Logger.debug("SaveManager", "Auto-save triggered")
      save_current_slot()

## Register a system that implements the SaveableSystem interface
## Required interface methods:
##   - get_save_key() -> String
##   - get_save_data() -> Dictionary
##   - load_data(data: Dictionary) -> void
##   - reset_data() -> void
func register_system(system) -> void:
  if not _validate_saveable_system(system):
    Logger.error("SaveManager", "System does not implement SaveableSystem interface: %s" % str(system))
    return
  
  managed_systems.append(system)
  Logger.info("SaveManager", "Registered saveable system: %s" % system.get_save_key())

## Validate that a system implements the SaveableSystem interface
func _validate_saveable_system(system) -> bool:
  return system.has_method("get_save_key") and \
         system.has_method("get_save_data") and \
         system.has_method("load_data") and \
         system.has_method("reset_data")

## Load a specific save slot
## Returns true if successful, false otherwise
func load_save_slot(slot_number: int) -> bool:
  if slot_number < 1 or slot_number > MAX_SAVE_SLOTS:
    Logger.error("SaveManager", "Invalid slot number: %d (must be 1-%d)" % [slot_number, MAX_SAVE_SLOTS])
    load_failed.emit("Invalid slot number")
    return false
  
  load_started.emit()
  
  var slot_path = SAVE_SLOT_PATH % slot_number
  
  # Check if slot exists
  if not FileAccess.file_exists(slot_path):
    Logger.warn("SaveManager", "Save slot %d does not exist" % slot_number)
    load_failed.emit("Save slot does not exist")
    return false
  
  # Try to load the slot
  var save_data = _load_json_file(slot_path)
  if save_data == null:
    # Try backup
    Logger.warn("SaveManager", "Primary save corrupted, attempting backup restore")
    var backup_path = SAVE_SLOT_BACKUP_PATH % slot_number
    save_data = _load_json_file(backup_path)
    
    if save_data == null:
      Logger.error("SaveManager", "Failed to load slot %d (both primary and backup corrupted)" % slot_number)
      load_failed.emit("Save file corrupted")
      return false
  
  # Validate save data structure
  if not _validate_save_data(save_data):
    Logger.error("SaveManager", "Invalid save data structure in slot %d" % slot_number)
    load_failed.emit("Invalid save data")
    return false
  
  # Load data into each managed system
  for system in managed_systems:
    var save_key = system.get_save_key()
    var system_data = save_data.get(save_key, {})
    
    if system_data is Dictionary:
      system.load_data(system_data)
      Logger.debug("SaveManager", "Loaded data for system: %s" % save_key)
    else:
      Logger.warn("SaveManager", "No data found for system: %s" % save_key)
  
  # Update current slot
  current_save_slot = slot_number
  auto_save_timer = 0.0  # Reset auto-save timer
  
  Logger.info("SaveManager", "Successfully loaded save slot %d" % slot_number)
  load_completed.emit()
  return true

## Save the current slot atomically
## Uses temporary file + rename to ensure atomic writes
func save_current_slot() -> void:
  if current_save_slot < 1 or current_save_slot > MAX_SAVE_SLOTS:
    Logger.error("SaveManager", "No valid save slot loaded (current: %d)" % current_save_slot)
    save_failed.emit("No valid save slot loaded")
    return
  
  save_started.emit()
  
  # Collect data from all registered systems
  var save_data = {
    "version": SAVE_VERSION,
    "metadata": _generate_slot_metadata()
  }
  
  for system in managed_systems:
    var save_key = system.get_save_key()
    var system_data = system.get_save_data()
    
    if system_data is Dictionary:
      save_data[save_key] = system_data
      Logger.debug("SaveManager", "Collected data from system: %s" % save_key)
    else:
      Logger.warn("SaveManager", "System returned invalid data: %s" % save_key)
  
  # Write to slot
  var slot_path = SAVE_SLOT_PATH % current_save_slot
  var backup_path = SAVE_SLOT_BACKUP_PATH % current_save_slot
  
  if _save_json_file_atomic(slot_path, backup_path, save_data):
    Logger.info("SaveManager", "Successfully saved slot %d" % current_save_slot)
    save_completed.emit()
  else:
    Logger.error("SaveManager", "Failed to save slot %d" % current_save_slot)
    save_failed.emit("File write failed")

## Create a new game in the specified slot
## Resets all per-slot data, keeps global data
func create_new_game(slot_number: int) -> void:
  if slot_number < 1 or slot_number > MAX_SAVE_SLOTS:
    Logger.error("SaveManager", "Invalid slot number: %d" % slot_number)
    return
  
  Logger.info("SaveManager", "Creating new game in slot %d" % slot_number)
  
  # Reset all managed systems to default state
  for system in managed_systems:
    system.reset_data()
    Logger.debug("SaveManager", "Reset system: %s" % system.get_save_key())
  
  # Set current slot
  current_save_slot = slot_number
  auto_save_timer = 0.0
  
  # Save the fresh state
  save_current_slot()
  
  slot_created.emit(slot_number)
  Logger.info("SaveManager", "New game created in slot %d" % slot_number)

## Get metadata for a specific save slot
## Returns dictionary with slot info or empty dict if slot doesn't exist
func get_slot_metadata(slot_number: int) -> Dictionary:
  if slot_number < 1 or slot_number > MAX_SAVE_SLOTS:
    return {"exists": false, "slot_number": slot_number}
  
  var slot_path = SAVE_SLOT_PATH % slot_number
  
  if not FileAccess.file_exists(slot_path):
    return {"exists": false, "slot_number": slot_number}
  
  var save_data = _load_json_file(slot_path)
  if save_data == null or not save_data is Dictionary:
    return {"exists": false, "slot_number": slot_number, "corrupted": true}
  
  var metadata = save_data.get("metadata", {})
  metadata["exists"] = true
  metadata["slot_number"] = slot_number
  
  return metadata

## Delete a save slot
## Returns true if successful or slot didn't exist, false on error
func delete_save_slot(slot_number: int) -> bool:
  if slot_number < 1 or slot_number > MAX_SAVE_SLOTS:
    Logger.error("SaveManager", "Invalid slot number: %d" % slot_number)
    return false
  
  var slot_path = SAVE_SLOT_PATH % slot_number
  var backup_path = SAVE_SLOT_BACKUP_PATH % slot_number
  
  # If current slot is being deleted, unload it
  if current_save_slot == slot_number:
    current_save_slot = -1
    auto_save_timer = 0.0
  
  var dir = DirAccess.open("user://saves/")
  if not dir:
    Logger.error("SaveManager", "Could not access save directory")
    return false
  
  var success = true
  
  # Delete primary save
  if FileAccess.file_exists(slot_path):
    var filename = "save_slot_%d.save" % slot_number
    if dir.remove(filename) != OK:
      Logger.error("SaveManager", "Failed to delete save file: %s" % filename)
      success = false
    else:
      Logger.debug("SaveManager", "Deleted save file: %s" % filename)
  
  # Delete backup
  if FileAccess.file_exists(backup_path):
    var backup_filename = "save_slot_%d.save.bak" % slot_number
    if dir.remove(backup_filename) != OK:
      Logger.warn("SaveManager", "Failed to delete backup file: %s" % backup_filename)
    else:
      Logger.debug("SaveManager", "Deleted backup file: %s" % backup_filename)
  
  if success:
    Logger.info("SaveManager", "Deleted save slot %d" % slot_number)
    slot_deleted.emit(slot_number)
  
  return success

## Get list of all slot numbers that have save data
func get_available_slots() -> Array[int]:
  var slots: Array[int] = []
  
  for i in range(1, MAX_SAVE_SLOTS + 1):
    var slot_path = SAVE_SLOT_PATH % i
    if FileAccess.file_exists(slot_path):
      slots.append(i)
  
  return slots

## Save global settings data (persists across all save slots)
func save_global_data() -> void:
  save_started.emit()
  
  # Collect global data (currently just settings)
  var global_data = {
    "version": SAVE_VERSION,
  }
  
  # Add data from systems marked as global (SettingsManager would go here)
  # For now, we'll let SettingsManager handle its own persistence
  # This is a placeholder for future global data expansion
  
  if _save_json_file_atomic(GLOBAL_SAVE_PATH, GLOBAL_SAVE_BACKUP_PATH, global_data):
    Logger.info("SaveManager", "Successfully saved global data")
    save_completed.emit()
  else:
    Logger.error("SaveManager", "Failed to save global data")
    save_failed.emit("Global data write failed")

## Load global settings data
func load_global_data() -> bool:
  load_started.emit()
  
  if not FileAccess.file_exists(GLOBAL_SAVE_PATH):
    Logger.info("SaveManager", "No global save file found")
    load_failed.emit("No global save file")
    return false
  
  var global_data = _load_json_file(GLOBAL_SAVE_PATH)
  if global_data == null:
    # Try backup
    global_data = _load_json_file(GLOBAL_SAVE_BACKUP_PATH)
    if global_data == null:
      Logger.error("SaveManager", "Failed to load global data")
      load_failed.emit("Global data corrupted")
      return false
  
  Logger.info("SaveManager", "Successfully loaded global data")
  load_completed.emit()
  return true

## Manual quick-save (triggered by F5 or similar)
func quick_save() -> void:
  if current_save_slot > 0:
    Logger.info("SaveManager", "Quick save triggered")
    save_current_slot()
  else:
    Logger.warn("SaveManager", "Quick save failed: no slot loaded")

## Helper: Generate metadata for current game state
func _generate_slot_metadata() -> Dictionary:
  var metadata = {
    "timestamp": Time.get_unix_time_from_system(),
    "playtime": 0.0,  # TODO: Track playtime
    "player_level": 1,
    "last_level": "",
    "slot_name": ""  # Optional user-customizable name
  }
  
  # Try to get player level from CurrencyManager
  if CurrencyManager:
    metadata["player_level"] = CurrencyManager.get_level()
  
  # Try to get last level from LevelManager
  if LevelManager:
    metadata["last_level"] = LevelManager.get_current_level_id()
  
  return metadata

## Helper: Ensure save directory exists
func _ensure_save_directory() -> void:
  var dir = DirAccess.open("user://")
  if dir:
    if not dir.dir_exists("saves"):
      dir.make_dir("saves")
      Logger.info("SaveManager", "Created save directory: user://saves/")

## Helper: Validate save data structure
func _validate_save_data(data) -> bool:
  if not data is Dictionary:
    return false
  
  if not data.has("version"):
    return false
  
  return true

## Helper: Load JSON file
## Returns parsed Dictionary or null on error
func _load_json_file(path: String):
  if not FileAccess.file_exists(path):
    return null
  
  var file = FileAccess.open(path, FileAccess.READ)
  if not file:
    Logger.error("SaveManager", "Could not open file for reading: %s" % path)
    return null
  
  var json_string = file.get_as_text()
  file.close()
  
  var json = JSON.new()
  var parse_result = json.parse(json_string)
  
  if parse_result != OK:
    Logger.error("SaveManager", "Error parsing JSON from %s: %s" % [path, json.get_error_message()])
    return null
  
  return json.get_data()

## Helper: Save JSON file atomically with backup
## Writes to temp file first, then renames. Keeps backup of previous save.
## Returns true on success, false on failure
func _save_json_file_atomic(primary_path: String, backup_path: String, data: Dictionary) -> bool:
  var temp_path = primary_path + ".tmp"
  
  # Write to temporary file
  var file = FileAccess.open(temp_path, FileAccess.WRITE)
  if not file:
    Logger.error("SaveManager", "Could not open temp file for writing: %s" % temp_path)
    return false
  
  var json_string = JSON.stringify(data, "  ")  # Pretty print with 2-space indent
  file.store_string(json_string)
  file.close()
  
  # Create backup of existing save
  if FileAccess.file_exists(primary_path):
    var dir = DirAccess.open("user://saves/")
    if dir:
      # Extract just the filename
      var primary_filename = primary_path.get_file()
      var backup_filename = backup_path.get_file()
      
      # Copy primary to backup
      if dir.copy(primary_filename, backup_filename) != OK:
        Logger.warn("SaveManager", "Failed to create backup: %s" % backup_path)
  
  # Rename temp file to primary (atomic operation)
  var dir = DirAccess.open("user://saves/")
  if not dir:
    Logger.error("SaveManager", "Could not access save directory")
    return false
  
  var temp_filename = temp_path.get_file()
  var primary_filename = primary_path.get_file()
  
  if dir.rename(temp_filename, primary_filename) != OK:
    Logger.error("SaveManager", "Failed to rename temp file to primary: %s -> %s" % [temp_filename, primary_filename])
    return false
  
  return true
