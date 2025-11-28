extends Node
class_name Component_Health

@export var hitpoints: int = 100
@export var disabled: bool:
  get:
    return disabled
  set(value):
    disabled = value
    _update_display()

@export var show_damage_numbers: bool = true ## Whether to display floating damage numbers

@onready var health_bar := $SubViewportContainer/SubViewport/VBoxContainer/HealthBar
@onready var health_label := $SubViewportContainer/SubViewport/VBoxContainer/HealthLabel
@onready var subviewport := $SubViewportContainer/SubViewport
@onready var sprite := $Sprite3D

var max_hitpoints: int
var dead: bool = false

# Damage number pooling
var _damage_number_scene: PackedScene
var _damage_number_pool: Array[UI_DamageNumber] = []
const MAX_POOL_SIZE: int = 10
const DAMAGE_NUMBER_SCENE_PATH: String = "res://Common/UI/damage_numbers/damage_number.tscn"

signal died(damage_source: String)
signal damaged(amount: int, hitpoints: int, damage_source: String)

func take_damage(amount: int, damage_source: String = "unknown"):
  if disabled:
    return

  hitpoints -= amount
  damaged.emit(amount, hitpoints, damage_source)
  _update_display()
  
  # Show damage number
  if show_damage_numbers:
    _show_damage_number(amount, damage_source)
  
  if hitpoints <= 0:
    _die(damage_source)


func _ready():
  # Store the initial hitpoints as max_hitpoints
  max_hitpoints = hitpoints
  _update_display()
  subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  
  # Register this component in parent's metadata for discovery
  if get_parent():
    get_parent().set_meta("health_component", self)
  
  # Load damage number scene
  if show_damage_numbers:
    _load_damage_number_scene()

func _load_damage_number_scene():
  """Load the damage number scene for pooling"""
  if ResourceLoader.exists(DAMAGE_NUMBER_SCENE_PATH):
    _damage_number_scene = load(DAMAGE_NUMBER_SCENE_PATH)

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

  dead = true
  hitpoints = 0
  died.emit(damage_source)

func _show_damage_number(amount: int, damage_source: String = "unknown"):
  """Display a floating damage number above this entity"""
  if not _damage_number_scene:
    return
  
  var parent = get_parent()
  if not parent:
    return
  
  # Get or create damage number from pool
  var damage_number = _get_pooled_damage_number()
  if not damage_number:
    return
  
  # Position above the entity
  var world_pos = parent.global_position + Vector3.UP * 2.0
  
  # Determine damage type based on source
  var damage_type = UI_DamageNumber.NumberType.DAMAGE_NORMAL
  match damage_source:
    "fire", "flame":
      damage_type = UI_DamageNumber.NumberType.DAMAGE_FIRE
    "ice", "frost", "cold":
      damage_type = UI_DamageNumber.NumberType.DAMAGE_ICE
    "poison", "toxic":
      damage_type = UI_DamageNumber.NumberType.DAMAGE_POISON
    "critical", "crit":
      damage_type = UI_DamageNumber.NumberType.DAMAGE_CRITICAL
  
  damage_number.display_damage(amount, world_pos, damage_type)

func _get_pooled_damage_number() -> UI_DamageNumber:
  """Get an available damage number from pool or create new one"""
  # Try to find an inactive one in the pool
  for dn in _damage_number_pool:
    if dn.is_available():
      return dn
  
  # Create new if pool not full
  if _damage_number_pool.size() < MAX_POOL_SIZE:
    var new_dn = _damage_number_scene.instantiate() as UI_DamageNumber
    # Add to current scene to keep organized (not scene root)
    var current_scene = get_tree().current_scene
    if current_scene:
      current_scene.add_child(new_dn)
    else:
      get_tree().root.add_child(new_dn)
    _damage_number_pool.append(new_dn)
    return new_dn
  
  # Pool full - reuse oldest
  if not _damage_number_pool.is_empty():
    var oldest = _damage_number_pool[0]
    oldest.deactivate()
    return oldest
  
  return null
