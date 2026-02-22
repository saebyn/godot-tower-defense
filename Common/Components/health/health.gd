extends Node
class_name Component_Health

@export_group("Health Settings")
@export var hitpoints: int = 100
@export var max_damage_per_hit: float = INF
@export var disabled: bool:
  get:
    return disabled
  set(value):
    disabled = value
    _update_display()

@export_group("SFX Settings")
@export var hit_sound: Resource_SoundEffect.SoundEffect = Resource_SoundEffect.SoundEffect.DEFAULT
@export var death_sound: Resource_SoundEffect.SoundEffect = Resource_SoundEffect.SoundEffect.DEFAULT
@export var audio_player: AudioStreamPlayer3D


@onready var health_bar := $SubViewportContainer/SubViewport/VBoxContainer/HealthBar
@onready var health_label := $SubViewportContainer/SubViewport/VBoxContainer/HealthLabel
@onready var subviewport := $SubViewportContainer/SubViewport
@onready var sprite := $Sprite3D

var max_hitpoints: int
var dead: bool = false

var damage_numbers: Component_DamageNumbers

signal died(damage_source: String)
signal damaged(amount: float, hitpoints: int, damage_source: String)

func take_damage(amount: float, damage_source: String = "unknown"):
  if disabled:
    return

  assert(amount >= 0, "Damage amount cannot be negative.")

  var damage = floori(min(amount, max_damage_per_hit))
  hitpoints = max(hitpoints - damage, 0)
  damaged.emit(damage, hitpoints, damage_source)
  _update_display()
  
  # Show damage number via damage numbers component if available
  if damage_numbers:
      damage_numbers.show_damage(damage, damage_source)

  # Play hit sound if audio player is assigned
  if audio_player:
    var pitch_override = _get_voice_pitch()
    AudioManager.play_sound(audio_player, hit_sound, pitch_override)
  
  assert(hitpoints >= 0, "Hitpoints should never be negative.")

  if hitpoints <= 0:
    _die(damage_source)


func _ready():
  # Store the initial hitpoints as max_hitpoints
  max_hitpoints = hitpoints
  _update_display()
  subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  
  # Register this component in parent's metadata for discovery
  var parent = get_parent()

  if not audio_player:
    MyLogger.warn("Health", "No AudioStreamPlayer assigned for Health effect sounds.")


  if parent:
    parent.set_meta("health_component", self )

    # Try to get damage numbers component if it exists
    if parent.has_meta("damage_numbers_component"):
      damage_numbers = parent.get_meta("damage_numbers_component")

func _update_display():
  if not is_node_ready():
    return
  
  sprite.visible = not disabled

  # Set up health display UI
  health_bar.max_value = max_hitpoints
  health_bar.value = hitpoints
  health_label.text = str(hitpoints) + " / " + str(max_hitpoints)

func _die(damage_source: String = "unknown"):
  if dead:
    return

  # Play death sound if audio player is assigned
  if audio_player:
    var pitch_override = _get_voice_pitch()
    AudioManager.play_sound(audio_player, death_sound, pitch_override)

  dead = true
  hitpoints = 0
  died.emit(damage_source)

## Get the voice pitch from parent if available (for survivors)
func _get_voice_pitch() -> Variant:
  var parent := get_parent()
  if parent and "voice_pitch" in parent and parent.voice_pitch != null:
    return parent.voice_pitch
  return null # No override
