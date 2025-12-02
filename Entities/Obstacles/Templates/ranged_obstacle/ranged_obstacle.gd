extends Entity_PlaceableObstacle
class_name Entity_RangedObstacle

const RANGED_OBSTACLES_GROUP: String = "ranged_obstacles"

@export var effect_range: float = 15.0:
  get:
    return effect_range
  set(value):
    effect_range = value
    if effect_range_indicator:
      effect_range_indicator.scale = Vector3(effect_range * 2, effect_range * 2, effect_range * 2)

## Whether this obstacle is currently being hovered over by the mouse
var _is_hovered: bool = false

@onready var effect_range_indicator: MeshInstance3D = $RangePreview

func _ready():
  # Call parent _ready first
  super._ready()
  
  # Add to obstacles group for range preview coordination
  add_to_group(RANGED_OBSTACLES_GROUP)

  # Scale the range indicator properly (do this once at ready)
  # SphereMesh has a default radius of 0.5. To get a sphere with radius = effect_range,
  # we need to scale it by effect_range / 0.5 = effect_range * 2.
  if effect_range_indicator:
    effect_range_indicator.scale = Vector3(effect_range * 2, effect_range * 2, effect_range * 2)

  MyLogger.info("RangedObstacle", "Ranged obstacle initialized with attack range: %f" % effect_range)


## Overrides the parent method to set up the attack range indicator for placement preview.
## Scales and displays the effect_range_indicator mesh to show the attack range during placement.
func _enter_placement_mode() -> void:
  super._enter_placement_mode()

  # Show the range indicator during placement mode
  if effect_range_indicator:
    effect_range_indicator.visible = true

## Hides the range indicator when exiting placement mode.
func _exit_placement_mode() -> void:
  super._exit_placement_mode()

  if effect_range_indicator:
    effect_range_indicator.visible = false


## Shows the attack range indicator for this ranged obstacle.
## Used during placement mode to show all existing turret ranges, or on hover.
func show_range_indicator() -> void:
  MyLogger.debug("RangedObstacle", "Showing range indicator with range: %f" % effect_range)
  if effect_range_indicator:
    effect_range_indicator.visible = true


## Hides the attack range indicator for this ranged obstacle.
## Used when exiting placement mode or when mouse stops hovering.
## @param force When true, hides the indicator even if currently being hovered (used for placement mode exit)
func hide_range_indicator(force: bool = false) -> void:
  # Don't hide if currently being hovered, unless forced
  if _is_hovered and not force:
    return
  if effect_range_indicator:
    effect_range_indicator.visible = false


## Called when mouse enters this obstacle's collision shape.
func on_mouse_enter() -> void:
  _is_hovered = true
  show_range_indicator()


## Called when mouse exits this obstacle's collision shape.
func on_mouse_exit() -> void:
  _is_hovered = false
  hide_range_indicator()

## Keep original effect range to handle buff stacking
var _original_effect_range: float = 0

func _stack_buffs(amounts: Array[float]) -> float:
  if _original_effect_range == 0:
    _original_effect_range = effect_range

  var result = _original_effect_range
  for buff in amounts:
    result *= (1.0 + buff)
  return result

func _handle_buffs(buff_type: Entity_BuffObstacle.BuffType, amounts: Array[float]) -> void:
  match buff_type:
    Entity_BuffObstacle.BuffType.RANGE:
      effect_range = _stack_buffs(amounts)
