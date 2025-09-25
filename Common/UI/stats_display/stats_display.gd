extends Control
class_name StatsDisplay

## UI component to display game statistics
## Shows enemy defeats, obstacle placements, and currency metrics

@onready var stats_label: RichTextLabel = $StatsLabel

func _ready():
  # Connect to the stats manager for real-time updates
  if StatsManager:
    StatsManager.stats_updated.connect(_update_display)
    # Initialize display with current stats
    _update_display()
  else:
    push_error("StatsManager not found! Make sure it's loaded as an autoload.")

func _update_display():
  if not stats_label:
    Logger.warn("StatsDisplay", "Stats label not found, cannot update display")
    return
  
  if not StatsManager:
    stats_label.text = "[color=red]StatsManager not available[/color]"
    return
  
  var stats = StatsManager.get_stats_summary()
  
  var text = "[center][b]Game Statistics[/b][/center]\n\n"
  
  # Enemy defeat stats
  text += "[b]Enemies Defeated[/b]\n"
  text += "Total: %d\n" % stats.enemies_defeated_total
  text += "By Hand: %d\n" % stats.enemies_defeated_by_hand
  
  if stats.enemies_defeated_by_type.size() > 0:
    text += "By Type:\n"
    for enemy_type in stats.enemies_defeated_by_type:
      text += "  %s: %d\n" % [enemy_type, stats.enemies_defeated_by_type[enemy_type]]
  
  text += "\n"
  
  # Obstacle placement stats
  text += "[b]Obstacles Placed[/b]\n"
  text += "Total: %d\n" % stats.obstacles_placed_total
  
  if stats.obstacles_placed_by_type.size() > 0:
    text += "By Type:\n"
    for obstacle_type in stats.obstacles_placed_by_type:
      text += "  %s: %d\n" % [obstacle_type, stats.obstacles_placed_by_type[obstacle_type]]
  
  text += "\n"
  
  # Currency stats  
  text += "[b]Currency[/b]\n"
  text += "Total Earned: %d\n" % stats.total_currency_earned
  text += "Max Held: %d\n" % stats.max_currency_held
  
  stats_label.text = text

## Toggle visibility of stats display
func toggle_visibility():
  visible = not visible