# Attack.gd
# This script handles the attack logic for an enemy character.
# It checks if the target is valid and applies damage if possible.
# The attack has a cooldown to prevent continuous damage application.
extends Node
class_name Attack

signal cooldown_started
signal cooldown_ended

enum AttackResult {
  SUCCESS,
  ON_COOLDOWN,
  INVALID_TARGET
}

@onready var attack_timer: Timer = $AttackTimer

@export var damage_amount: int = 10
@export var damage_cooldown: float = 1.0
@export var damage_source: String = "unknown" ## Source identifier for damage tracking
var is_on_cooldown: bool = false

func perform_attack(target: Node) -> AttackResult:
  if not is_on_cooldown:
    # check to see if the target has a child node named "Health"
    # TODO consider finding the node using metadata
    if target.has_node("Health"):
      var health = target.get_node("Health")
      if health is Health:
        health.take_damage(damage_amount, damage_source)
      else:
        return AttackResult.INVALID_TARGET
    else:
      return AttackResult.INVALID_TARGET
    # Start cooldown
    is_on_cooldown = true
    attack_timer.start(damage_cooldown)
    cooldown_started.emit()
    return AttackResult.SUCCESS
  return AttackResult.ON_COOLDOWN

func cancel():
  attack_timer.stop()
  _on_AttackTimer_timeout()

func _on_AttackTimer_timeout():
  is_on_cooldown = false
  cooldown_ended.emit()