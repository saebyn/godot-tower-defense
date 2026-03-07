extends GutTest

## Unit tests for SurvivorNameManager autoload

func before_each():
  SurvivorNameManager.reset_data()

func after_each():
  SurvivorNameManager.reset_data()

# --- assign_name ---

func test_assign_name_returns_non_empty_string():
  var name = SurvivorNameManager.assign_name()
  assert_ne(name, "", "Assigned name should not be empty")

func test_assign_name_returns_name_from_pool():
  var name = SurvivorNameManager.assign_name()
  assert_true(SurvivorNameManager.NAME_POOL.has(name), "Assigned name should come from the name pool")

func test_assign_name_adds_to_used_names():
  var name = SurvivorNameManager.assign_name()
  assert_true(SurvivorNameManager.used_names.has(name), "Assigned name should appear in used_names")

func test_assigned_names_are_unique():
  var first = SurvivorNameManager.assign_name()
  var second = SurvivorNameManager.assign_name()
  assert_ne(first, "", "First name should not be empty")
  assert_ne(second, "", "Second name should not be empty")
  assert_ne(first, second, "Two assigned names should not be the same")

func test_used_names_count_increases_with_each_assignment():
  assert_eq(SurvivorNameManager.used_names.size(), 0, "Should start with 0 used names")
  SurvivorNameManager.assign_name()
  assert_eq(SurvivorNameManager.used_names.size(), 1, "Should have 1 used name after one assignment")
  SurvivorNameManager.assign_name()
  assert_eq(SurvivorNameManager.used_names.size(), 2, "Should have 2 used names after two assignments")

func test_get_available_count_decreases_with_each_assignment():
  var initial_count = SurvivorNameManager.get_available_count()
  SurvivorNameManager.assign_name()
  assert_eq(SurvivorNameManager.get_available_count(), initial_count - 1,
    "Available count should decrease by 1 after assignment")

# --- release_name ---

func test_release_name_removes_from_used_names():
  var name = SurvivorNameManager.assign_name()
  SurvivorNameManager.release_name(name)
  assert_false(SurvivorNameManager.used_names.has(name), "Name should be removed from used_names after release")

func test_release_name_makes_name_available_again():
  var initial_count = SurvivorNameManager.get_available_count()
  var name = SurvivorNameManager.assign_name()
  assert_eq(SurvivorNameManager.get_available_count(), initial_count - 1, "Count decreased after assign")
  SurvivorNameManager.release_name(name)
  assert_eq(SurvivorNameManager.get_available_count(), initial_count, "Count restored after release")

func test_release_name_does_nothing_for_unknown_name():
  var initial_count = SurvivorNameManager.used_names.size()
  SurvivorNameManager.release_name("NotARealName")
  assert_eq(SurvivorNameManager.used_names.size(), initial_count, "Used names count should not change")

func test_release_empty_string_does_nothing():
  SurvivorNameManager.assign_name()
  var count_before = SurvivorNameManager.used_names.size()
  SurvivorNameManager.release_name("")
  assert_eq(SurvivorNameManager.used_names.size(), count_before, "Releasing empty string should not change used names")

func test_released_name_can_be_reassigned():
  var name = SurvivorNameManager.assign_name()
  SurvivorNameManager.release_name(name)

  # Exhaust all other names so the released one must be chosen
  for n in SurvivorNameManager.NAME_POOL:
    if n != name:
      SurvivorNameManager.used_names.append(n)

  var reassigned = SurvivorNameManager.assign_name()
  assert_eq(reassigned, name, "Released name should be available for reassignment")

# --- persistence (save / load) ---

func test_get_save_key_returns_expected_key():
  assert_eq(SurvivorNameManager.get_save_key(), "survivor_names", "Save key should be 'survivor_names'")

func test_save_and_load_round_trip():
  SurvivorNameManager.assign_name()
  SurvivorNameManager.assign_name()
  var saved_names = SurvivorNameManager.used_names.duplicate()

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  assert_eq(SurvivorNameManager.used_names.size(), 0, "Should be empty after reset")

  SurvivorNameManager.load_data(save_data)
  assert_eq(SurvivorNameManager.used_names.size(), saved_names.size(), "Should restore same number of names")
  for n in saved_names:
    assert_true(SurvivorNameManager.used_names.has(n), "Loaded data should contain name '%s'" % n)

func test_load_data_ignores_names_not_in_pool():
  var bogus_data = {"used_names": ["FakeNameXYZ", "AnotherBogus"]}
  SurvivorNameManager.load_data(bogus_data)
  assert_eq(SurvivorNameManager.used_names.size(), 0, "Names not in pool should be ignored on load")

func test_load_data_accepts_empty_array():
  SurvivorNameManager.assign_name()
  SurvivorNameManager.load_data({"used_names": []})
  assert_eq(SurvivorNameManager.used_names.size(), 0, "Loading empty array should clear used names")

func test_reset_data_clears_used_names():
  SurvivorNameManager.assign_name()
  SurvivorNameManager.assign_name()
  SurvivorNameManager.reset_data()
  assert_eq(SurvivorNameManager.used_names.size(), 0, "reset_data should clear all used names")

# --- pool integrity ---

func test_names_across_scenarios_are_not_reused():
  # Simulate scenario 1: one survivor survives (name stays reserved)
  var survivor_a = SurvivorNameManager.assign_name()

  # Simulate scenario 2: new survivor gets a different name
  var survivor_b = SurvivorNameManager.assign_name()
  assert_ne(survivor_a, survivor_b, "Survivor names across scenarios must be unique")

func test_name_pool_has_enough_names_for_typical_play():
  # Ensure there are enough names for multiple scenarios worth of survivors
  assert_gt(SurvivorNameManager.NAME_POOL.size(), 20, "Name pool should have more than 20 names")
