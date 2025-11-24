extends Node
class_name UI_DamageNumberManager

## Manages the pooling and display of damage numbers for performance
## Automatically connects to health components and currency signals

@export var damage_number_scene: PackedScene
@export var max_pool_size: int = 30 ## Maximum number of damage numbers to keep in pool
@export var initial_pool_size: int = 10 ## Initial number of damage numbers to create

var damage_number_pool: Array[UI_DamageNumber] = []
var active_damage_numbers: Array[UI_DamageNumber] = []

# Settings for accessibility
var damage_numbers_enabled: bool = true
var scrap_numbers_enabled: bool = true
var number_size_multiplier: float = 1.0

func _ready():
  # Load the damage number scene if not set
  if not damage_number_scene:
    damage_number_scene = load("res://Common/UI/damage_numbers/damage_number.tscn")
  
  # Create initial pool
  _initialize_pool()
  
  # Connect to CurrencyManager for scrap feedback
  if CurrencyManager:
    CurrencyManager.scrap_earned.connect(_on_scrap_earned)
  
  # Connect to settings if available
  if SettingsManager and SettingsManager.has_method("get_setting"):
    _load_settings()
    # Listen for setting changes if the signal exists
    if SettingsManager.has_signal("setting_changed"):
      SettingsManager.setting_changed.connect(_on_setting_changed)
  
  Logger.info("DamageNumberManager", "Initialized with pool size %d" % initial_pool_size)

func _initialize_pool():
  """Create the initial pool of damage number instances"""
  for i in range(initial_pool_size):
    var damage_number = damage_number_scene.instantiate() as UI_DamageNumber
    add_child(damage_number)
    damage_number_pool.append(damage_number)

func _load_settings():
  """Load settings from SettingsManager"""
  damage_numbers_enabled = SettingsManager.get_setting("damage_numbers_enabled", true)
  scrap_numbers_enabled = SettingsManager.get_setting("scrap_numbers_enabled", true)
  number_size_multiplier = SettingsManager.get_setting("number_size_multiplier", 1.0)

func _on_setting_changed(setting_name: String, new_value):
  """Update settings when they change"""
  match setting_name:
    "damage_numbers_enabled":
      damage_numbers_enabled = new_value
    "scrap_numbers_enabled":
      scrap_numbers_enabled = new_value
    "number_size_multiplier":
      number_size_multiplier = new_value

func show_damage(amount: int, world_position: Vector3, damage_type: UI_DamageNumber.NumberType = UI_DamageNumber.NumberType.DAMAGE_NORMAL):
  """Display a damage number at the specified position"""
  if not damage_numbers_enabled:
    return
  
  var damage_number = _get_or_create_damage_number()
  if damage_number:
    # Apply size multiplier
    damage_number.scale = Vector3.ONE * number_size_multiplier
    damage_number.display_damage(amount, world_position, damage_type)
    active_damage_numbers.append(damage_number)

func show_scrap_gain(amount: int, world_position: Vector3):
  """Display a scrap gain number at the specified position"""
  if not scrap_numbers_enabled:
    return
  
  var damage_number = _get_or_create_damage_number()
  if damage_number:
    # Apply size multiplier
    damage_number.scale = Vector3.ONE * number_size_multiplier
    damage_number.display_damage(amount, world_position, UI_DamageNumber.NumberType.SCRAP_GAIN)
    active_damage_numbers.append(damage_number)
  
  # Play scrap collection sound
  if AudioManager and AudioManager.has_method("play_sfx"):
    AudioManager.play_sfx("scrap_collect")

func _get_or_create_damage_number() -> UI_DamageNumber:
  """Get an available damage number from the pool or create a new one"""
  # First, try to find an inactive one in the pool
  for damage_number in damage_number_pool:
    if damage_number.is_available():
      return damage_number
  
  # If pool is not at max size, create a new one
  if damage_number_pool.size() < max_pool_size:
    var damage_number = damage_number_scene.instantiate() as UI_DamageNumber
    add_child(damage_number)
    damage_number_pool.append(damage_number)
    Logger.debug("DamageNumberManager", "Pool expanded to %d" % damage_number_pool.size())
    return damage_number
  
  # Pool is full and all are active, reuse the oldest active one
  if active_damage_numbers.size() > 0:
    var oldest = active_damage_numbers[0]
    oldest.deactivate()
    return oldest
  
  Logger.warn("DamageNumberManager", "Could not get damage number from pool")
  return null

func _return_to_pool(damage_number: UI_DamageNumber):
  """Return a damage number to the pool after use"""
  active_damage_numbers.erase(damage_number)

func _on_scrap_earned(amount: int):
  """Handle scrap earned signal - this is for future implementation
  where we might show scrap gain at currency UI location"""
  # For now, scrap numbers are shown at enemy death location
  # This could be extended to show at currency UI as well
  pass

func connect_to_health_component(health_component: Component_Health):
  """Connect to a health component's damaged signal"""
  if not health_component:
    return
  
  # Get the entity that owns this health component
  var entity = health_component.get_parent()
  if not entity:
    return
  
  # Connect to the damaged signal
  health_component.damaged.connect(func(amount: int, _hitpoints: int, _damage_source: String):
    if damage_numbers_enabled and entity:
      # Position above the entity
      var world_pos = entity.global_position + Vector3.UP * 2.0
      show_damage(amount, world_pos, UI_DamageNumber.NumberType.DAMAGE_NORMAL)
  )
  
  Logger.debug("DamageNumberManager", "Connected to health component on %s" % entity.name)

func connect_to_enemy(enemy: Node3D):
  """Connect to an enemy's health component and death signal"""
  # Find health component - first try metadata, then look for child
  var health_component = null
  if enemy.has_meta("health_component"):
    health_component = enemy.get_meta("health_component")
  else:
    # Fallback: search for Component_Health child
    for child in enemy.get_children():
      if child is Component_Health:
        health_component = child
        break
  
  if health_component:
    connect_to_health_component(health_component)
  
  # Connect to death for scrap display
  var scrap_reward = enemy.get("scrap_reward")
  if health_component and scrap_reward != null:
    health_component.died.connect(func(_damage_source: String):
      var reward = enemy.get("scrap_reward")
      if scrap_numbers_enabled and reward and reward > 0:
        var world_pos = enemy.global_position + Vector3.UP * 2.5
        show_scrap_gain(reward, world_pos)
    )
