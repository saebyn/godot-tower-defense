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

  # Priority name is consumed at assignment — removed from priority_pool
  assert_false(SurvivorNameManager.priority_pool.has(name),
    "Priority name should be removed from priority_pool immediately after assignment")

  SurvivorNameManager.release_name(name)

  # name should NOT be in used_names any more
  assert_false(SurvivorNameManager.used_names.has(name),
    "Released priority name should not be in used_names")
  # name should NOT be back in priority_pool (permanently consumed)
  assert_false(SurvivorNameManager.priority_pool.has(name),
    "Released priority name should not be re-added to priority_pool")

func test_priority_pool_name_cannot_be_reassigned_after_release():
  # Use a name NOT in NAME_POOL so it cannot come back through the regular pool
  SurvivorNameManager.priority_pool.append("ZSpecialHero")
  var first = SurvivorNameManager.assign_name()
  assert_eq(first, "ZSpecialHero")
  SurvivorNameManager.release_name(first)

  # Exhaust NAME_POOL so only the generator would produce names
  for n in SurvivorNameManager.NAME_POOL:
    SurvivorNameManager.used_names.append(n)

  var second = SurvivorNameManager.assign_name()
  assert_ne(second, "ZSpecialHero",
    "Consumed priority name (not in NAME_POOL) should never be reassigned")

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
  SurvivorNameManager.assign_name() # consumes "Alpha"
  var second = SurvivorNameManager.assign_name()
  assert_true(SurvivorNameManager.NAME_POOL.has(second),
    "Should fall back to regular NAME_POOL once priority pool is exhausted")

func test_priority_name_consumed_even_if_priority_pool_cleared_before_release():
  # Assign a priority name — it is removed from priority_pool at assignment time,
  # so clearing priority_pool afterward has no effect on consumption.
  SurvivorNameManager.priority_pool.append("ZSpecialHero")
  var name = SurvivorNameManager.assign_name()
  assert_eq(name, "ZSpecialHero")
  assert_false(SurvivorNameManager.priority_pool.has(name),
    "Priority name should already be removed from priority_pool at assignment")

  SurvivorNameManager.priority_pool.clear() # simulates pool being modified (no-op here)
  SurvivorNameManager.release_name(name)

  # The name should not be in used_names and should not be re-added to priority_pool
  assert_false(SurvivorNameManager.used_names.has(name),
    "Name should not be in used_names after release")
  assert_false(SurvivorNameManager.priority_pool.has(name),
    "Priority name should not be re-added to priority_pool after release")

func test_priority_name_also_in_regular_pool_returns_to_pool_on_release():
  # "Ada" is in NAME_POOL — when used as a priority name it is assigned first,
  # but after release it becomes available again from the regular pool.
  var priority_name: String = "Ada"
  SurvivorNameManager.priority_pool.append(priority_name)
  var name = SurvivorNameManager.assign_name()
  assert_eq(name, priority_name,
    "Priority name should be assigned before regular pool names")
  assert_false(SurvivorNameManager.priority_pool.has(priority_name),
    "Name should be removed from priority_pool at assignment")
  SurvivorNameManager.release_name(name)

  # The name is back in the regular pool (it was never removed from NAME_POOL)
  assert_false(SurvivorNameManager.used_names.has(priority_name),
    "Name should not be in used_names after release")
  assert_true(SurvivorNameManager.get_available_count() > 0,
    "Regular pool should have available names including the released one")

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

func test_consumed_priority_name_not_reassigned_after_save_load_round_trip():
  # Assign and release a priority name so it is consumed and removed from priority_pool
  SurvivorNameManager.priority_pool.append("Alpha")
  var name = SurvivorNameManager.assign_name()
  SurvivorNameManager.release_name(name) # "Alpha" is now consumed

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  # After round-trip, "Alpha" must not be in priority_pool (it was consumed before save)
  assert_false(SurvivorNameManager.priority_pool.has("Alpha"),
    "Consumed priority name should not reappear in priority_pool after save/load")

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
  var data = {"used_names": ["", " "], "priority_pool": []}
  SurvivorNameManager.load_data(data)
  assert_false(SurvivorNameManager.used_names.has(""),
    "Empty string should not be loaded as a used name")
  assert_false(SurvivorNameManager.used_names.has(" "),
    "Whitespace-only string should not be loaded as a used name")

func test_load_data_accepts_empty_array():
  SurvivorNameManager.assign_name()
  SurvivorNameManager.load_data({"used_names": [], "priority_pool": []})
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

func test_reset_data_clears_used_names_including_consumed_priority():
  SurvivorNameManager.priority_pool.append("Alpha")
  var name = SurvivorNameManager.assign_name()
  SurvivorNameManager.release_name(name)
  assert_eq(SurvivorNameManager.used_names.size(), 0, "used_names should be empty after release")
  SurvivorNameManager.reset_data()
  assert_eq(SurvivorNameManager.used_names.size(), 0,
    "reset_data should leave used_names empty")

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
