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

# --- priority pool ---

func test_priority_pool_name_is_assigned_before_regular_pool():
  SurvivorNameManager.priority_pool.append("ZSpecialHero")
  var name = SurvivorNameManager.assign_name()
  assert_eq(name, "ZSpecialHero", "Priority pool name should be assigned before regular pool names")

func test_priority_pool_name_is_added_to_used_names():
  SurvivorNameManager.priority_pool.append("ZSpecialHero")
  SurvivorNameManager.assign_name()
  assert_true(SurvivorNameManager.used_names.has("ZSpecialHero"),
    "Priority name should appear in used_names after assignment")

func test_priority_pool_name_is_not_reassigned_after_release():
  SurvivorNameManager.priority_pool.append("ZSpecialHero")
  var name = SurvivorNameManager.assign_name()
  assert_eq(name, "ZSpecialHero")

  # _spent_priority_names is populated at assignment time
  assert_true(SurvivorNameManager.get("_spent_priority_names").has(name),
    "Priority name should appear in _spent_priority_names immediately after assignment")

  SurvivorNameManager.release_name(name)

  # name should NOT be in used_names any more
  assert_false(SurvivorNameManager.used_names.has(name),
    "Released priority name should not be in used_names")
  # name should still be in _spent_priority_names (permanently consumed)
  assert_true(SurvivorNameManager.get("_spent_priority_names").has(name),
    "Released priority name should remain in _spent_priority_names")

func test_priority_pool_name_cannot_be_reassigned_after_release():
  SurvivorNameManager.priority_pool.append("ZSpecialHero")
  var first = SurvivorNameManager.assign_name()
  SurvivorNameManager.release_name(first)

  # Exhaust NAME_POOL so generator would also be used — priority slot is spent
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)

  var second = SurvivorNameManager.assign_name()
  assert_ne(second, "ZSpecialHero",
    "Spent priority name should never be reassigned")

func test_multiple_priority_names_are_each_assigned_before_regular_pool():
  SurvivorNameManager.priority_pool.append("Alpha")
  SurvivorNameManager.priority_pool.append("Bravo")
  var first = SurvivorNameManager.assign_name()
  var second = SurvivorNameManager.assign_name()
  assert_true(first == "Alpha" or first == "Bravo",
    "First name should come from priority pool")
  assert_true(second == "Alpha" or second == "Bravo",
    "Second name should come from priority pool")
  assert_ne(first, second, "Both priority names should be distinct")

func test_falls_back_to_regular_pool_when_priority_pool_exhausted():
  SurvivorNameManager.priority_pool.append("Alpha")
  SurvivorNameManager.assign_name()  # consumes "Alpha"
  var second = SurvivorNameManager.assign_name()
  assert_true(SurvivorNameManager.NAME_POOL.has(second),
    "Should fall back to regular NAME_POOL once priority pool is exhausted")

func test_priority_name_consumed_even_if_priority_pool_cleared_before_release():
  # Assign a priority name, then clear the priority_pool before the survivor dies
  SurvivorNameManager.priority_pool.append("ZSpecialHero")
  var name = SurvivorNameManager.assign_name()
  assert_eq(name, "ZSpecialHero")

  SurvivorNameManager.priority_pool.clear()  # simulates pool being modified
  SurvivorNameManager.release_name(name)

  # The name should still be permanently consumed, not recycled to the regular pool
  assert_false(SurvivorNameManager.used_names.has(name),
    "Name should not be in used_names after release")
  assert_true(SurvivorNameManager.get("_spent_priority_names").has(name),
    "Priority name should remain spent even if priority_pool was cleared before release")

func test_priority_name_already_in_regular_pool_is_consumed_not_recycled():
  # "Ada" is in NAME_POOL — adding it to priority_pool means it gets consumed
  var priority_name: String = "Ada"
  SurvivorNameManager.priority_pool.append(priority_name)
  var name = SurvivorNameManager.assign_name()
  assert_eq(name, priority_name)
  SurvivorNameManager.release_name(name)
  # Removing from used_names but also spending it — it must NOT be reassignable
  assert_true(SurvivorNameManager.get("_spent_priority_names").has(priority_name),
    "Name that exists in both pools should be treated as priority when released")

# --- fallback name generator ---

func test_assign_name_when_pool_exhausted_returns_non_empty():
  # Fill the entire primary pool
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)

  var generated = SurvivorNameManager.assign_name()
  assert_ne(generated, "", "Should return a non-empty generated name when pool is exhausted")

func test_assign_name_when_pool_exhausted_is_not_a_plain_pool_name():
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)

  var generated = SurvivorNameManager.assign_name()
  assert_false(SurvivorNameManager.NAME_POOL.has(generated),
    "Generated name should not be a plain pool name when pool is exhausted")

func test_assign_name_when_pool_exhausted_is_unique():
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)

  var first_generated = SurvivorNameManager.assign_name()
  var second_generated = SurvivorNameManager.assign_name()
  assert_ne(first_generated, second_generated,
    "Two consecutively generated names should be unique")

func test_assign_name_when_pool_exhausted_adds_to_used_names():
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)

  var count_before = SurvivorNameManager.used_names.size()
  var generated = SurvivorNameManager.assign_name()
  assert_eq(SurvivorNameManager.used_names.size(), count_before + 1,
    "Generated name should be added to used_names")
  assert_true(SurvivorNameManager.used_names.has(generated),
    "Generated name should appear in used_names")

func test_generated_name_can_be_released():
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)

  var generated = SurvivorNameManager.assign_name()
  var count_before = SurvivorNameManager.used_names.size()
  SurvivorNameManager.release_name(generated)
  assert_eq(SurvivorNameManager.used_names.size(), count_before - 1,
    "Generated name should be releasable")

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

func test_priority_pool_survives_save_load_round_trip():
  SurvivorNameManager.priority_pool.append("Alpha")
  SurvivorNameManager.priority_pool.append("Bravo")

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  assert_true(SurvivorNameManager.priority_pool.has("Alpha"),
    "Priority pool should survive save/load")
  assert_true(SurvivorNameManager.priority_pool.has("Bravo"),
    "Priority pool should survive save/load")

func test_spent_priority_names_survive_save_load_round_trip():
  SurvivorNameManager.priority_pool.append("Alpha")
  var name = SurvivorNameManager.assign_name()
  SurvivorNameManager.release_name(name)  # "Alpha" is now spent

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  assert_true(SurvivorNameManager.get("_spent_priority_names").has("Alpha"),
    "Spent priority names should survive save/load so they are never reassigned")

func test_generated_name_survives_save_load_round_trip():
  # Exhaust the pool then generate a fallback name
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)
  var generated = SurvivorNameManager.assign_name()

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  assert_true(SurvivorNameManager.used_names.has(generated),
    "Generated name should survive a save/load round trip")

func test_load_data_ignores_empty_strings():
  var data = {"used_names": ["", " "], "priority_pool": [], "spent_priority_names": []}
  SurvivorNameManager.load_data(data)
  assert_false(SurvivorNameManager.used_names.has(""),
    "Empty string should not be loaded as a used name")
  assert_false(SurvivorNameManager.used_names.has(" "),
    "Whitespace-only string should not be loaded as a used name")

func test_load_data_accepts_empty_array():
  SurvivorNameManager.assign_name()
  SurvivorNameManager.load_data({"used_names": [], "priority_pool": [], "spent_priority_names": []})
  assert_eq(SurvivorNameManager.used_names.size(), 0, "Loading empty array should clear used names")

func test_reset_data_clears_used_names():
  SurvivorNameManager.assign_name()
  SurvivorNameManager.assign_name()
  SurvivorNameManager.reset_data()
  assert_eq(SurvivorNameManager.used_names.size(), 0, "reset_data should clear all used names")

func test_reset_data_clears_priority_pool():
  SurvivorNameManager.priority_pool.append("Alpha")
  SurvivorNameManager.reset_data()
  assert_eq(SurvivorNameManager.priority_pool.size(), 0, "reset_data should clear priority_pool")

func test_reset_data_clears_spent_priority_names():
  SurvivorNameManager.priority_pool.append("Alpha")
  var name = SurvivorNameManager.assign_name()
  SurvivorNameManager.release_name(name)
  SurvivorNameManager.reset_data()
  assert_eq(SurvivorNameManager.get("_spent_priority_names").size(), 0,
    "reset_data should clear _spent_priority_names")

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
