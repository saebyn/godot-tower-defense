"""
# Attack.gd

This script handles the attack logic for an enemy character.
It checks if the target is valid and applies damage if possible.
The attack has a cooldown to prevent continuous damage application.
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
@export var selected_effect_name: String = "Bullet"
@export var effect_parameter_overrides: Dictionary = {}
@export var attack_effects_database: AttackEffectDatabase

var is_on_cooldown: bool = false
var current_target: Node = null

# Load default effects database if none specified
func _ready():
	if not attack_effects_database:
		# Create the default database dynamically
		attack_effects_database = preload("res://Common/Effects/attack_effects/default_attack_effects.gd").create_default_database()


func perform_attack(target: Node) -> AttackResult:
  current_target = target
  if not is_on_cooldown:
    # check to see if the target has a child node named "Health"
    # TODO consider finding the node using metadata
    if target.has_node("Health"):
      var health = target.get_node("Health")
      if health is Health:
        # Show attack effect before applying damage
        if show_attack_effects and selected_effect_name != "None":
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

func _show_attack_effect(target: Node):
  """
  Creates and plays the selected attack effect from this attack to the target.
  """
  if not attack_effects_database:
    return
  
  var effect_resource = attack_effects_database.get_effect_by_name(selected_effect_name)
  if not effect_resource or not effect_resource.effect_scene:
    return
  
  var effect_instance = effect_resource.effect_scene.instantiate()
  if not effect_instance:
    return
  
  # Add effect to the scene tree (to the parent's parent to avoid it being a child of this attack)
  var scene_root = get_tree().current_scene
  scene_root.add_child(effect_instance)
  
  # Get positions - use parent's position as source since Attack is a Node, not Node3D
  var from_position = Vector3.ZERO
  if get_parent() and get_parent() is Node3D:
    from_position = get_parent().global_position
  
  var to_position = Vector3.ZERO
  if target is Node3D:
    to_position = target.global_position
  
  # Combine default parameters with instance overrides
  var final_parameters = effect_resource.effect_parameters.duplicate()
  for param_name in effect_parameter_overrides:
    final_parameters[param_name] = effect_parameter_overrides[param_name]
  
  # Play the effect with combined parameters
  if effect_instance.has_method("play_effect"):
    effect_instance.play_effect(from_position, to_position, final_parameters)

func cancel():
  is_on_cooldown = false
  attack_timer.stop()
  current_target = null

func _on_AttackTimer_timeout():
  is_on_cooldown = false
