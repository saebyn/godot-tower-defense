extends Node

## SurvivorNameManager - Assigns and tracks persistent names for survivors
##
## Assignment priority (highest to lowest):
##   1. priority_pool  — names added here are assigned first and permanently
##                       consumed on release (never recycled).
##   2. NAME_POOL      — built-in pool of 65 names; released names return here
##                       and may be reassigned to future survivors.
##   3. Generated      — when both pools are exhausted an adjective + base-name
##                       combination is produced, retrying until unique.
##
## Names in use by living survivors are never reassigned to a new survivor.
## Names of survivors that survive a scenario stay reserved until those
## survivors eventually die (or a new game is started).
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
## survivors memorable identities. Released priority names are permanently
## consumed and never reassigned (see _spent_priority_names).
var priority_pool: Array[String] = []

## Priority names that have already been used and released; excluded from
## future assignments so each priority name is a once-only identity.
var _spent_priority_names: Array[String] = []

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

  var available_priority = _get_available_priority_names()
  if not available_priority.is_empty():
    chosen = available_priority.pick_random()
    # Mark as spent at assignment time so the check in release_name() remains
    # correct even if priority_pool is later modified.
    _spent_priority_names.append(chosen)
    MyLogger.info("SurvivorNameManager", "Assigning priority name '%s'" % chosen)
  else:
    var available = _get_available_names()
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

  if survivor_name in _spent_priority_names:
    MyLogger.info("SurvivorNameManager", "Consumed priority name '%s' (permanently retired)" % survivor_name)
  else:
    MyLogger.info("SurvivorNameManager", "Released name '%s' back to pool (%d names in use)" % [survivor_name, used_names.size()])

  name_released.emit(survivor_name)

## Returns all names that are not currently assigned to a living survivor.
func _get_available_names() -> Array[String]:
  var available: Array[String] = []
  for n in NAME_POOL:
    if n not in used_names:
      available.append(n)
  return available

## Returns priority pool names that are available (not in use and not spent).
func _get_available_priority_names() -> Array[String]:
  var available: Array[String] = []
  for n in priority_pool:
    if n not in used_names and n not in _spent_priority_names:
      available.append(n)
  return available

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

## Number of primary pool names still available (excludes generated names).
## Returns 0 rather than a negative number when generated names fill used_names.
func get_available_count() -> int:
  var pool_names_in_use: int = 0
  for n in used_names:
    if n in NAME_POOL:
      pool_names_in_use += 1
  return NAME_POOL.size() - pool_names_in_use

## SaveableSystem Interface Implementation

func get_save_key() -> String:
  return "survivor_names"

func get_save_data() -> Dictionary:
  return {
    "used_names": used_names.duplicate(),
    "priority_pool": priority_pool.duplicate(),
    "spent_priority_names": _spent_priority_names.duplicate(),
  }

func load_data(data: Dictionary) -> void:
  used_names.clear()
  priority_pool.clear()
  _spent_priority_names.clear()

  var loaded_used: Array = data.get("used_names", [])
  for n in loaded_used:
    if n is String and not n.strip_edges().is_empty():
      used_names.append(n)

  var loaded_priority: Array = data.get("priority_pool", [])
  for n in loaded_priority:
    if n is String and not n.strip_edges().is_empty():
      priority_pool.append(n)

  var loaded_spent: Array = data.get("spent_priority_names", [])
  for n in loaded_spent:
    if n is String and not n.strip_edges().is_empty():
      _spent_priority_names.append(n)

  MyLogger.info("SurvivorNameManager", "Loaded %d used names, %d priority names, %d spent priority names from save" % [used_names.size(), priority_pool.size(), _spent_priority_names.size()])

func reset_data() -> void:
  used_names.clear()
  priority_pool.clear()
  _spent_priority_names.clear()
  MyLogger.info("SurvivorNameManager", "Survivor names reset")
