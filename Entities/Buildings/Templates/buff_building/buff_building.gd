class_name Entity_BuffBuilding
extends Entity_RangedBuilding

enum BuffType {
  ATTACK_SPEED, # aka cooldown reduction
  DAMAGE,
  RANGE
}

@export var buff_type: BuffType = BuffType.ATTACK_SPEED
@export_range(-1.0, 1.0, 0.01) var buff_amount: float = 0.1 # e.g., 0.1 for 10% increase
@export var buff_interval: float = 1.0 # seconds between applying buffs


var buff_timer: Timer

func _ready():
  super._ready()

  # Set up buff timer
  buff_timer = Timer.new()
  buff_timer.wait_time = buff_interval
  buff_timer.one_shot = false
  # Only autostart when placed, not in preview mode
  buff_timer.autostart = not is_preview
  buff_timer.timeout.connect(_apply_buffs)
  add_child(buff_timer)

func place(navigation_region: NavigationRegion3D) -> void:
  var was_preview := is_preview
  super.place(navigation_region)
  if buff_timer and was_preview and not is_preview:
    buff_timer.start()

func _apply_buffs():
  var buildings := get_tree().get_nodes_in_group(Entity_PlaceableBuilding.BUILDING_GROUP)
  for building in buildings:
    if building == self:
      continue
    if not is_instance_valid(building):
      continue
    var distance := global_position.distance_to(building.global_position)
    if distance <= effect_range:
      _apply_buff_to_building(building)

func _apply_buff_to_building(building: Entity_PlaceableBuilding) -> void:
  if building.has_method("receive_buff"):
    building.receive_buff(buff_type, buff_amount, self.get_instance_id(), buff_interval)