extends Node
class_name Component_Health

## Opacity applied when HP is at or above the high-health threshold (nearly invisible)
const HIGH_HP_OPACITY: float = 0.10
## Maximum opacity, applied at or below the low-health threshold
const FULL_OPACITY: float = 1.0
## HP ratio above which the bar fades to low opacity (becomes more transparent)
const HIGH_HP_THRESHOLD: float = 0.8
## HP ratio at or below which the bar is always fully opaque
const LOW_HP_THRESHOLD: float = 0.3

## Health bar fill colors keyed to zombie/entity type themes (Visual Style Guide)
const COLOR_ZOMBIE_STANDARD: Color = Color(0.478, 0.608, 0.463, 1.0) # desaturated green #7A9B76
const COLOR_ZOMBIE_FAST: Color = Color(0.788, 0.365, 0.310, 1.0) # warm red/orange #C95D4F
const COLOR_ZOMBIE_TANK: Color = Color(0.420, 0.447, 0.502, 1.0) # cool gray #6B7280
const COLOR_SURVIVOR: Color = Color(0.949, 0.655, 0.353, 1.0) # orange accent #F2A75A
const COLOR_DEFAULT: Color = Color(0.349, 0.431, 0.286, 1.0) # zombie_flesh from palette

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
## When false the health bar sprite is hidden entirely (health is still tracked).
@export var show_health_bar: bool = true
## Override the health bar fill color. Requires use_custom_bar_color = true.
@export var bar_color: Color = Color(0.0, 0.0, 0.0, 0.0)
## When true, bar_color is used instead of automatic type-based color detection.
@export var use_custom_bar_color: bool = false

@export_group("SFX Settings")
@export var hit_sound: Resource_SoundEffect.SoundEffect = Resource_SoundEffect.SoundEffect.DEFAULT
@export var death_sound: Resource_SoundEffect.SoundEffect = Resource_SoundEffect.SoundEffect.DEFAULT
@export var audio_player: AudioStreamPlayer3D


@onready var health_bar := $SubViewportContainer/SubViewport/VBoxContainer/BarOverlay/HealthBar
@onready var health_label := $SubViewportContainer/SubViewport/VBoxContainer/BarOverlay/HealthLabel
@onready var background := $SubViewportContainer/SubViewport/Background
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
  
  sprite.visible = (not disabled) and show_health_bar

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

  var hp_ratio: float = float(hitpoints) / float(max_hitpoints) if max_hitpoints > 0 else 0.0

  # Apply fill color, lerping toward saturated red as HP drops
  var base_color := _get_effective_bar_color()
  var danger_color := Color(0.85, 0.10, 0.10, 1.0) # vivid red
  # Color starts shifting at 60% HP and is fully red at 0%
  var color_lerp_weight: float = clampf(1.0 - (hp_ratio / 0.6), 0.0, 1.0)
  # Increase saturation as well: convert to HSV, boost saturation, convert back
  var lerped := base_color.lerp(danger_color, color_lerp_weight)
  if _bar_fill_style:
    _bar_fill_style.bg_color = lerped

  # Compute transparency using three zones:
  #   hp >= HIGH_HP_THRESHOLD : faded (HIGH_HP_OPACITY)
  #   hp <= LOW_HP_THRESHOLD  : fully opaque (FULL_OPACITY)
  #   between thresholds      : linear interpolation
  var target_alpha: float
  if hp_ratio >= HIGH_HP_THRESHOLD:
    target_alpha = HIGH_HP_OPACITY
  elif hp_ratio <= LOW_HP_THRESHOLD:
    target_alpha = FULL_OPACITY
  else:
    var lerp_weight: float = (hp_ratio - LOW_HP_THRESHOLD) / (HIGH_HP_THRESHOLD - LOW_HP_THRESHOLD)
    target_alpha = lerp(FULL_OPACITY, HIGH_HP_OPACITY, lerp_weight)

  # Modulate the bar and background individually inside the SubViewport.
  # Sprite3D.modulate is left at full opacity so the label (baked into the
  # same SubViewport texture) is never dimmed — it stays fully readable.
  health_bar.modulate.a = target_alpha
  background.modulate.a = target_alpha

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
