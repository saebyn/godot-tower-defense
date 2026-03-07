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

## Names currently assigned to living survivors (persisted across scenarios)
var used_names: Array[String] = []

signal name_assigned(survivor_name: String)
signal name_released(survivor_name: String)

func _ready() -> void:
  SaveManager.register_system(self)
  MyLogger.info("SurvivorNameManager", "Survivor Name Manager initialized - Pool size: %d" % NAME_POOL.size())

## Assign an available name from the pool to a new survivor.
## Returns an empty string if all names are exhausted.
func assign_name() -> String:
  var available = _get_available_names()

  if available.is_empty():
    MyLogger.warn("SurvivorNameManager", "Name pool exhausted - no names available")
    return ""

  # Pick a random name from the available list
  var chosen: String = available[randi() % available.size()]
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

## Number of names still available in the pool.
func get_available_count() -> int:
  return NAME_POOL.size() - used_names.size()

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
    if n is String and n in NAME_POOL:
      used_names.append(n)

  MyLogger.info("SurvivorNameManager", "Loaded %d used names from save" % used_names.size())

func reset_data() -> void:
  used_names.clear()
  MyLogger.info("SurvivorNameManager", "Survivor names reset")
