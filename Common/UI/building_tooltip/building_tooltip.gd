extends Control
class_name UI_BuildingTooltip

## Tooltip that displays building stats and active buffs when hovering over buildings
## Shows base stats and buffed stats with visual indicators for stat increases

# UI elements
var panel: PanelContainer
var content_container: VBoxContainer
var name_label: Label
var separator: HSeparator
var stats_container: VBoxContainer
var buffs_label: Label

# Data
var current_building: Entity_PlaceableBuilding = null

# Positioning
const OFFSET_FROM_MOUSE = Vector2(20, 20)
const SCREEN_MARGIN = 10

# Colors from COLOR_PALETTE.md
const COLOR_BUFFED = Color(0.18, 0.8, 0.44, 1.0) # Economy Green (#2ECC71)
const COLOR_BASE = Color(0.6, 0.6, 0.6, 1.0) # Gray for base values
const COLOR_TEXT = Color(0.95, 0.9, 0.8, 1.0) # Cream/Beige

func _ready() -> void:
  _setup_ui()
  visible = false

func _setup_ui() -> void:
  # Create main panel
  panel = PanelContainer.new()
  panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(panel)
  
  # Panel will use default theme automatically
  
  # Create margin container for padding
  var margin = MarginContainer.new()
  margin.add_theme_constant_override("margin_left", 8)
  margin.add_theme_constant_override("margin_right", 8)
  margin.add_theme_constant_override("margin_top", 6)
  margin.add_theme_constant_override("margin_bottom", 6)
  panel.add_child(margin)
  
  # Create main content container
  content_container = VBoxContainer.new()
  content_container.add_theme_constant_override("separation", 4)
  margin.add_child(content_container)
  
  # Name label (large, bold)
  name_label = Label.new()
  name_label.add_theme_font_size_override("font_size", 16)
  content_container.add_child(name_label)
  
  # Separator line
  separator = HSeparator.new()
  content_container.add_child(separator)
  
  # Stats container
  stats_container = VBoxContainer.new()
  stats_container.add_theme_constant_override("separation", 2)
  content_container.add_child(stats_container)
  
  # Buffs info label (initially hidden)
  buffs_label = Label.new()
  buffs_label.add_theme_font_size_override("font_size", 12)
  buffs_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
  content_container.add_child(buffs_label)

## Show tooltip for the given building at mouse position
func show_tooltip(building: Entity_PlaceableBuilding, mouse_pos: Vector2) -> void:
  current_building = building
  update_tooltip_content()
  visible = true
  position_tooltip(mouse_pos)

## Hide the tooltip
func hide_tooltip() -> void:
  visible = false
  current_building = null

## Update tooltip content based on current building
func update_tooltip_content() -> void:
  if not current_building:
    return
  
  var info = current_building.get_tooltip_info()
  
  # Update name
  name_label.text = info.name
  
  # Clear existing stats
  for child in stats_container.get_children():
    child.queue_free()
  
  # Add each stat row
  for stat_name in info.base_stats.keys():
    var base = info.base_stats[stat_name]
    var current_val = info.current_stats[stat_name]
    var is_buffed = abs(current_val - base) > 0.001
    
    _add_stat_row(stat_name, base, current_val, is_buffed)
  
  # Update buff sources info
  var sources = current_building.get_active_buff_sources()
  if not sources.is_empty():
    buffs_label.visible = true
    buffs_label.text = "\n📡 Active Buffs:"
    for source in sources:
      var buff_name = _get_buff_type_name(source.type)
      var percent = source.amount * 100
      buffs_label.text += "\n  • %s (%+.0f%% %s)" % [source.name, percent, buff_name]
  else:
    buffs_label.visible = false

## Add a single stat row to the stats container
func _add_stat_row(stat_name: String, base_value, current_value, is_buffed: bool) -> void:
  var row = HBoxContainer.new()
  row.add_theme_constant_override("separation", 4)
  
  # Stat name label
  var label = Label.new()
  label.text = _format_stat_name(stat_name) + ":"
  label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(label)
  
  # Value label with rich text for color coding
  var value_label = RichTextLabel.new()
  value_label.bbcode_enabled = true
  value_label.fit_content = true
  value_label.scroll_active = false
  value_label.custom_minimum_size = Vector2(120, 20)
  value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
  
  if is_buffed:
    # Show: "10 → 15 (+50%)"
    var percent = ((current_value / base_value - 1.0) * 100) if base_value != 0 else 0
    value_label.text = "[color=#999999]%s[/color] → [b][color=#2ECC71]%s[/color][/b] [color=#2ECC71](+%.0f%%)[/color]" % [
      _format_value(base_value),
      _format_value(current_value),
      percent
    ]
  else:
    value_label.text = _format_value(current_value)
  
  row.add_child(value_label)
  stats_container.add_child(row)

## Position tooltip near mouse with edge detection
func position_tooltip(mouse_pos: Vector2) -> void:
  # Wait for panel to calculate its size
  await get_tree().process_frame
  
  var target_pos = mouse_pos + OFFSET_FROM_MOUSE
  var viewport_size = get_viewport_rect().size
  var tooltip_size = panel.size
  
  # Prevent going off right edge
  if target_pos.x + tooltip_size.x > viewport_size.x - SCREEN_MARGIN:
    target_pos.x = mouse_pos.x - tooltip_size.x - OFFSET_FROM_MOUSE.x
  
  # Prevent going off bottom edge
  if target_pos.y + tooltip_size.y > viewport_size.y - SCREEN_MARGIN:
    target_pos.y = viewport_size.y - tooltip_size.y - SCREEN_MARGIN
  
  # Prevent going off left edge
  if target_pos.x < SCREEN_MARGIN:
    target_pos.x = SCREEN_MARGIN
  
  # Prevent going off top edge
  if target_pos.y < SCREEN_MARGIN:
    target_pos.y = SCREEN_MARGIN
  
  position = target_pos

## Update tooltip position to follow mouse
func _process(_delta: float) -> void:
  if visible and current_building:
    var mouse_pos = get_viewport().get_mouse_position()
    position_tooltip(mouse_pos)

## Format stat name for display
func _format_stat_name(stat_name: String) -> String:
  match stat_name:
    "attack_speed":
      return "Attack Speed"
    "damage":
      return "Damage"
    "range":
      return "Range"
    "health":
      return "Health"
    _:
      # Fallback: capitalize first letter
      return stat_name.capitalize()

## Format value for display
func _format_value(value) -> String:
  if value is float:
    return "%.1f" % value
  elif value is int:
    return str(value)
  else:
    return str(value)

## Get human-readable buff type name
func _get_buff_type_name(buff_type: Entity_BuffBuilding.BuffType) -> String:
  match buff_type:
    Entity_BuffBuilding.BuffType.ATTACK_SPEED:
      return "speed"
    Entity_BuffBuilding.BuffType.DAMAGE:
      return "damage"
    Entity_BuffBuilding.BuffType.RANGE:
      return "range"
    _:
      return "stat"
