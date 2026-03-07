extends Node
class_name Component_Health

## Opacity applied when HP is at or above the full-health threshold
const HIGH_HP_OPACITY: float = 0.35
## Opacity applied when HP drops below the low-health threshold
const FULL_OPACITY: float = 1.0
## HP ratio above which the bar fades to high-opacity
const HIGH_HP_THRESHOLD: float = 0.8

## Health bar fill colors keyed to zombie/entity type themes (Visual Style Guide)
const COLOR_ZOMBIE_STANDARD: Color = Color(0.478, 0.608, 0.463, 1.0)  # desaturated green #7A9B76
const COLOR_ZOMBIE_FAST: Color = Color(0.788, 0.365, 0.310, 1.0)      # warm red/orange #C95D4F
const COLOR_ZOMBIE_TANK: Color = Color(0.420, 0.447, 0.502, 1.0)      # cool gray #6B7280
const COLOR_SURVIVOR: Color = Color(0.949, 0.655, 0.353, 1.0)         # orange accent #F2A75A
const COLOR_DEFAULT: Color = Color(0.349, 0.431, 0.286, 1.0)          # zombie_flesh from palette

@export_group("Health Settings")
@export var hitpoints: int = 100
@export var max_damage_per_hit: float = INF
@export var disabled: bool:
  get:
    return disabled
  set(value):
    disabled = value
    _update_display()

@export_group("Visual Settings")
## Override the health bar fill color. Requires use_custom_bar_color = true.
@export var bar_color: Color = Color(0.0, 0.0, 0.0, 0.0)
## When true, bar_color is used instead of automatic type-based color detection.
@export var use_custom_bar_color: bool = false

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

## StyleBoxFlat used to apply fill color to the health bar (created once in _ready)
var _bar_fill_style: StyleBoxFlat

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

  # Create a reusable StyleBoxFlat for bar fill color (avoids allocating per update)
  _bar_fill_style = StyleBoxFlat.new()
  health_bar.add_theme_stylebox_override("fill", _bar_fill_style)

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

  _update_health_bar_visuals()

## Determine the fill color for the health bar based on the entity type.
## Returns bar_color if use_custom_bar_color is true, otherwise infers from parent entity type.
func _get_effective_bar_color() -> Color:
  if use_custom_bar_color:
    return bar_color

  var parent = get_parent()
  if not parent:
    return COLOR_DEFAULT

  # Survivors use the orange accent color
  if parent.is_in_group("survivors"):
    return COLOR_SURVIVOR

  # Use enemy_type string to identify zombie sub-types
  if "enemy_type" in parent:
    var type: String = str(parent.enemy_type).to_lower()
    if "fast" in type:
      return COLOR_ZOMBIE_FAST
    if "tank" in type:
      return COLOR_ZOMBIE_TANK
    # Any other enemy is treated as standard zombie
    return COLOR_ZOMBIE_STANDARD

  return COLOR_DEFAULT

## Update health bar fill color and sprite transparency based on current HP ratio.
func _update_health_bar_visuals():
  if not is_node_ready():
    return

  # Apply fill color
  var fill_color := _get_effective_bar_color()
  if _bar_fill_style:
    _bar_fill_style.bg_color = fill_color

  # Compute transparency: fade bar toward HIGH_HP_OPACITY when HP is healthy
  var hp_ratio: float = float(hitpoints) / float(max_hitpoints) if max_hitpoints > 0 else 0.0
  var target_alpha: float = HIGH_HP_OPACITY if hp_ratio >= HIGH_HP_THRESHOLD else lerp(FULL_OPACITY, HIGH_HP_OPACITY, hp_ratio / HIGH_HP_THRESHOLD)

  sprite.modulate.a = target_alpha
  # Keep label readable — never drop below 60% opacity
  health_label.modulate.a = maxf(target_alpha, 0.6)

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
