# Attack.gd
# This script handles the attack logic for an enemy character.
# It checks if the target is valid and applies damage if possible.
# The attack has a cooldown to prevent continuous damage application.
extends Node
class_name Component_Attack

# Emitted immediately after a successful attack when cooldown begins.
signal cooldown_started
# Emitted when the attack cooldown completes or is canceled early.
signal cooldown_ended

enum AttackResult {
  SUCCESS,
  ON_COOLDOWN,
  INVALID_TARGET
}

@onready var attack_timer: Timer = $AttackTimer

@export_group("Damage Settings")
@export var damage_amount: float = 10.0 ## Amount of damage per attack
@export var attack_speed: float = 1.0 ## How many attacks per second
@export var damage_source: String = "unknown" ## Source identifier for damage tracking

@export_group("Effects")
@export var hit_sound: Resource_SoundEffect.SoundEffect = Resource_SoundEffect.SoundEffect.DEFAULT
@export var audio_player: AudioStreamPlayer3D


var is_on_cooldown: bool = false

func _ready():
  # Register this component in parent's metadata for discovery
  if get_parent():
    get_parent().set_meta("attack_component", self)

  if not audio_player:
    MyLogger.warn("Attack", "No AudioStreamPlayer assigned for Attack effect sounds.")


func perform_attack(target: Node) -> AttackResult:
  if not is_on_cooldown:
    # Find Health component via metadata
    var health = null
    if target.has_meta("health_component"):
      health = target.get_meta("health_component")
    
    if health and health is Component_Health:
      health.take_damage(damage_amount, damage_source)
      # Play zombie attack sound for zombie attacks, or the configured hit_sound otherwise
      var sound_to_play = hit_sound
      if damage_source == "zombie":
        sound_to_play = Resource_SoundEffect.SoundEffect.ZOMBIE_ATTACK
      
      if audio_player and sound_to_play != Resource_SoundEffect.SoundEffect.NONE:
        AudioManager.play_sound(audio_player, sound_to_play)
      
      # Start cooldown
      is_on_cooldown = true
      # if attack_speed is 10 attacks/second,
      # then the attack cooldown is 0.1 seconds/attack
      attack_timer.start(1.0 / attack_speed)
      cooldown_started.emit()
      return AttackResult.SUCCESS
    else:
      return AttackResult.INVALID_TARGET
   
  return AttackResult.ON_COOLDOWN

func cancel():
  attack_timer.stop()
  _on_AttackTimer_timeout()

func _on_AttackTimer_timeout():
  is_on_cooldown = false
  cooldown_ended.emit()