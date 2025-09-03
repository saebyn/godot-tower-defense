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

enum AttackEffectType {
  NONE,
  BULLET,
  FIREBALL,
  MAGIC_SPARKLES,
  LASER_BEAM
}

@onready var attack_timer: Timer = $AttackTimer

@export var damage_amount: int = 10
@export var damage_cooldown: float = 1.0
@export var attack_effect_type: AttackEffectType = AttackEffectType.BULLET
@export var show_attack_effects: bool = true

var is_on_cooldown: bool = false
var current_target: Node = null

# Preload attack effect scenes
var attack_effect_scenes = {
  AttackEffectType.BULLET: preload("res://Common/Effects/attack_effects/bullet_attack_effect.tscn"),
  AttackEffectType.FIREBALL: preload("res://Common/Effects/attack_effects/fireball_attack_effect.tscn"),
  AttackEffectType.MAGIC_SPARKLES: preload("res://Common/Effects/attack_effects/magic_sparkles_attack_effect.tscn"),
  AttackEffectType.LASER_BEAM: preload("res://Common/Effects/attack_effects/laser_beam_attack_effect.tscn")
}


func perform_attack(target: Node) -> AttackResult:
  current_target = target
  if not is_on_cooldown:
    # check to see if the target has a child node named "Health"
    # TODO consider finding the node using metadata
    if target.has_node("Health"):
      var health = target.get_node("Health")
      if health is Health:
        # Show attack effect before applying damage
        if show_attack_effects and attack_effect_type != AttackEffectType.NONE:
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
  if not attack_effect_scenes.has(attack_effect_type):
    return
  
  var effect_scene = attack_effect_scenes[attack_effect_type]
  if not effect_scene:
    return
  
  var effect_instance = effect_scene.instantiate()
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
  
  # Play the effect
  if effect_instance.has_method("play_effect"):
    effect_instance.play_effect(from_position, to_position)

func cancel():
  is_on_cooldown = false
  attack_timer.stop()
  current_target = null

func _on_AttackTimer_timeout():
  is_on_cooldown = false
