extends Node
class_name Main_NavigationController

## NavigationController
##
## Manages periodic navigation mesh rebaking for the game world.
## Extracts navigation mesh management from main.gd for clarity.

@export var navigation_region: NavigationRegion3D
@export var navigation_rebake_interval: float = 5.0 ## Seconds between rebakes

func _ready() -> void:
  _start_navigation_rebake_timer()


func rebake_navigation_mesh() -> void:
  MyLogger.info("Navigation", "Rebaking navigation mesh...")
  if navigation_region and navigation_region.navigation_mesh:
    if navigation_region.is_baking():
      # Wait and retry if already baking
      MyLogger.debug("Navigation", "Navigation mesh is already baking, waiting...")
      await navigation_region.bake_finished

    navigation_region.bake_navigation_mesh()
    MyLogger.info("Navigation", "Navigation mesh rebaked!")


func _start_navigation_rebake_timer() -> void:
  var timer := Timer.new()
  timer.wait_time = navigation_rebake_interval
  timer.autostart = true
  timer.one_shot = false
  add_child(timer)
  timer.timeout.connect(rebake_navigation_mesh)
