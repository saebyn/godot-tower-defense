class_name Entity_BuffObstacle
extends Entity_RangedObstacle

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
    super.place(navigation_region)
    if buff_timer:
        buff_timer.start()

func _apply_buffs():
    var obstacles := get_tree().get_nodes_in_group(Entity_PlaceableObstacle.OBSTACLE_GROUP)
    for obstacle in obstacles:
        if obstacle == self:
            continue
        if not is_instance_valid(obstacle):
            continue
        var distance := global_position.distance_to(obstacle.global_position)
        if distance <= effect_range:
            _apply_buff_to_obstacle(obstacle)

func _apply_buff_to_obstacle(obstacle: Entity_PlaceableObstacle) -> void:
    if obstacle.has_method("receive_buff"):
        obstacle.receive_buff(buff_type, buff_amount, self.get_instance_id(), buff_interval)