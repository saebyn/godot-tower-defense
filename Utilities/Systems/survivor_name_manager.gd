extends Node

## SurvivorNameManager - Assigns and tracks persistent names and profiles for survivors
##
## Assignment priority (highest to lowest):
##   1. priority_pool  — names added here are assigned first and permanently
##                       consumed on assignment (never recycled).
##   2. NAME_POOL      — built-in pool of names; released names return here
##                       and may be reassigned to future survivors.
##   3. Generated      — when both pools are exhausted an adjective + base-name
##                       combination is produced, retrying until unique.
##
## Names in use by living survivors are never reassigned to a new survivor.
## Names of survivors that survive a scenario stay reserved until those
## survivors eventually die (or a new game is started).
##
## Survivor profiles persist across scenarios. Each profile carries an id,
## name, and status ("alive" or "dead"). Alive profiles are reused across
## scenario loads; dead profiles are kept for historical records.
## Call prepare_for_scenario() (via Stage_Scenario._enter_tree) before
## survivor nodes load so that assign_next_profile() hands out the correct
## pre-existing alive profiles in order.
##
## Implements SaveableSystem interface for centralized save management.

## Full pool of candidate names
const NAME_POOL: Array[String] = [
  "Aarav", "Ada", "Adeline", "Amos", "Astrid",
  "Blake", "Bo", "Britta",
  "Cal", "Cass", "Cedar", "Cole",
  "Darcy", "Delia", "Drew",
  "Echo", "Eli", "Emery",
  "Fern", "Finn", "Fletcher",
  "Gray", "Greer",
  "Hazel", "Hunter",
  "Ida", "Iris",
  "Jade", "June",
  "Kai", "Kit",
  "Lane", "Lark", "Leif", "Lena",
  "Mae", "Marsh", "Micah", "Miles",
  "Nadia", "Nash", "Nora",
  "Orion", "Owen",
  "Paige", "Pearl", "Piper",
  "Quinn",
  "Reed", "Remy", "River", "Roan", "Robin",
  "Sage", "Scout", "Skye", "Sloane",
  "Tate", "Terra", "Theo",
  "Uma",
  "Vale", "Vera",
  "Wren",
  "Zara", "Zed",
]

## Adjective prefixes combined with a base pool name when the pool is exhausted
const _GENERATED_NAME_PREFIXES: Array[String] = [
  "Big", "Bold", "Brave", "Calm", "Dark", "Deft", "Fast", "Grim",
  "Iron", "Kind", "Last", "Lucky", "Mad", "Old", "Quick", "Quiet",
  "Rough", "Scarred", "Slim", "Sly", "Swift", "Tough", "True", "Wily",
]

## Names currently assigned to living survivors (persisted across scenarios)
var used_names: Array[String] = []

## Priority pool — checked before NAME_POOL. Add names here to give specific
## survivors memorable identities. Priority names are permanently consumed
## on assignment and never reassigned (see _spent_priority_names).
var priority_pool: Array[String] = []

## Persistent survivor profiles. Each entry is a Dictionary with:
##   id     — unique string identifier (auto-incremented integer as string)
##   name   — survivor name (from name pool or generator)
##   status — "alive" or "dead"
var profiles: Array = []

## Auto-increment counter used to generate unique profile ids (persisted)
var _next_profile_id: int = 0

## Index into the ordered alive-profiles list; advanced each time a survivor
## node calls assign_next_profile(). Reset to 0 by prepare_for_scenario().
## Not persisted — purely runtime state.
var _profile_assignment_index: int = 0

signal name_assigned(survivor_name: String)
signal name_released(survivor_name: String)

func _ready() -> void:
  SaveManager.register_system(self)
  MyLogger.info("SurvivorNameManager", "Survivor Name Manager initialized - Pool size: %d" % NAME_POOL.size())

## Assign an available name to a new survivor.
## Priority order: priority_pool → NAME_POOL → generated fallback.
## Falls back to a generated name (adjective + base name) when both pools are
## exhausted, retrying until a unique combination is found.
func assign_name() -> String:
  var chosen: String

  var available_priority_name = _get_next_available_priority_name()
  if not available_priority_name.is_empty():
    chosen = available_priority_name
    MyLogger.info("SurvivorNameManager", "Assigning priority name '%s'" % chosen)
  else:
    var available = _get_normal_pool_names()
    if available.is_empty():
      MyLogger.info("SurvivorNameManager", "Name pool exhausted - generating a fallback name")
      chosen = _generate_unique_name()
    else:
      chosen = available.pick_random()

  used_names.append(chosen)
  name_assigned.emit(chosen)
  MyLogger.info("SurvivorNameManager", "Assigned name '%s' (%d names now in use)" % [chosen, used_names.size()])
  return chosen

## Return a name when the survivor who held it dies.
## Priority names (recorded in _spent_priority_names at assignment) are
## permanently consumed and never reassigned.
## Regular pool names are simply removed from used_names and become available again.
func release_name(survivor_name: String) -> void:
  if survivor_name.is_empty():
    return

  var idx = used_names.find(survivor_name)
  if idx == -1:
    MyLogger.warn("SurvivorNameManager", "Tried to release unknown name '%s'" % survivor_name)
    return

  used_names.remove_at(idx)

  MyLogger.info("SurvivorNameManager", "Released name '%s' back to pool (%d names in use)" % [survivor_name, used_names.size()])

  name_released.emit(survivor_name)

func add_name_to_priority_pool(new_name: String) -> bool:
  # Checks to prevent adding empty or duplicate names to the priority pool,
  # which could cause confusion and unintended behavior in name assignment
  # and release logic.
  if new_name.is_empty():
    return false

  if new_name in priority_pool:
    MyLogger.warn("SurvivorNameManager", "Tried to add name '%s' to priority pool but it's already there" % new_name)
    return false

  priority_pool.append(new_name)
  MyLogger.info("SurvivorNameManager", "Added name '%s' to priority pool" % new_name)
  return true

## Returns all names that are not currently assigned to a living survivor
func _get_normal_pool_names() -> Array[String]:
  var available: Array[String] = []
  for n in NAME_POOL:
    if n not in used_names:
      available.append(n)
  return available

## Returns first priority pool name that is available
func _get_next_available_priority_name() -> String:
  for n in priority_pool:
    if n not in used_names:
      priority_pool.erase(n) # Remove from priority pool to prevent future assignment
      return n
  return ""

## Generate a unique name by combining a random adjective prefix with a random
## base pool name, retrying until the combination is not already in use.
func _generate_unique_name() -> String:
  const MAX_ATTEMPTS: int = 10000
  for _i in range(MAX_ATTEMPTS):
    var prefix: String = _GENERATED_NAME_PREFIXES.pick_random()
    var base: String = NAME_POOL.pick_random()
    var generated: String = "%s %s" % [prefix, base]
    if generated not in used_names:
      return generated
  # Practically unreachable: prefix_count * pool_count >> realistic survivor count
  MyLogger.error("SurvivorNameManager", "Could not generate a unique name after %d attempts" % MAX_ATTEMPTS)
  return "Unknown"

## Number of primary pool names still available (excludes generated names and
## names permanently consumed via the priority pool).
func get_available_count() -> int:
  # Delegate to _get_normal_pool_names so we correctly exclude
  # names currently in use by survivors
  return _get_normal_pool_names().size()

## --- Survivor Profile API ---

## Reset the assignment index so that the next call to assign_next_profile()
## starts from the first alive profile.  Call this from Stage_Scenario._enter_tree()
## before survivor nodes load, ensuring pre-placed survivors receive their
## correct carry-forward profiles.
func prepare_for_scenario() -> void:
  _profile_assignment_index = 0
  MyLogger.info("SurvivorNameManager", "Profile assignment reset for new scenario (%d alive profiles)" % get_alive_profiles().size())

## Return the next alive profile for a new survivor node, or create a fresh
## profile if all pre-existing alive profiles have already been handed out.
## Returns the profile id (String).
func assign_next_profile() -> String:
  var alive := get_alive_profiles()
  if _profile_assignment_index < alive.size():
    var profile: Dictionary = alive[_profile_assignment_index]
    _profile_assignment_index += 1
    MyLogger.info("SurvivorNameManager", "Assigned existing profile '%s' (id=%s) to survivor" % [profile.get("name", ""), profile.get("id", "")])
    return profile.get("id", "")
  else:
    var new_profile := _create_profile()
    _profile_assignment_index += 1
    return new_profile.get("id", "")

## Create a brand-new survivor profile and register it.
## Assigns a name via the normal name-pool logic.
func _create_profile() -> Dictionary:
  var profile_id := _generate_profile_id()
  var profile_name := assign_name()
  var profile := {"id": profile_id, "name": profile_name, "status": "alive"}
  profiles.append(profile)
  MyLogger.info("SurvivorNameManager", "Created new profile '%s' (id=%s)" % [profile_name, profile_id])
  return profile

## Generate a new unique profile id (auto-incremented integer as string).
func _generate_profile_id() -> String:
  _next_profile_id += 1
  return str(_next_profile_id)

## Mark the named profile as dead and release its name back to the pool.
## The profile entry is retained for historical records.
func mark_profile_dead(profile_id: String) -> void:
  for p in profiles:
    if p.get("id") == profile_id:
      if p.get("status") == "dead":
        MyLogger.warn("SurvivorNameManager", "Profile %s is already marked dead" % profile_id)
        return
      p["status"] = "dead"
      release_name(p.get("name", ""))
      MyLogger.info("SurvivorNameManager", "Marked profile '%s' (id=%s) as dead" % [p.get("name", ""), profile_id])
      return
  MyLogger.warn("SurvivorNameManager", "mark_profile_dead: profile id '%s' not found" % profile_id)

## Return the profile Dictionary for the given id, or an empty Dictionary if
## not found.
func get_profile(profile_id: String) -> Dictionary:
  for p in profiles:
    if p.get("id") == profile_id:
      return p
  return {}

## Convenience accessor — returns the name for a given profile id, or "".
func get_profile_name(profile_id: String) -> String:
  return get_profile(profile_id).get("name", "")

## Return all profiles whose status is "alive".
func get_alive_profiles() -> Array:
  return profiles.filter(func(p: Dictionary) -> bool: return p.get("status") == "alive")

## --- SaveableSystem Interface Implementation ---

func get_save_key() -> String:
  return "survivor_names"

func get_save_data() -> Dictionary:
  return {
    "used_names": used_names.duplicate(),
    "priority_pool": priority_pool.duplicate(),
    "profiles": profiles.duplicate(true),
    "next_profile_id": _next_profile_id,
  }

func load_data(data: Dictionary) -> void:
  used_names.clear()
  priority_pool.clear()

  var loaded_used: Array = data.get("used_names", [])
  for n in loaded_used:
    if n is String and not n.strip_edges().is_empty():
      used_names.append(n)

  var loaded_priority: Array = data.get("priority_pool", [])
  for n in loaded_priority:
    if n is String and not n.strip_edges().is_empty():
      priority_pool.append(n)

  profiles.clear()
  var loaded_profiles: Array = data.get("profiles", [])
  for p in loaded_profiles:
    if p is Dictionary and p.has("id") and p.has("name") and p.has("status"):
      profiles.append(p.duplicate())

  _next_profile_id = data.get("next_profile_id", 0)
  _profile_assignment_index = 0

  MyLogger.info("SurvivorNameManager", "Loaded %d used names, %d priority names, %d profiles from save" % [used_names.size(), priority_pool.size(), profiles.size()])

func reset_data() -> void:
  used_names.clear()
  priority_pool.clear()
  profiles.clear()
  _next_profile_id = 0
  _profile_assignment_index = 0
  MyLogger.info("SurvivorNameManager", "Survivor names reset")
