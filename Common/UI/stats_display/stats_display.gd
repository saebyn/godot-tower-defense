extends Control
class_name StatsDisplay

## UI component to display game statistics
## Shows enemy defeats, obstacle placements, and currency metrics

@onready var stats_label: RichTextLabel = $StatsLabel

func _ready():
  # Connect to the stats manager for real-time updates
  if StatsManager:
    StatsManager.stats_updated.connect(_update_display)
    StatsManager.stats_loaded.connect(_on_stats_loaded)
    StatsManager.stats_saved.connect(_on_stats_saved)
    # Initialize display with current stats
    _update_display()
  else:
    push_error("StatsManager not found! Make sure it's loaded as an autoload.")

func _on_stats_loaded():
  Logger.info("StatsDisplay", "Stats loaded from persistent storage")
  _update_display()

func _on_stats_saved():
  Logger.debug("StatsDisplay", "Stats saved to persistent storage")

func _update_display():
  if not stats_label:
    Logger.warn("StatsDisplay", "Stats label not found, cannot update display")
    return
  
  if not StatsManager:
    stats_label.text = "[color=red]StatsManager not available[/color]"
    return
  
  var stats = StatsManager.get_stats_summary()
  
  var text = "[center][b]Game Statistics[/b][/center]\n"
  
  # Persistence indicator
  if StatsManager.has_saved_stats():
    text += "[center][color=green][i]📊 Persistent stats across sessions[/i][/color][/center]\n\n"
  else:
    text += "[center][color=yellow][i]📊 Stats will be saved automatically[/i][/color][/center]\n\n"
  
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
  
  # Resource stats (scrap and XP)
  text += "[b]Resources[/b]\n"
  text += "Total Scrap Earned: %d\n" % stats.total_scrap_earned
  text += "Max Scrap Held: %d\n" % stats.max_scrap_held
  text += "Total XP Earned: %d\n" % stats.total_xp_earned
  
  text += "\n[center][color=gray][i]Press R twice to reset all stats[/i][/color][/center]"
  
  stats_label.text = text

func _input(event):
  if visible and event is InputEventKey and event.pressed:
    if event.keycode == KEY_R:
      _reset_stats_with_confirmation()

func _reset_stats_with_confirmation():
  # Simple confirmation by requiring double-tap
  if not get_meta("reset_confirmation", false):
    set_meta("reset_confirmation", true)
    Logger.info("StatsDisplay", "Press R again to confirm stats reset")
    # Clear confirmation after 3 seconds
    get_tree().create_timer(3.0).timeout.connect(func(): set_meta("reset_confirmation", false))
  else:
    set_meta("reset_confirmation", false)
    StatsManager.reset_stats()
    Logger.info("StatsDisplay", "All stats have been reset")

## Toggle visibility of stats display
func toggle_visibility():
  visible = not visible