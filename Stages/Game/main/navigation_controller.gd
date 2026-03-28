extends Node
class_name Main_NavigationController

## NavigationController
##
## Manages periodic navigation mesh rebaking for the game world.
## Extracts navigation mesh management from main.gd for clarity.

@export var navigation_region: NavigationRegion3D
@export var navigation_rebake_interval: float = 5.0 ## Seconds between rebakes

## Tracks whether a rebake coroutine is already in progress to prevent overlapping bakes.
var _rebake_in_progress: bool = false
## Tracks whether a rebake was requested while one was already in progress.
var _rebake_queued: bool = false

func _ready() -> void:
  _start_navigation_rebake_timer()


func rebake_navigation_mesh() -> void:
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

    navigation_region.bake_navigation_mesh()
    await navigation_region.bake_finished
    MyLogger.info("Navigation", "Navigation mesh rebaked!")

  _rebake_in_progress = false

  if _rebake_queued:
    _rebake_queued = false
    rebake_navigation_mesh()


func _start_navigation_rebake_timer() -> void:
  var timer := Timer.new()
  timer.wait_time = navigation_rebake_interval
  timer.autostart = true
  timer.one_shot = false
  add_child(timer)
  timer.timeout.connect(rebake_navigation_mesh)
