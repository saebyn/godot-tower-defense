"""
# Attack.gd

This script handles the attack logic for an enemy character.
It checks if the target is valid and applies damage if possible.
The attack has a cooldown to prevent continuous damage application.

Attack effects are configured by adding a child node that extends BaseAttackEffect.
The Attack component will automatically detect and use any child attack effect.
"""
extends Node
class_name Attack

enum AttackResult {
  SUCCESS,
  ON_COOLDOWN,
  INVALID_TARGET
}

@onready var attack_timer: Timer = $AttackTimer

@export var damage_amount: int = 10
@export var damage_cooldown: float = 1.0
@export var show_attack_effects: bool = true
@export var effect_parameter_overrides: Dictionary = {}

var is_on_cooldown: bool = false
var current_target: Node = null
var attack_effect: BaseAttackEffect = null

func _ready():
	# Find child attack effect
	_find_attack_effect()


func perform_attack(target: Node) -> AttackResult:
  current_target = target
  if not is_on_cooldown:
    # check to see if the target has a child node named "Health"
    # TODO consider finding the node using metadata
    if target.has_node("Health"):
      var health = target.get_node("Health")
      if health is Health:
        # Show attack effect before applying damage
        if show_attack_effects and attack_effect:
          _show_attack_effect(target)
        
        health.take_damage(damage_amount)
      else:
        return AttackResult.INVALID_TARGET
    else:
      return AttackResult.INVALID_TARGET
    # Start cooldown
    is_on_cooldown = true
    attack_timer.start(damage_cooldown)
    return AttackResult.SUCCESS
  return AttackResult.ON_COOLDOWN

func _find_attack_effect():
  """
  Find a child node that extends BaseAttackEffect to use as the attack effect.
  """
  for child in get_children():
    if child is BaseAttackEffect:
      attack_effect = child
      break

func _show_attack_effect(target: Node):
  """
  Triggers the child attack effect to play from this attack to the target.
  """
  if not attack_effect:
    return
  
  # Get positions - use parent's position as source since Attack is a Node, not Node3D
  var from_position = Vector3.ZERO
  if get_parent() and get_parent() is Node3D:
    from_position = get_parent().global_position
  
  var to_position = Vector3.ZERO
  if target is Node3D:
    to_position = target.global_position
  
  # Apply parameter overrides to the attack effect
  if not effect_parameter_overrides.is_empty():
    attack_effect._apply_parameters(effect_parameter_overrides)
  
  # Play the effect
  attack_effect.play_effect(from_position, to_position)

func cancel():
  is_on_cooldown = false
  attack_timer.stop()
  current_target = null

func _on_AttackTimer_timeout():
  is_on_cooldown = false
