extends Node

## Manages tech tree unlocks, prerequisites, and mutually exclusive branch logic
## Loads tech tree structure from Config/TechTree/ resource files
## Implements SaveableSystem interface for centralized save management

signal tech_unlocked(tech_id: String)
signal tech_locked(tech_id: String)

var unlocked_tech_ids: Array[String] = []
var locked_tech_ids: Array[String] = []
var tech_nodes: Dictionary = {} # tech_id -> TechNodeResource

const TECH_TREE_PATH = "res://Config/TechTree/"

func _ready() -> void:
  Logger.info("TechTreeManager", "Initializing TechTreeManager...")
  
  # Register with SaveManager
  SaveManager.register_system(self)
  
  # Load tech tree definitions
  _load_tech_tree()
  
  Logger.info("TechTreeManager", "TechTreeManager initialized with %d tech nodes" % tech_nodes.size())

## Load all tech node resources from Config/TechTree/
func _load_tech_tree() -> void:
  var dir = DirAccess.open(TECH_TREE_PATH)
  if not dir:
    Logger.warn("TechTreeManager", "Could not open tech tree directory: %s" % TECH_TREE_PATH)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  
  while file_name != "":
    if not dir.current_is_dir() and file_name.ends_with(".tres"):
      var resource_path = TECH_TREE_PATH + file_name
      var tech_node = load(resource_path) as TechNodeResource
      
      if tech_node and tech_node.is_valid():
        tech_nodes[tech_node.id] = tech_node
        Logger.debug("TechTreeManager", "Loaded tech node: %s (%s)" % [tech_node.id, tech_node.display_name])
      else:
        Logger.error("TechTreeManager", "Failed to load or invalid tech node: %s" % resource_path)
    
    file_name = dir.get_next()
  
  dir.list_dir_end()
  
  if tech_nodes.size() == 0:
    Logger.warn("TechTreeManager", "No tech nodes found in %s" % TECH_TREE_PATH)

## Check if a tech can be unlocked
func can_unlock_tech(tech_id: String) -> bool:
  # Check if tech exists
  if tech_id not in tech_nodes:
    Logger.error("TechTreeManager", "Tech node does not exist: %s" % tech_id)
    return false
  
  # Check if already unlocked
  if tech_id in unlocked_tech_ids:
    Logger.debug("TechTreeManager", "Tech already unlocked: %s" % tech_id)
    return false
  
  # Check if permanently locked
  if tech_id in locked_tech_ids:
    Logger.debug("TechTreeManager", "Tech is permanently locked: %s" % tech_id)
    return false
  
  var tech = tech_nodes[tech_id]
  
  # Check player level requirement
  if CurrencyManager.get_level() < tech.level_requirement:
    Logger.debug("TechTreeManager", "Tech %s requires level %d, player is level %d" % [tech_id, tech.level_requirement, CurrencyManager.get_level()])
    return false
  
  # Check scrap cost (currently unused but kept for potential future use)
  if tech.scrap_cost > 0 and CurrencyManager.get_scrap() < tech.scrap_cost:
    Logger.debug("TechTreeManager", "Tech %s requires %d scrap, player has %d" % [tech_id, tech.scrap_cost, CurrencyManager.get_scrap()])
    return false
  
  # Check prerequisites
  for prereq_id in tech.prerequisite_tech_ids:
    if prereq_id not in unlocked_tech_ids:
      Logger.debug("TechTreeManager", "Tech %s requires prerequisite: %s" % [tech_id, prereq_id])
      return false
  
  # Check branch completion requirements
  for branch_name in tech.requires_branch_completion:
    if not is_branch_completed(branch_name):
      Logger.debug("TechTreeManager", "Tech %s requires branch completion: %s" % [tech_id, branch_name])
      return false
  
  # Check achievement requirements (if AchievementManager exists)
  if tech.achievement_ids.size() > 0:
    # TODO: Integrate with AchievementManager when it's implemented
    Logger.debug("TechTreeManager", "Tech %s has achievement requirements (not yet checked)" % tech_id)
    # For now, we'll allow unlocking without achievements
  
  return true

## Unlock a tech node
func unlock_tech(tech_id: String) -> bool:
  if not can_unlock_tech(tech_id):
    Logger.warn("TechTreeManager", "Cannot unlock tech: %s" % tech_id)
    return false
  
  var tech = tech_nodes[tech_id]
  
  # Deduct scrap cost if any (currently unused)
  if tech.scrap_cost > 0:
    if not CurrencyManager.spend_scrap(tech.scrap_cost):
      Logger.error("TechTreeManager", "Failed to spend scrap for tech: %s" % tech_id)
      return false
  
  # Add to unlocked techs
  unlocked_tech_ids.append(tech_id)
  Logger.info("TechTreeManager", "Unlocked tech: %s (%s)" % [tech_id, tech.display_name])
  
  # Lock mutually exclusive techs
  for exclusive_id in tech.mutually_exclusive_with:
    if exclusive_id not in locked_tech_ids:
      locked_tech_ids.append(exclusive_id)
      tech_locked.emit(exclusive_id)
      Logger.info("TechTreeManager", "Locked mutually exclusive tech: %s" % exclusive_id)
  
  # Emit unlock signal
  tech_unlocked.emit(tech_id)
  
  return true

## Check if a tech is unlocked
func is_tech_unlocked(tech_id: String) -> bool:
  return tech_id in unlocked_tech_ids

## Check if a tech is permanently locked
func is_tech_locked(tech_id: String) -> bool:
  return tech_id in locked_tech_ids

## Get a tech node by ID
func get_tech_node(tech_id: String) -> TechNodeResource:
  return tech_nodes.get(tech_id)

## Get all tech nodes in a specific branch
func get_techs_in_branch(branch_name: String) -> Array[TechNodeResource]:
  var branch_techs: Array[TechNodeResource] = []
  for tech_id in tech_nodes:
    var tech = tech_nodes[tech_id]
    if tech.branch_name == branch_name:
      branch_techs.append(tech)
  return branch_techs

## Check if a branch is completed (all non-mutually-exclusive techs unlocked)
func is_branch_completed(branch_name: String) -> bool:
  var branch_techs = get_techs_in_branch(branch_name)
  
  if branch_techs.size() == 0:
    Logger.warn("TechTreeManager", "Branch %s has no techs" % branch_name)
    return false
  
  for tech in branch_techs:
    # Skip if locked by mutual exclusivity
    if tech.id in locked_tech_ids:
      continue
    
    # Check if unlocked
    if tech.id not in unlocked_tech_ids:
      return false
  
  return true

## Get all unlocked obstacle IDs from the tech tree
func get_unlocked_obstacle_ids() -> Array[String]:
  var obstacle_ids: Array[String] = []
  
  for tech_id in unlocked_tech_ids:
    var tech = tech_nodes.get(tech_id)
    if tech:
      for obstacle_id in tech.unlocked_obstacle_ids:
        if obstacle_id not in obstacle_ids:
          obstacle_ids.append(obstacle_id)
  
  return obstacle_ids

## Reset tech tree state (for testing or new game)
func reset_tech_tree() -> void:
  unlocked_tech_ids.clear()
  locked_tech_ids.clear()
  Logger.info("TechTreeManager", "Tech tree reset")

## SaveableSystem Interface Implementation

## Get unique save key for this system
func get_save_key() -> String:
  return "tech_tree"

## Get saveable state as dictionary
func get_save_data() -> Dictionary:
  return {
    "unlocked_tech_ids": unlocked_tech_ids,
    "locked_tech_ids": locked_tech_ids,
  }

## Load data from saved state
func load_data(data: Dictionary) -> void:
  # Load unlocked tech IDs
  var loaded_unlocked: Array = data.get("unlocked_tech_ids", [])
  unlocked_tech_ids.clear()
  for tech_id in loaded_unlocked:
    if tech_id is String:
      unlocked_tech_ids.append(tech_id)
  
  # Load locked tech IDs (from exclusive branches)
  var loaded_locked: Array = data.get("locked_tech_ids", [])
  locked_tech_ids.clear()
  for tech_id in loaded_locked:
    if tech_id is String:
      locked_tech_ids.append(tech_id)
  
  Logger.info("TechTreeManager", "Tech tree loaded - Unlocked: %d, Locked: %d" % [unlocked_tech_ids.size(), locked_tech_ids.size()])

## Reset to default state (for new game)
func reset_data() -> void:
  reset_tech_tree()
