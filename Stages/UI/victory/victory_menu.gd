extends Control

@onready var completion_time_label = $Panel/MarginContainer/VBoxContainer/CompletionTimeLabel
@onready var best_time_label = $Panel/MarginContainer/VBoxContainer/BestTimeLabel
@onready var buildings_reclaimed_label = $Panel/MarginContainer/VBoxContainer/BuildingsReclaimedLabel
@onready var scrap_reclaimed_label = $Panel/MarginContainer/VBoxContainer/ScrapReclaimedLabel
@onready var remaining_scrap_label = $Panel/MarginContainer/VBoxContainer/RemainingScrapLabel
@onready var converted_to_xp_label = $Panel/MarginContainer/VBoxContainer/ConvertedToXPLabel
@onready var bonus_xp_label = $Panel/MarginContainer/VBoxContainer/BonusXPLabel
@onready var total_xp_label = $Panel/MarginContainer/VBoxContainer/TotalXPLabel
@onready var current_level_label = $Panel/MarginContainer/VBoxContainer/CurrentLevelLabel

func _ready():
  # Initially hide the victory menu
  visible = false
  
  # Connect to GameManager state changes
  GameManager.game_state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(new_state: GameManager.GameState):
  match new_state:
    GameManager.GameState.VICTORY:
      _update_stats()
      visible = true
    _:
      visible = false


func _update_stats() -> void:
  var stats = ScenarioManager.last_scenario_stats
  
  if stats.is_empty():
    MyLogger.warn("VictoryMenu", "No scenario stats available")
    return
  
  # Format and display completion time
  var completion_time = stats.get("completion_time", 0.0)
  completion_time_label.text = "Completion Time: %s" % _format_time(completion_time)
  
  # Display best time
  var scenario_id = stats.get("scenario_id", "")
  var best_time = ScenarioManager.get_best_time(scenario_id)
  if best_time > 0.0:
    var is_new_record = stats.get("is_new_record", false)
    var record_indicator = " ⭐" if is_new_record else ""
    best_time_label.text = "Best Time: %s%s" % [_format_time(best_time), record_indicator]
  else:
    best_time_label.text = "Best Time: --:--"
  
  # Display building reclaim stats
  var buildings_count = stats.get("buildings_reclaimed", 0)
  buildings_reclaimed_label.text = "Buildings Reclaimed: %d" % buildings_count
  
  var scrap_reclaimed = stats.get("scrap_reclaimed", 0)
  scrap_reclaimed_label.text = "Scrap Reclaimed: +%d" % scrap_reclaimed
  
  # Display scrap conversion stats
  var scrap_converted = stats.get("scrap_converted", 0)
  remaining_scrap_label.text = "Remaining Scrap: %d" % scrap_converted
  
  var xp_from_conversion = stats.get("xp_gained_from_conversion", 0)
  converted_to_xp_label.text = "Converted to XP: +%d ✨" % xp_from_conversion
  
  # Display bonus XP
  var bonus_xp = stats.get("bonus_xp_earned", 0)
  if bonus_xp > 0:
    bonus_xp_label.text = "Completion Bonus: +%d XP ⭐" % bonus_xp
    bonus_xp_label.visible = true
  else:
    bonus_xp_label.visible = false
  
  # Total XP earned (conversion + bonus)
  var total_xp = xp_from_conversion + bonus_xp
  total_xp_label.text = "Total XP Earned: %d" % total_xp
  
  # Display current level and progress
  var current_level = CurrencyManager.get_level()
  var current_xp = CurrencyManager.get_xp()
  var xp_for_next_level = CurrencyManager.get_xp_for_next_level()
  current_level_label.text = "Current Level: %d (%d / %d XP)" % [current_level, current_xp, xp_for_next_level]


## Format seconds to MM:SS
func _format_time(seconds: float) -> String:
  var minutes = int(seconds) / 60
  var remaining_seconds = int(seconds) % 60
  return "%d:%02d" % [minutes, remaining_seconds]


func _on_button_pressed() -> void:
  GameManager.return_to_main_menu()