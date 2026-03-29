extends GutTest

## Unit tests for TechTreeManager autoload
## Tests tech tree loading, unlock validation, mutual exclusivity, and branch completion

func before_each():
  # Reset the TechTreeManager state before each test
  TechTreeManager.reset_tech_tree()
  
  # Reset CurrencyManager to known state
  CurrencyManager.current_scrap = 100
  CurrencyManager.current_xp = 0
  CurrencyManager.current_level = 1
  
  # Ensure debug mode is off by default
  SettingsManager.debug_mode = false

func after_each():
  # Always restore debug mode to off after each test
  SettingsManager.debug_mode = false
  
  # Restore CurrencyManager to clean state
  CurrencyManager.current_scrap = 100
  CurrencyManager.current_xp = 0
  CurrencyManager.current_level = 1

func test_tech_tree_loads_tech_nodes():
  # Assert - verify that tech nodes were loaded from Config/TechTree/
  assert_gt(TechTreeManager.tech_nodes.size(), 0, "Should load at least one tech node")

func test_can_unlock_tech_with_valid_level():
  # Arrange
  CurrencyManager.current_level = 1
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_scrap_shooter")
  
  # Assert
  assert_true(can_unlock, "Should be able to unlock starter tech at level 1")

func test_cannot_unlock_tech_with_insufficient_level():
  # Arrange
  CurrencyManager.current_level = 1
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_molotov_mortar")
  
  # Assert
  assert_false(can_unlock, "Should not be able to unlock tech requiring level 4")

func test_cannot_unlock_tech_without_prerequisites():
  # Arrange
  CurrencyManager.current_level = 2
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_boom_barrel")
  
  # Assert
  assert_false(can_unlock, "Should not be able to unlock tech without prerequisite")

func test_can_unlock_tech_with_prerequisites():
  # Arrange
  CurrencyManager.current_level = 2
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_boom_barrel")
  
  # Assert
  assert_true(can_unlock, "Should be able to unlock tech with prerequisite satisfied")

func test_unlock_tech_adds_to_unlocked_list():
  # Arrange
  CurrencyManager.current_level = 1
  
  # Act
  var result = TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Assert
  assert_true(result, "Should return true when unlocking")
  assert_true(TechTreeManager.is_tech_unlocked("tur_scrap_shooter"), "Tech should be in unlocked list")

func test_unlock_tech_emits_signal():
  # Arrange
  CurrencyManager.current_level = 1
  watch_signals(TechTreeManager)
  
  # Act
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Assert
  assert_signal_emitted(TechTreeManager, "tech_unlocked")
  assert_signal_emitted_with_parameters(TechTreeManager, "tech_unlocked", ["tur_scrap_shooter"])

func test_cannot_unlock_already_unlocked_tech():
  # Arrange
  CurrencyManager.current_level = 1
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_scrap_shooter")
  
  # Assert
  assert_false(can_unlock, "Should not be able to unlock already unlocked tech")

func test_mutual_exclusivity_locks_alternative_tech():
  # Arrange
  CurrencyManager.current_level = 2
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Act
  TechTreeManager.unlock_tech("tur_boom_barrel")
  
  # Assert
  assert_true(TechTreeManager.is_tech_locked("tur_molotov_mortar"), "Mutually exclusive tech should be locked")

func test_mutual_exclusivity_emits_locked_signal():
  # Arrange
  CurrencyManager.current_level = 2
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  watch_signals(TechTreeManager)
  
  # Act
  TechTreeManager.unlock_tech("tur_boom_barrel")
  
  # Assert
  assert_signal_emitted(TechTreeManager, "tech_locked")
  assert_signal_emitted_with_parameters(TechTreeManager, "tech_locked", ["tur_molotov_mortar"])

func test_cannot_unlock_permanently_locked_tech():
  # Arrange
  CurrencyManager.current_level = 4
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  TechTreeManager.unlock_tech("tur_boom_barrel")
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_molotov_mortar")
  
  # Assert
  assert_false(can_unlock, "Should not be able to unlock permanently locked tech")

func test_get_tech_node_returns_valid_resource():
  # Act
  var tech = TechTreeManager.get_tech_node("tur_scrap_shooter")
  
  # Assert
  assert_not_null(tech, "Should return a tech node resource")
  assert_eq(tech.id, "tur_scrap_shooter", "Should return correct tech node")
  assert_eq(tech.display_name, "Scrap Shooter", "Should have correct display name")

func test_get_techs_in_branch_returns_branch_techs():
  # Act
  var offensive_techs = TechTreeManager.get_techs_in_branch("Offensive")
  
  # Assert
  assert_gt(offensive_techs.size(), 0, "Should return at least one offensive tech")
  for tech in offensive_techs:
    assert_eq(tech.branch_name, "Offensive", "All returned techs should be in Offensive branch")

func test_is_branch_completed_returns_false_initially():
  # Act
  var completed = TechTreeManager.is_branch_completed("Offensive")
  
  # Assert
  assert_false(completed, "Branch should not be completed initially")

func test_get_unlocked_building_ids_returns_buildings():
  # Arrange
  CurrencyManager.current_level = 1
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Act
  var building_ids = TechTreeManager.get_unlocked_building_ids()
  
  # Assert
  assert_has(building_ids, "turret", "Should include building from unlocked tech")

func test_get_unlocked_building_ids_accumulates_from_multiple_techs():
  # Arrange
  CurrencyManager.current_level = 1
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  TechTreeManager.unlock_tech("ob_crates")
  
  # Act
  var building_ids = TechTreeManager.get_unlocked_building_ids()
  
  # Assert
  assert_has(building_ids, "turret", "Should include turret from first tech")
  assert_has(building_ids, "wall", "Should include wall from second tech")

func test_reset_tech_tree_clears_unlocked_techs():
  # Arrange
  CurrencyManager.current_level = 1
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Act
  TechTreeManager.reset_tech_tree()
  
  # Assert
  assert_false(TechTreeManager.is_tech_unlocked("tur_scrap_shooter"), "Tech should not be unlocked after reset")
  assert_eq(TechTreeManager.unlocked_tech_ids.size(), 0, "Unlocked tech list should be empty")

func test_reset_tech_tree_clears_locked_techs():
  # Arrange
  CurrencyManager.current_level = 2
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  TechTreeManager.unlock_tech("tur_boom_barrel")
  
  # Act
  TechTreeManager.reset_tech_tree()
  
  # Assert
  assert_false(TechTreeManager.is_tech_locked("tur_molotov_mortar"), "Tech should not be locked after reset")
  assert_eq(TechTreeManager.locked_tech_ids.size(), 0, "Locked tech list should be empty")

## Debug mode tests

func test_debug_mode_bypasses_level_requirement():
  # Arrange - tech requires level 4, player is level 1
  CurrencyManager.current_level = 1
  SettingsManager.debug_mode = true
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_molotov_mortar")
  
  # Assert
  assert_true(can_unlock, "Debug mode should bypass level requirement")

func test_debug_mode_bypasses_prerequisite_requirement():
  # Arrange - tech requires prerequisite tur_scrap_shooter (not unlocked)
  CurrencyManager.current_level = 2
  SettingsManager.debug_mode = true
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_boom_barrel")
  
  # Assert
  assert_true(can_unlock, "Debug mode should bypass prerequisite requirement")

func test_debug_mode_bypasses_scrap_cost():
  # Arrange - no scrap, tech has scrap cost
  CurrencyManager.current_scrap = 0
  CurrencyManager.current_level = 1
  SettingsManager.debug_mode = true
  
  # Act - use a tech that has scrap_cost > 0 if any; otherwise unlock a normal tech
  var can_unlock = TechTreeManager.can_unlock_tech("tur_scrap_shooter")
  
  # Assert
  assert_true(can_unlock, "Debug mode should allow unlock regardless of scrap balance")

func test_debug_mode_does_not_spend_scrap_on_unlock():
  # Arrange
  CurrencyManager.current_scrap = 50
  CurrencyManager.current_level = 1
  SettingsManager.debug_mode = true
  var scrap_before = CurrencyManager.get_scrap()
  
  # Act
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Assert
  assert_eq(CurrencyManager.get_scrap(), scrap_before, "Debug mode should not spend scrap on unlock")

func test_debug_mode_still_blocks_already_unlocked_tech():
  # Arrange
  CurrencyManager.current_level = 1
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  SettingsManager.debug_mode = true
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_scrap_shooter")
  
  # Assert
  assert_false(can_unlock, "Debug mode should not allow re-unlocking an already unlocked tech")

func test_debug_mode_still_blocks_permanently_locked_tech():
  # Arrange
  CurrencyManager.current_level = 2
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  TechTreeManager.unlock_tech("tur_boom_barrel")  # locks tur_molotov_mortar
  SettingsManager.debug_mode = true
  
  # Act
  var can_unlock = TechTreeManager.can_unlock_tech("tur_molotov_mortar")
  
  # Assert
  assert_false(can_unlock, "Debug mode should not bypass permanent mutual-exclusivity lock")

## list_unlocked_techs tests

func test_list_unlocked_techs_returns_empty_initially():
  # Act
  var unlocked = TechTreeManager.list_unlocked_techs()
  
  # Assert
  assert_eq(unlocked.size(), 0, "Should return empty array when no techs are unlocked")

func test_list_unlocked_techs_returns_unlocked_tech_ids():
  # Arrange
  CurrencyManager.current_level = 1
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Act
  var unlocked = TechTreeManager.list_unlocked_techs()
  
  # Assert
  assert_has(unlocked, "tur_scrap_shooter", "Should include the unlocked tech ID")
  assert_eq(unlocked.size(), 1, "Should return exactly one tech ID")

func test_list_unlocked_techs_returns_duplicate_not_internal_array():
  # Arrange
  CurrencyManager.current_level = 1
  TechTreeManager.unlock_tech("tur_scrap_shooter")
  
  # Act - mutate the returned array
  var unlocked = TechTreeManager.list_unlocked_techs()
  unlocked.clear()
  
  # Assert - internal state should be unchanged; call list_unlocked_techs() again to verify
  var unlocked_again = TechTreeManager.list_unlocked_techs()
  assert_eq(unlocked_again.size(), 1, "Clearing returned array should not affect internal state")
  assert_has(unlocked_again, "tur_scrap_shooter", "Internal state should still contain the unlocked tech")
