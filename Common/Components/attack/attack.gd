# Attack.gd
# This script handles the attack logic for an enemy character.
# It checks if the target is valid and applies damage if possible.
# The attack has a cooldown to prevent continuous damage application.
extends Node
class_name Attack

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
@export var damage_amount: int = 10
@export var damage_cooldown: float = 1.0
@export var damage_source: String = "unknown" ## Source identifier for damage tracking

@export_group("Effects")
@export var hit_sound: AudioManager.SoundEffect = AudioManager.SoundEffect.PLAYER_ATTACK_HIT
@export var audio_player: AudioStreamPlayer


var is_on_cooldown: bool = false

func _ready():
  # Register this component in parent's metadata for discovery
  if get_parent():
    get_parent().set_meta("attack_component", self)

func perform_attack(target: Node) -> AttackResult:
  if not is_on_cooldown:
    # Find Health component via metadata
    var health = null
    if target.has_meta("health_component"):
      health = target.get_meta("health_component")
    
    if health and health is Health:
      health.take_damage(damage_amount, damage_source)
      if audio_player:
        AudioManager.play_sound(audio_player, hit_sound)
      # Start cooldown
      is_on_cooldown = true
      attack_timer.start(damage_cooldown)
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