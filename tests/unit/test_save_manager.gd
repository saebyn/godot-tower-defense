extends GutTest

## Unit tests for SaveManager autoload
## Tests save slot management, atomic writes, and SaveableSystem interface

# Mock saveable system for testing
class MockSaveableSystem:
  var save_key: String
  var save_data: Dictionary
  var loaded_data: Dictionary
  var reset_called: bool = false
  
  func _init(key: String, data: Dictionary = {}):
    save_key = key
    save_data = data
    loaded_data = {}
  
  func get_save_key() -> String:
    return save_key
  
  func get_save_data() -> Dictionary:
    return save_data
  
  func load_data(data: Dictionary) -> void:
    loaded_data = data
  
  func reset_data() -> void:
    reset_called = true
    save_data = {}
    loaded_data = {}

# Test slot number
const TEST_SLOT = 1

func before_each():
  # Clean up any existing test save files
  _cleanup_test_saves()
  
  # Clear registered systems
  SaveManager.managed_systems.clear()
  SaveManager.current_save_slot = -1
  SaveManager.auto_save_timer = 0.0

func after_each():
  # Clean up test saves after each test
  _cleanup_test_saves()

func _cleanup_test_saves():
  # Delete test save slots
  for i in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
    var slot_path = SaveManager.SAVE_SLOT_PATH % i
    var backup_path = SaveManager.SAVE_SLOT_BACKUP_PATH % i
    
    if FileAccess.file_exists(slot_path):
      DirAccess.remove_absolute(slot_path)
    if FileAccess.file_exists(backup_path):
      DirAccess.remove_absolute(backup_path)

## Test: Register system with valid interface
func test_register_system_with_valid_interface():
  var mock_system = MockSaveableSystem.new("test_system")
  
  SaveManager.register_system(mock_system)
  
  assert_eq(SaveManager.managed_systems.size(), 1, "Should have 1 registered system")
  assert_eq(SaveManager.managed_systems[0], mock_system, "Should be the mock system")

## Test: Register multiple systems
func test_register_multiple_systems():
  var system1 = MockSaveableSystem.new("system1")
  var system2 = MockSaveableSystem.new("system2")
  
  SaveManager.register_system(system1)
  SaveManager.register_system(system2)
  
  assert_eq(SaveManager.managed_systems.size(), 2, "Should have 2 registered systems")

## Test: Create new game initializes slot
func test_create_new_game():
  var mock_system = MockSaveableSystem.new("test_system", {"value": 100})
  SaveManager.register_system(mock_system)
  
  SaveManager.create_new_game(TEST_SLOT)
  
  assert_eq(SaveManager.current_save_slot, TEST_SLOT, "Current slot should be set")
  assert_true(mock_system.reset_called, "System reset_data should be called")
  
  # Verify save file was created
  var slot_path = SaveManager.SAVE_SLOT_PATH % TEST_SLOT
  assert_true(FileAccess.file_exists(slot_path), "Save file should exist")

## Test: Save and load slot preserves data
func test_save_and_load_slot():
  var mock_system = MockSaveableSystem.new("test_system", {"value": 42, "name": "test"})
  SaveManager.register_system(mock_system)
  
  # Create and save
  SaveManager.create_new_game(TEST_SLOT)
  mock_system.save_data = {"value": 100, "name": "updated"}
  SaveManager.save_current_slot()
  
  # Reset system and load
  mock_system.save_data = {}
  mock_system.loaded_data = {}
  SaveManager.current_save_slot = -1
  
  var success = SaveManager.load_save_slot(TEST_SLOT)
  
  assert_true(success, "Load should succeed")
  assert_eq(SaveManager.current_save_slot, TEST_SLOT, "Current slot should be set")
  assert_eq(mock_system.loaded_data.get("value"), 100, "Loaded value should match saved")
  assert_eq(mock_system.loaded_data.get("name"), "updated", "Loaded name should match saved")

## Test: Load non-existent slot fails
func test_load_nonexistent_slot_fails():
  var success = SaveManager.load_save_slot(99)
  
  assert_false(success, "Loading non-existent slot should fail")

## Test: Get slot metadata for existing slot
func test_get_slot_metadata_existing_slot():
  var mock_system = MockSaveableSystem.new("test_system")
  SaveManager.register_system(mock_system)
  
  SaveManager.create_new_game(TEST_SLOT)
  
  var metadata = SaveManager.get_slot_metadata(TEST_SLOT)
  
  assert_true(metadata.get("exists"), "Slot should exist")
  assert_eq(metadata.get("slot_number"), TEST_SLOT, "Slot number should match")
  assert_true(metadata.has("timestamp"), "Should have timestamp")
  assert_true(metadata.has("playtime"), "Should have playtime")

## Test: Get slot metadata for non-existent slot
func test_get_slot_metadata_nonexistent_slot():
  var metadata = SaveManager.get_slot_metadata(99)
  
  assert_false(metadata.get("exists", false), "Slot should not exist")
  assert_eq(metadata.get("slot_number"), 99, "Slot number should match")

## Test: Delete save slot
func test_delete_save_slot():
  var mock_system = MockSaveableSystem.new("test_system")
  SaveManager.register_system(mock_system)
  
  # Create a save
  SaveManager.create_new_game(TEST_SLOT)
  var slot_path = SaveManager.SAVE_SLOT_PATH % TEST_SLOT
  assert_true(FileAccess.file_exists(slot_path), "Save file should exist before delete")
  
  # Delete it
  var success = SaveManager.delete_save_slot(TEST_SLOT)
  
  assert_true(success, "Delete should succeed")
  assert_false(FileAccess.file_exists(slot_path), "Save file should not exist after delete")

## Test: Get available slots
func test_get_available_slots():
  var mock_system = MockSaveableSystem.new("test_system")
  SaveManager.register_system(mock_system)
  
  # Create multiple slots
  SaveManager.create_new_game(1)
  SaveManager.create_new_game(3)
  SaveManager.create_new_game(5)
  
  var available = SaveManager.get_available_slots()
  
  assert_eq(available.size(), 3, "Should have 3 available slots")
  assert_true(available.has(1), "Should include slot 1")
  assert_true(available.has(3), "Should include slot 3")
  assert_true(available.has(5), "Should include slot 5")

## Test: Invalid slot numbers are rejected
func test_invalid_slot_numbers_rejected():
  assert_false(SaveManager.load_save_slot(0), "Slot 0 should be invalid")
  assert_false(SaveManager.load_save_slot(-1), "Negative slot should be invalid")
  assert_false(SaveManager.load_save_slot(SaveManager.MAX_SAVE_SLOTS + 1), "Slot beyond max should be invalid")

## Test: Save includes version field
func test_save_includes_version():
  var mock_system = MockSaveableSystem.new("test_system")
  SaveManager.register_system(mock_system)
  
  SaveManager.create_new_game(TEST_SLOT)
  
  # Load raw save file and check version
  var slot_path = SaveManager.SAVE_SLOT_PATH % TEST_SLOT
  var file = FileAccess.open(slot_path, FileAccess.READ)
  var json = JSON.new()
  json.parse(file.get_as_text())
  var data = json.get_data()
  file.close()
  
  assert_true(data.has("version"), "Save should include version field")
  assert_eq(data.get("version"), SaveManager.SAVE_VERSION, "Version should match SAVE_VERSION")

## Test: Save includes metadata
func test_save_includes_metadata():
  var mock_system = MockSaveableSystem.new("test_system")
  SaveManager.register_system(mock_system)
  
  SaveManager.create_new_game(TEST_SLOT)
  
  var metadata = SaveManager.get_slot_metadata(TEST_SLOT)
  
  assert_true(metadata.has("timestamp"), "Should have timestamp")
  assert_true(metadata.has("playtime"), "Should have playtime")
  assert_true(metadata.has("player_level"), "Should have player_level")
  assert_true(metadata.has("last_level"), "Should have last_level")

## Test: Multiple systems save independently
func test_multiple_systems_save_independently():
  var system1 = MockSaveableSystem.new("system1", {"value1": 100})
  var system2 = MockSaveableSystem.new("system2", {"value2": 200})
  
  SaveManager.register_system(system1)
  SaveManager.register_system(system2)
  
  SaveManager.create_new_game(TEST_SLOT)
  
  # Update values
  system1.save_data = {"value1": 150}
  system2.save_data = {"value2": 250}
  SaveManager.save_current_slot()
  
  # Reset and load
  system1.loaded_data = {}
  system2.loaded_data = {}
  SaveManager.current_save_slot = -1
  
  SaveManager.load_save_slot(TEST_SLOT)
  
  assert_eq(system1.loaded_data.get("value1"), 150, "System1 data should be restored")
  assert_eq(system2.loaded_data.get("value2"), 250, "System2 data should be restored")

## Test: Deleting current slot clears current_save_slot
func test_delete_current_slot_clears_current_save_slot():
  var mock_system = MockSaveableSystem.new("test_system")
  SaveManager.register_system(mock_system)
  
  SaveManager.create_new_game(TEST_SLOT)
  assert_eq(SaveManager.current_save_slot, TEST_SLOT, "Current slot should be set")
  
  SaveManager.delete_save_slot(TEST_SLOT)
  
  assert_eq(SaveManager.current_save_slot, -1, "Current slot should be cleared")

## Test: Save directory is created if missing
func test_save_directory_created():
  # Directory should exist after SaveManager initializes
  var dir = DirAccess.open("user://")
  assert_true(dir.dir_exists("saves"), "Save directory should exist")
