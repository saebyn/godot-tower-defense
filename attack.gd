extends Node
class_name Attack

@onready var attack_timer: Timer = $AttackTimer

@export var damage_amount: int = 10
@export var damage_cooldown: float = 1.0
var attacking: bool = false
var current_target: Node = null


func perform_attack(target: Node):
  current_target = target
  if not attacking:
    attacking = true
    attack_timer.start(damage_cooldown)

func cancel():
  attacking = false
  attack_timer.stop()
  current_target = null

func _send_damage(target: Node, damage: int):
  # check to see if the target has a child node named "Health"
  # TODO consider finding the node using metadata
  if target.has_node("Health"):
    var health = target.get_node("Health")
    if health is Health:
      health.take_damage(damage)


func _on_AttackTimer_timeout():
  print("Attack timer timed out, attacking target.")
  _send_damage(current_target, damage_amount)
  attacking = false