extends GutTest

## Unit tests for survivor profile persistence in SurvivorNameManager

func before_each():
  SurvivorNameManager.reset_data()

func after_each():
  SurvivorNameManager.reset_data()

# --- assign_next_profile: creates a new profile when none exist ---

func test_assign_next_profile_returns_non_empty_id():
  var profile_id = SurvivorNameManager.assign_next_profile()
  assert_ne(profile_id, "", "assign_next_profile should return a non-empty id")

func test_assign_next_profile_adds_a_profile():
  SurvivorNameManager.assign_next_profile()
  assert_eq(SurvivorNameManager.profiles.size(), 1, "One profile should exist after first assignment")

func test_assign_next_profile_new_profile_is_alive():
  var profile_id = SurvivorNameManager.assign_next_profile()
  var profile = SurvivorNameManager.get_profile(profile_id)
  assert_eq(profile.get("status"), "alive", "Newly created profile should be alive")

func test_assign_next_profile_new_profile_has_a_name():
  var profile_id = SurvivorNameManager.assign_next_profile()
  var profile = SurvivorNameManager.get_profile(profile_id)
  assert_ne(profile.get("name", ""), "", "Newly created profile should have a non-empty name")

func test_two_new_profiles_have_different_ids():
  var id1 = SurvivorNameManager.assign_next_profile()
  var id2 = SurvivorNameManager.assign_next_profile()
  assert_ne(id1, id2, "Two profiles should have different ids")

func test_two_new_profiles_have_different_names():
  var id1 = SurvivorNameManager.assign_next_profile()
  var id2 = SurvivorNameManager.assign_next_profile()
  var name1 = SurvivorNameManager.get_profile_name(id1)
  var name2 = SurvivorNameManager.get_profile_name(id2)
  assert_ne(name1, name2, "Two profiles should have different names")

# --- get_profile and get_profile_name ---

func test_get_profile_returns_correct_profile():
  var profile_id = SurvivorNameManager.assign_next_profile()
  var profile = SurvivorNameManager.get_profile(profile_id)
  assert_eq(profile.get("id"), profile_id, "get_profile should return the profile with the given id")

func test_get_profile_returns_empty_dict_for_unknown_id():
  var profile = SurvivorNameManager.get_profile("nonexistent_id")
  assert_eq(profile, {}, "get_profile should return an empty dict for an unknown id")

func test_get_profile_name_returns_name_for_known_profile():
  var profile_id = SurvivorNameManager.assign_next_profile()
  var name = SurvivorNameManager.get_profile_name(profile_id)
  assert_ne(name, "", "get_profile_name should return a non-empty name for a known profile")

func test_get_profile_name_returns_empty_for_unknown_profile():
  var name = SurvivorNameManager.get_profile_name("nonexistent_id")
  assert_eq(name, "", "get_profile_name should return empty string for unknown id")

# --- get_alive_profiles ---

func test_get_alive_profiles_returns_all_new_profiles():
  SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.assign_next_profile()
  assert_eq(SurvivorNameManager.get_alive_profiles().size(), 2, "Both new profiles should be alive")

func test_get_alive_profiles_excludes_dead_profiles():
  var id1 = SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.mark_profile_dead(id1)
  assert_eq(SurvivorNameManager.get_alive_profiles().size(), 1, "Dead profile should not appear in alive list")

# --- mark_profile_dead ---

func test_mark_profile_dead_sets_status_to_dead():
  var profile_id = SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.mark_profile_dead(profile_id)
  var profile = SurvivorNameManager.get_profile(profile_id)
  assert_eq(profile.get("status"), "dead", "Profile status should be 'dead' after mark_profile_dead")

func test_mark_profile_dead_does_not_remove_profile():
  var profile_id = SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.mark_profile_dead(profile_id)
  assert_eq(SurvivorNameManager.profiles.size(), 1, "Profile should still exist after being marked dead")

func test_mark_profile_dead_releases_name_for_reuse():
  var profile_id = SurvivorNameManager.assign_next_profile()
  var profile_name = SurvivorNameManager.get_profile_name(profile_id)
  SurvivorNameManager.mark_profile_dead(profile_id)
  assert_false(SurvivorNameManager.used_names.has(profile_name),
    "Dead survivor's name should be released from used_names")

func test_mark_profile_dead_twice_is_idempotent():
  var profile_id = SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.mark_profile_dead(profile_id)
  SurvivorNameManager.mark_profile_dead(profile_id) # should not error or double-release
  var profile = SurvivorNameManager.get_profile(profile_id)
  assert_eq(profile.get("status"), "dead", "Profile should still be dead after second call")

func test_mark_profile_dead_unknown_id_does_not_crash():
  SurvivorNameManager.mark_profile_dead("nonexistent_id") # should not crash
  assert_true(true, "mark_profile_dead with unknown id should not crash")

# --- prepare_for_scenario and profile carry-forward ---

func test_prepare_for_scenario_resets_assignment_index():
  # Create two profiles and assign them both
  SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.assign_next_profile()

  # Reset: next assignment should return the first alive profile again
  SurvivorNameManager.prepare_for_scenario()
  var alive = SurvivorNameManager.get_alive_profiles()
  var reassigned_id = SurvivorNameManager.assign_next_profile()
  assert_eq(reassigned_id, alive[0].get("id"), "After prepare_for_scenario, first assignment should return first alive profile")

func test_alive_profiles_are_reused_after_prepare_for_scenario():
  # Scenario 1: create two survivors
  var id1 = SurvivorNameManager.assign_next_profile()
  var id2 = SurvivorNameManager.assign_next_profile()

  # Scenario 2 starts: reset and reassign
  SurvivorNameManager.prepare_for_scenario()
  var reused_id1 = SurvivorNameManager.assign_next_profile()
  var reused_id2 = SurvivorNameManager.assign_next_profile()

  assert_eq(reused_id1, id1, "First alive profile should be reused in scenario 2")
  assert_eq(reused_id2, id2, "Second alive profile should be reused in scenario 2")

func test_new_profile_created_when_alive_profiles_exhausted():
  # Scenario 1: one survivor
  SurvivorNameManager.assign_next_profile()

  # Scenario 2: two survivor slots — first reuses alive profile, second is new
  SurvivorNameManager.prepare_for_scenario()
  var profile_count_before = SurvivorNameManager.profiles.size()
  SurvivorNameManager.assign_next_profile() # reuses existing
  SurvivorNameManager.assign_next_profile() # creates new

  assert_eq(SurvivorNameManager.profiles.size(), profile_count_before + 1,
    "A new profile should be created when alive profiles are exhausted")

func test_dead_profiles_are_not_reused():
  # Create one survivor and kill them
  var id1 = SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.mark_profile_dead(id1)

  # Scenario 2: no alive profiles remain; a fresh profile should be created
  SurvivorNameManager.prepare_for_scenario()
  var id2 = SurvivorNameManager.assign_next_profile()

  assert_ne(id2, id1, "Dead profiles should not be reused — a new profile id should be created")

func test_surviving_profiles_carry_forward_their_name():
  # Scenario 1: survivor Alice lives
  var id1 = SurvivorNameManager.assign_next_profile()
  var name1 = SurvivorNameManager.get_profile_name(id1)

  # Scenario 2 starts: Alice's profile is reused with the same name
  SurvivorNameManager.prepare_for_scenario()
  var reused_id = SurvivorNameManager.assign_next_profile()

  assert_eq(reused_id, id1, "Surviving profile should be reused")
  assert_eq(SurvivorNameManager.get_profile_name(reused_id), name1,
    "Surviving survivor should keep their name in the next scenario")

# --- save / load round-trip ---

func test_profiles_survive_save_load_round_trip():
  var id1 = SurvivorNameManager.assign_next_profile()
  var name1 = SurvivorNameManager.get_profile_name(id1)

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  assert_eq(SurvivorNameManager.profiles.size(), 1, "Profile should survive save/load")
  assert_eq(SurvivorNameManager.get_profile_name(id1), name1,
    "Profile name should survive save/load")
  assert_eq(SurvivorNameManager.get_profile(id1).get("status"), "alive",
    "Profile status should survive save/load")

func test_dead_profiles_survive_save_load_round_trip():
  var id1 = SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.mark_profile_dead(id1)

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  assert_eq(SurvivorNameManager.profiles.size(), 1, "Dead profile should survive save/load")
  assert_eq(SurvivorNameManager.get_profile(id1).get("status"), "dead",
    "Dead profile status should survive save/load")

func test_next_profile_id_survives_save_load_round_trip():
  SurvivorNameManager.assign_next_profile() # id 1
  SurvivorNameManager.assign_next_profile() # id 2

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  # Consume the two alive profiles (they carry forward from save)
  SurvivorNameManager.assign_next_profile() # reuses id 1
  SurvivorNameManager.assign_next_profile() # reuses id 2
  # Now request a third survivor — alive pool is exhausted; a brand-new profile is created
  var id3 = SurvivorNameManager.assign_next_profile()
  assert_ne(id3, "1", "New profile after load should not reuse id 1")
  assert_ne(id3, "2", "New profile after load should not reuse id 2")
  assert_eq(id3, "3", "New profile id should continue from the saved next_profile_id")

func test_profile_assignment_index_reset_on_load():
  SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.assign_next_profile()

  var save_data = SurvivorNameManager.get_save_data()
  SurvivorNameManager.reset_data()
  SurvivorNameManager.load_data(save_data)

  # After load, assignment index should be 0 — first assignment returns first alive profile
  var alive = SurvivorNameManager.get_alive_profiles()
  var first_id = SurvivorNameManager.assign_next_profile()
  assert_eq(first_id, alive[0].get("id"),
    "Assignment index should be reset to 0 after load_data")

# --- reset_data ---

func test_reset_data_clears_profiles():
  SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.reset_data()
  assert_eq(SurvivorNameManager.profiles.size(), 0, "reset_data should clear all profiles")

func test_reset_data_resets_next_profile_id():
  SurvivorNameManager.assign_next_profile()
  SurvivorNameManager.reset_data()
  var id1 = SurvivorNameManager.assign_next_profile()
  assert_eq(id1, "1", "After reset_data, profile ids should start from 1 again")
