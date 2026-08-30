extends Node
class_name Main_NavigationController

## NavigationController
##
## Manages periodic navigation mesh rebaking for the game world.
## Extracts navigation mesh management from main.gd for clarity.

const NAVIGATION_MONITORS := {
  "Navigation/Active Zombies": Utility_NavigationMetrics.ACTIVE_ZOMBIES,
  "Navigation/Target Sets per Second": Utility_NavigationMetrics.TARGET_SETS_PER_SECOND,
  "Navigation/Duplicate Target Sets per Second": Utility_NavigationMetrics.DUPLICATE_TARGET_SETS_PER_SECOND,
  "Navigation/Duplicate Target Set Percent": Utility_NavigationMetrics.DUPLICATE_TARGET_SET_PERCENT,
  "Navigation/Explicit Path Queries per Second": Utility_NavigationMetrics.EXPLICIT_PATH_QUERIES_PER_SECOND,
  "Navigation/Explicit Path Query Time ms per Second": Utility_NavigationMetrics.EXPLICIT_PATH_QUERY_TIME_MSEC_PER_SECOND,
  "Navigation/Explicit Path Query Max ms": Utility_NavigationMetrics.EXPLICIT_PATH_QUERY_MAX_MSEC,
  "Navigation/Path Changes per Second": Utility_NavigationMetrics.PATH_CHANGES_PER_SECOND,
  "Navigation/Agent Path Update Time ms per Second": Utility_NavigationMetrics.AGENT_PATH_UPDATE_TIME_MSEC_PER_SECOND,
  "Navigation/Agent Path Update Max ms": Utility_NavigationMetrics.AGENT_PATH_UPDATE_MAX_MSEC,
  "Navigation/Reachability Checks per Second": Utility_NavigationMetrics.REACHABILITY_CHECKS_PER_SECOND,
  "Navigation/Fallback Checks per Second": Utility_NavigationMetrics.FALLBACK_CHECKS_PER_SECOND,
  "Navigation/Rebake Requests per Second": Utility_NavigationMetrics.REBAKE_REQUESTS_PER_SECOND,
  "Navigation/Rebakes Started per Second": Utility_NavigationMetrics.REBAKES_STARTED_PER_SECOND,
  "Navigation/Last Rebake ms": Utility_NavigationMetrics.LAST_REBAKE_MSEC,
}

@export var ui: MainUI ## Reference to main UI to send updates on bounding box
@export var navigation_region: NavigationRegion3D
@export var navigation_rebake_interval: float = 5.0 ## Seconds between rebakes

## Tracks whether a rebake coroutine is already in progress to prevent overlapping bakes.
var _rebake_in_progress: bool = false
## Tracks whether a rebake was requested while one was already in progress.
var _rebake_queued: bool = false


func _ready() -> void:
  Utility_NavigationMetrics.reset()
  _register_navigation_monitors()
  _start_navigation_rebake_timer()


func _process(delta: float) -> void:
  Utility_NavigationMetrics.update(delta)


func _exit_tree() -> void:
  for monitor_name in NAVIGATION_MONITORS:
    if Performance.has_custom_monitor(monitor_name):
      Performance.remove_custom_monitor(monitor_name)


func rebake_navigation_mesh() -> void:
  Utility_NavigationMetrics.record_rebake_requested()
  _rebake_navigation_mesh()


func _rebake_navigation_mesh() -> void:
  if _rebake_in_progress:
    # Queue one additional bake for after the current one finishes
    _rebake_queued = true
    MyLogger.debug("Navigation", "Rebake requested while one is in progress; queuing.")
    return

  _rebake_in_progress = true
  _rebake_queued = false

  MyLogger.info("Navigation", "Rebaking navigation mesh...")
  if navigation_region and navigation_region.navigation_mesh:
    if navigation_region.is_baking():
      MyLogger.debug("Navigation", "Navigation mesh is already baking, waiting...")
      await navigation_region.bake_finished

    Utility_NavigationMetrics.record_rebake_started()
    var rebake_started_usec := Time.get_ticks_usec()
    navigation_region.bake_navigation_mesh()
    await navigation_region.bake_finished
    Utility_NavigationMetrics.record_rebake_finished(Time.get_ticks_usec() - rebake_started_usec)
    MyLogger.info("Navigation", "Navigation mesh rebaked!")

  _rebake_in_progress = false

  if _rebake_queued:
    _rebake_queued = false
    _rebake_navigation_mesh()


func _register_navigation_monitors() -> void:
  for monitor_name in NAVIGATION_MONITORS:
    if Performance.has_custom_monitor(monitor_name):
      Performance.remove_custom_monitor(monitor_name)
    Performance.add_custom_monitor(
      monitor_name,
      _get_navigation_metric,
      [NAVIGATION_MONITORS[monitor_name]],
    )


func _get_navigation_metric(metric: StringName) -> float:
  return Utility_NavigationMetrics.get_metric(metric)


func _start_navigation_rebake_timer() -> void:
  var timer := Timer.new()
  timer.wait_time = navigation_rebake_interval
  timer.autostart = true
  timer.one_shot = false
  add_child(timer)
  timer.timeout.connect(rebake_navigation_mesh)
