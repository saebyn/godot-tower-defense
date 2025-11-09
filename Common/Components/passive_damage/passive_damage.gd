@tool
extends Area3D
class_name Component_PassiveDamage

## Deals damage to enemies that enter/stay in contact with this area.
## Useful for spike traps, fire patches, barbed wire, etc.
##
## Usage: Add as child node to an obstacle, configure damage settings,
## and add a CollisionShape3D child to define the damage area.

signal damage_dealt(target: Node, damage: int)

@export_group("Damage Settings")
@export var damage_amount: int = 10 ## Damage dealt per hit
@export var damage_cooldown: float = 1.0 ## Cooldown between damage ticks per enemy
@export var damage_source: String = "passive_damage" ## Source identifier for tracking
@export var target_group: String = "enemies" ## Which group to damage

@export_group("Audio")
@export var enable_sound: bool = false ## Enable damage sound effects
@export var damage_sound: AudioManager.SoundEffect = AudioManager.SoundEffect.PLAYER_ATTACK_HIT
@export var audio_player: AudioStreamPlayer

var _enemy_cooldowns: Dictionary = {} ## Maps enemy -> time until next damage
var _enemies_in_area: Array[Node] = []


func _ready():
  # Configure area to detect bodies on layer 4 (enemies)
  collision_mask = 4
  monitoring = true
  monitorable = false
  
  body_entered.connect(_on_body_entered)
  body_exited.connect(_on_body_exited)
  
  # Register in parent metadata for discovery
  if get_parent():
    get_parent().set_meta("passive_damage_component", self)
  
  Logger.debug("PassiveDamage", "PassiveDamage component initialized")


func _process(delta: float):
  if Engine.is_editor_hint():
    return
  
  # Update cooldowns for all enemies
  var enemies_to_remove = []
  for enemy in _enemy_cooldowns.keys():
    if not is_instance_valid(enemy):
      enemies_to_remove.append(enemy)
      continue
    
    _enemy_cooldowns[enemy] -= delta
    if _enemy_cooldowns[enemy] <= 0:
      _try_damage_enemy(enemy)
  
  # Cleanup invalid enemies
  for enemy in enemies_to_remove:
    _enemy_cooldowns.erase(enemy)


func _on_body_entered(body: Node):
  if Engine.is_editor_hint():
    return
  
  if body.is_in_group(target_group):
    _enemies_in_area.append(body)
    Logger.trace("PassiveDamage", "Enemy entered damage area: %s" % body.name)
    _try_damage_enemy(body)


func _on_body_exited(body: Node):
  if Engine.is_editor_hint():
    return
  
  if body in _enemies_in_area:
    _enemies_in_area.erase(body)
    Logger.trace("PassiveDamage", "Enemy exited damage area: %s" % body.name)
  
  if body in _enemy_cooldowns:
    _enemy_cooldowns.erase(body)


func _try_damage_enemy(enemy: Node):
  # Check if enemy still valid and not on cooldown
  if not is_instance_valid(enemy):
    return
  
  if enemy in _enemy_cooldowns and _enemy_cooldowns[enemy] > 0:
    return
  
  # Deal damage via Health component
  var health = null
  if enemy.has_meta("health_component"):
    health = enemy.get_meta("health_component")
  
  if health and health is Component_Health:
    health.take_damage(damage_amount, damage_source)
    _enemy_cooldowns[enemy] = damage_cooldown
    damage_dealt.emit(enemy, damage_amount)
    Logger.debug("PassiveDamage", "Dealt %d damage to %s" % [damage_amount, enemy.name])
    
    if enable_sound and audio_player:
      AudioManager.play_sound(audio_player, damage_sound)


func get_enemies_in_area() -> Array[Node]:
  return _enemies_in_area.duplicate()


func is_enemy_on_cooldown(enemy: Node) -> bool:
  return enemy in _enemy_cooldowns and _enemy_cooldowns[enemy] > 0
