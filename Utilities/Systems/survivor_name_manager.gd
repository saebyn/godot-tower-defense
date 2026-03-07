extends Node

## SurvivorNameManager - Assigns and tracks persistent names for survivors
##
## Each survivor receives a unique name drawn from a built-in pool.
## Names in use by living survivors are never reassigned to a new survivor.
## When a survivor dies their name is returned to the available pool so it
## can be reused in later scenarios.
##
## Names of survivors that survive a scenario stay reserved until those
## survivors eventually die (or a new game is started).
##
## When the primary pool is exhausted, a generated name (adjective + base name)
## is produced, retrying until a unique combination is found.
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

signal name_assigned(survivor_name: String)
signal name_released(survivor_name: String)

func _ready() -> void:
  SaveManager.register_system(self)
  MyLogger.info("SurvivorNameManager", "Survivor Name Manager initialized - Pool size: %d" % NAME_POOL.size())

## Assign an available name from the pool to a new survivor.
## Falls back to a generated name (adjective + base name) when the pool is
## exhausted, retrying until a unique combination is found.
func assign_name() -> String:
  var available = _get_available_names()

  var chosen: String
  if available.is_empty():
    MyLogger.info("SurvivorNameManager", "Name pool exhausted - generating a fallback name")
    chosen = _generate_unique_name()
  else:
    # Pick a random name from the available list
    chosen = available.pick_random()

  used_names.append(chosen)
  name_assigned.emit(chosen)
  MyLogger.info("SurvivorNameManager", "Assigned name '%s' (%d names now in use)" % [chosen, used_names.size()])
  return chosen

## Return a name to the available pool (call when the survivor who held it dies).
func release_name(survivor_name: String) -> void:
  if survivor_name.is_empty():
    return

  var idx = used_names.find(survivor_name)
  if idx == -1:
    MyLogger.warn("SurvivorNameManager", "Tried to release unknown name '%s'" % survivor_name)
    return

  used_names.remove_at(idx)
  name_released.emit(survivor_name)
  MyLogger.info("SurvivorNameManager", "Released name '%s' back to pool (%d names in use)" % [survivor_name, used_names.size()])

## Returns all names that are not currently assigned to a living survivor.
func _get_available_names() -> Array[String]:
  var available: Array[String] = []
  for n in NAME_POOL:
    if n not in used_names:
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
  }

func load_data(data: Dictionary) -> void:
  used_names.clear()
  var loaded: Array = data.get("used_names", [])
  for n in loaded:
    if n is String and not n.strip_edges().is_empty():
      used_names.append(n)

  MyLogger.info("SurvivorNameManager", "Loaded %d used names from save" % used_names.size())

func reset_data() -> void:
  used_names.clear()
  MyLogger.info("SurvivorNameManager", "Survivor names reset")
