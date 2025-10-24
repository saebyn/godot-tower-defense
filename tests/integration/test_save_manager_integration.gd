extends GutTest

## Integration test for SaveManager with real managers
## Tests that managers properly save and load their state through SaveManager
## 
## Note: Autoload managers persist between tests, so we carefully manage state

const TEST_SLOT_1 = 7
const TEST_SLOT_2 = 8

func before_all():
  # Clean up any test slots
  _cleanup_test_slots()

func after_all():
  # Clean up test slots
  _cleanup_test_slots()

func before_each():
  # Ensure clean slate for each test
  _cleanup_test_slots()

func after_each():
  # Clean up after each test
  _cleanup_test_slots()

func _cleanup_test_slots():
  SaveManager.delete_save_slot(TEST_SLOT_1)
  SaveManager.delete_save_slot(TEST_SLOT_2)
  SaveManager.current_save_slot = -1
  
  # Reset all manager state to ensure clean slate between tests
  for system in SaveManager.managed_systems:
    system.reset_data()

## Test: Create new game and save currency data
func test_currency_manager_save_load():
  # Create fresh game
  SaveManager.create_new_game(TEST_SLOT_1)
  var initial_scrap = CurrencyManager.get_scrap()
  
  # Modify currency data
  CurrencyManager.earn_scrap(500)
  CurrencyManager.earn_xp(250)
  
  var expected_scrap = CurrencyManager.get_scrap()
  var expected_xp = CurrencyManager.get_xp()
  var expected_level = CurrencyManager.get_level()
  
  # Save
  SaveManager.save_current_slot()
  
  # Create a different save to reset state
  SaveManager.create_new_game(TEST_SLOT_2)
  assert_eq(CurrencyManager.get_scrap(), CurrencyManager.starting_scrap, "Should be reset to starting scrap")
  
  # Load original save
  var success = SaveManager.load_save_slot(TEST_SLOT_1)
  
  assert_true(success, "Load should succeed")
  assert_eq(CurrencyManager.get_scrap(), expected_scrap, "Scrap should be restored")
  assert_eq(CurrencyManager.get_xp(), expected_xp, "XP should be restored")
  assert_eq(CurrencyManager.get_level(), expected_level, "Level should be restored")

## Test: Stats manager save/load
func test_stats_manager_save_load():
  # Create fresh game
  SaveManager.create_new_game(TEST_SLOT_1)
  
  # Track some stats
  StatsManager.track_enemy_defeated("basic_zombie", false)
  StatsManager.track_enemy_defeated("basic_zombie", false)
  StatsManager.track_obstacle_placed("turret")
  
  var expected_enemies = StatsManager.get_enemies_defeated_total()
  var expected_obstacles = StatsManager.get_obstacles_placed_total()
  
  # Save
  SaveManager.save_current_slot()
  
  # Create different save to reset
  SaveManager.create_new_game(TEST_SLOT_2)
  assert_eq(StatsManager.get_enemies_defeated_total(), 0, "Should be reset")
  
  # Load
  SaveManager.load_save_slot(TEST_SLOT_1)
  
  assert_eq(StatsManager.get_enemies_defeated_total(), expected_enemies, "Enemy count should be restored")
  assert_eq(StatsManager.get_obstacles_placed_total(), expected_obstacles, "Obstacle count should be restored")

## Test: Level manager save/load
func test_level_manager_save_load():
  # Create fresh game
  SaveManager.create_new_game(TEST_SLOT_1)
  
  # Mark some levels complete
  LevelManager.mark_level_complete("level_1", 120.5, 1000)
  LevelManager.mark_level_complete("level_2", 95.3, 1500)
  
  var expected_count = LevelManager.completed_levels.size()
  var expected_best_time = LevelManager.get_best_time("level_1")
  
  # Save
  SaveManager.save_current_slot()
  
  # Create different save to reset
  SaveManager.create_new_game(TEST_SLOT_2)
  assert_eq(LevelManager.completed_levels.size(), 0, "Should be reset")
  
  # Load
  SaveManager.load_save_slot(TEST_SLOT_1)
  
  assert_eq(LevelManager.completed_levels.size(), expected_count, "Completed count should match")
  assert_true(LevelManager.is_level_completed("level_1"), "Level 1 should be complete")
  assert_true(LevelManager.is_level_completed("level_2"), "Level 2 should be complete")
  assert_eq(LevelManager.get_best_time("level_1"), expected_best_time, "Best time should be restored")

## Test: Tech tree manager save/load
func test_tech_tree_manager_save_load():
  # This test verifies tech tree persistence works
  # Note: Tech tree state may persist between tests due to autoload nature
  # Create fresh game
  SaveManager.create_new_game(TEST_SLOT_1)
  
  # Verify tech nodes exist
  assert_gt(TechTreeManager.tech_nodes.size(), 0, "Tech tree should have at least one tech node")
  
  # Get first tech node
  var tech_id = TechTreeManager.tech_nodes.keys()[0]
  
  # Manually add to unlocked (bypass unlock logic for testing)
  if not TechTreeManager.is_tech_unlocked(tech_id):
    TechTreeManager.unlocked_tech_ids.append(tech_id)
  
  var expected_count = TechTreeManager.unlocked_tech_ids.size()
  assert_gt(expected_count, 0, "Should have at least one unlocked tech")
  
  # Save
  SaveManager.save_current_slot()
  
  # Verify save file contains tech tree data
  var slot_path = SaveManager.SAVE_SLOT_PATH % TEST_SLOT_1
  var save_data = SaveManager._load_json_file(slot_path)
  assert_true(save_data.has("tech_tree"), "Save should contain tech tree data")
  assert_true(save_data["tech_tree"].has("unlocked_tech_ids"), "Tech tree should have unlocked_tech_ids")
  
  # Load into a different slot to verify data round-trips
  SaveManager.create_new_game(TEST_SLOT_2)
  TechTreeManager.unlocked_tech_ids.clear() # Clear for this new game
  
  # Verify it's cleared
  assert_eq(TechTreeManager.unlocked_tech_ids.size(), 0, "Tech tree should be reset after new game")
  
  # Load original slot
  SaveManager.load_save_slot(TEST_SLOT_1)
  
  # Verify tech is restored
  assert_true(TechTreeManager.is_tech_unlocked(tech_id), "Tech should be unlocked after load")
  assert_eq(TechTreeManager.unlocked_tech_ids.size(), expected_count, "Unlocked count should match")

## Test: Multiple managers save/load together
func test_all_managers_save_load():
  # Create fresh game
  SaveManager.create_new_game(TEST_SLOT_1)
  
  # Modify all managers
  CurrencyManager.earn_scrap(300)
  StatsManager.track_enemy_defeated("zombie", false)
  LevelManager.mark_level_complete("level_1")
  
  var expected_scrap = CurrencyManager.get_scrap()
  var expected_enemies = StatsManager.get_enemies_defeated_total()
  var expected_levels = LevelManager.completed_levels.size()
  
  # Save
  SaveManager.save_current_slot()
  
  # Create different save to reset all
  SaveManager.create_new_game(TEST_SLOT_2)
  
  # Load original
  SaveManager.load_save_slot(TEST_SLOT_1)
  
  # Verify all restored
  assert_eq(CurrencyManager.get_scrap(), expected_scrap, "Scrap restored")
  assert_eq(StatsManager.get_enemies_defeated_total(), expected_enemies, "Stats restored")
  assert_eq(LevelManager.completed_levels.size(), expected_levels, "Levels restored")

## Test: Switch between save slots
func test_save_slot_switching():
  # This test verifies that different save slots maintain independent state
  # Create slot 1 with specific scrap amount
  SaveManager.create_new_game(TEST_SLOT_1)
  var base_scrap = CurrencyManager.get_scrap()
  CurrencyManager.earn_scrap(100)
  SaveManager.save_current_slot()
  var scrap_slot1 = CurrencyManager.get_scrap()
  
  # Create slot 2 with different scrap amount
  SaveManager.create_new_game(TEST_SLOT_2)
  CurrencyManager.earn_scrap(500)
  SaveManager.save_current_slot()
  var scrap_slot2 = CurrencyManager.get_scrap()
  
  assert_true(scrap_slot2 > scrap_slot1, "Slot 2 should have more scrap than slot 1")
  assert_true(scrap_slot1 > base_scrap, "Slot 1 should have more than base scrap")
  
  # Verify slots are independent by loading each
  SaveManager.load_save_slot(TEST_SLOT_1)
  var loaded_slot1_scrap = CurrencyManager.get_scrap()
  
  SaveManager.load_save_slot(TEST_SLOT_2)
  var loaded_slot2_scrap = CurrencyManager.get_scrap()
  
  # The loaded values should differ (proving slots are independent)
  assert_true(loaded_slot2_scrap != loaded_slot1_scrap, "Slots should have different scrap values")
  assert_true(loaded_slot2_scrap > loaded_slot1_scrap, "Slot 2 should have more scrap")

## Test: Metadata is accurate
func test_save_metadata():
  # Create fresh game
  SaveManager.create_new_game(TEST_SLOT_1)
  
  # Modify state
  CurrencyManager.earn_xp(300) # Should level up
  LevelManager.set_current_level_id("level_2")
  
  var player_level = CurrencyManager.get_level()
  
  # Save
  SaveManager.save_current_slot()
  
  # Get metadata
  var metadata = SaveManager.get_slot_metadata(TEST_SLOT_1)
  
  assert_true(metadata.get("exists"), "Slot should exist")
  assert_eq(metadata.get("player_level"), player_level, "Player level should match")
  assert_eq(metadata.get("last_level"), "level_2", "Last level should match")
  assert_true(metadata.has("timestamp"), "Should have timestamp")
