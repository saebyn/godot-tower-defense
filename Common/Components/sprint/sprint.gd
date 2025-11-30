## Sprint Component
## Enables sprinting behavior for entities, allowing them to temporarily increase their movement speed.
class_name Component_Sprint
extends Node

@export var sprint_speed_multiplier: float = 2.0 ## Multiplier applied to movement speed when sprinting
@export var sprint_chance: float = 0.3 ## Chance to initiate a sprint per decision check (0.0 to 1.0)
@export var sprint_duration: float = 2.0 ## Duration of each sprint in seconds
@export var sprint_decision_interval: float = 5.0 ## Interval between sprint decision checks in seconds

var is_sprinting: bool = false
var original_speed: float = 0.0
var decision_timer: Timer

func _ready() -> void:
  decision_timer = Timer.new()
  decision_timer.wait_time = sprint_decision_interval
  decision_timer.one_shot = false
  decision_timer.autostart = true
  decision_timer.timeout.connect(_on_decision_timer_timeout)
  add_child(decision_timer)


func _on_decision_timer_timeout() -> void:
  if not is_sprinting and randf() < sprint_chance:
    _start_sprint()


func _start_sprint() -> void:
  MyLogger.debug("Sprint", "Entity %s is starting to sprint." % get_parent().name)
  is_sprinting = true
  original_speed = get_parent().movement_speed
  get_parent().movement_speed = original_speed * sprint_speed_multiplier
  await get_tree().create_timer(sprint_duration).timeout
  _end_sprint()


func _end_sprint() -> void:
  MyLogger.debug("Sprint", "Entity %s has ended sprinting." % get_parent().name)
  is_sprinting = false
  get_parent().movement_speed = original_speed