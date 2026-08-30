extends Node
class_name Main_HoverController

## HoverController
##
## Manages hover interactions in the game world:
## - Ranged building range indicators on hover
## - Building tooltip display
## - Unit-frame visibility for entities with health components

@export var camera: Camera3D
@export var ui: Control

@export var raycast_length: float = 1000.0

## Currently hovered ranged building for range preview
var _hovered_ranged_building: Entity_RangedBuilding = null
## Any entity (enemy, building, target) currently under the cursor — used for unit-frame hover
var _hovered_entity: Node3D = null
## Raycast for detecting entities on hover
var _hover_raycast: RayCast3D
## Building tooltip for displaying stats on hover
var _building_tooltip = null # UI_BuildingTooltip
## Last mouse position to avoid redundant hover checks
var _last_hover_check_position: Vector2 = Vector2(-1, -1)
## Minimum distance mouse must move before triggering hover check (in pixels)
const HOVER_CHECK_THRESHOLD: float = 5.0


func _ready() -> void:
  # Create hover detection raycast
  _hover_raycast = RayCast3D.new()
  _hover_raycast.enabled = false
  _hover_raycast.collision_mask = 1 | 2 | 4 # Targets/survivors (layer 1) + buildings (layer 2) + enemies (layer 3)
  add_child(_hover_raycast)

  # Create building tooltip if scene is assigned
  if ui:
    _building_tooltip = UI_BuildingTooltip.new()
    ui.add_child(_building_tooltip)
    _building_tooltip.visible = false


## Handle hover input for the given mouse position.
## Called from PlayerInputController on mouse motion.
func handle_hover(mouse_position: Vector2) -> void:
  # Skip if mouse hasn't moved enough to warrant a new raycast
  if _last_hover_check_position.distance_to(mouse_position) < HOVER_CHECK_THRESHOLD:
    return
  _last_hover_check_position = mouse_position

  var ray_origin := camera.project_ray_origin(mouse_position)
  var ray_direction := camera.project_ray_normal(mouse_position)

  _hover_raycast.enabled = true
  _hover_raycast.position = ray_origin
  _hover_raycast.target_position = ray_direction * raycast_length
  _hover_raycast.force_raycast_update()

  var new_hovered_building: Entity_RangedBuilding = null
  var new_hovered_entity: Node3D = null

  if _hover_raycast.is_colliding():
    var collider = _hover_raycast.get_collider()
    if collider is Node3D:
      new_hovered_entity = collider as Node3D
    if collider is Entity_RangedBuilding:
      new_hovered_building = collider as Entity_RangedBuilding

  _hover_raycast.enabled = false

  # ── Ranged-building range indicator + tooltip ──────────────────────────────
  if new_hovered_building != _hovered_ranged_building:
    if _hovered_ranged_building and is_instance_valid(_hovered_ranged_building):
      _hovered_ranged_building.on_mouse_exit()
      if _building_tooltip:
        _building_tooltip.hide_tooltip()
    _hovered_ranged_building = new_hovered_building
    if _hovered_ranged_building:
      _hovered_ranged_building.on_mouse_enter()
      if _building_tooltip:
        _building_tooltip.show_tooltip(_hovered_ranged_building, mouse_position)

  # ── Unit-frame hover for any entity with a health component ────────────────
  # Clear stale reference if the previously hovered entity was freed (e.g. scrap collected)
  if _hovered_entity != null and not is_instance_valid(_hovered_entity):
    _hovered_entity = null
  if new_hovered_entity != _hovered_entity:
    if _hovered_entity != null:
      _hide_entity_unit_frame(_hovered_entity)
    _hovered_entity = new_hovered_entity
    _show_entity_unit_frame(_hovered_entity)


## Clear hover state for a specific building (called when it is removed).
func clear_hover_for_building(building: Entity_RangedBuilding) -> void:
  if _hovered_ranged_building == building:
    _hovered_ranged_building.on_mouse_exit()
    _hovered_ranged_building = null
    MyLogger.debug("HoverController", "Cleared hover state for removed building")


## Clear hover state for a specific entity (called when it is removed).
func clear_hover_for_entity(entity: Node3D) -> void:
  if _hovered_entity == entity:
    _hide_entity_unit_frame(_hovered_entity)
    _hovered_entity = null


## Hide the building tooltip if it is currently showing the given building.
func clear_tooltip_for_building(building: Entity_RangedBuilding) -> void:
  if _building_tooltip and _building_tooltip.visible and _building_tooltip.current_building == building:
    _building_tooltip.hide_tooltip()
    MyLogger.debug("HoverController", "Hid tooltip for removed building")


## Walks up the parent chain from node to find a node with "health_component" metadata.
## Returns the Component_Health, or null if none is found.
func _find_health_component(node: Node) -> Component_Health:
  var current: Node = node
  while current != null:
    if current.has_meta("health_component"):
      return current.get_meta("health_component") as Component_Health
    current = current.get_parent()
  return null


## Show the unit frame on the health component of a node, if it has one.
func _show_entity_unit_frame(entity: Node3D) -> void:
  if entity == null:
    return
  var health := _find_health_component(entity)
  if health:
    health.show_unit_frame()


## Hide the unit frame on the health component of a node, if it has one.
func _hide_entity_unit_frame(entity: Node3D) -> void:
  if entity == null or not is_instance_valid(entity):
    return
  var health := _find_health_component(entity)
  if health:
    health.hide_unit_frame()
