extends Control

@onready var survival_time_label = $Panel/MarginContainer/VBoxContainer/SurvivalTimeLabel
@onready var buildings_reclaimed_label = $Panel/MarginContainer/VBoxContainer/BuildingsReclaimedLabel
@onready var scrap_reclaimed_label = $Panel/MarginContainer/VBoxContainer/ScrapReclaimedLabel
@onready var remaining_scrap_label = $Panel/MarginContainer/VBoxContainer/RemainingScrapLabel
@onready var converted_to_xp_label = $Panel/MarginContainer/VBoxContainer/ConvertedToXPLabel
@onready var current_level_label = $Panel/MarginContainer/VBoxContainer/CurrentLevelLabel

func _ready():
  # Initially hide the game over menu
  visible = false
  
  # Connect to GameManager state changes
  GameManager.game_state_changed.connect(_on_game_state_changed)


func _on_game_state_changed(new_state: GameManager.GameState):
  match new_state:
    GameManager.GameState.GAME_OVER:
      _update_stats()
      visible = true
    _:
      visible = false


func _update_stats() -> void:
  var stats = ScenarioManager.last_scenario_stats
  
  if stats.is_empty():
    MyLogger.warn("GameOverMenu", "No scenario stats available")
    return
  
  # Format and display survival time
  var elapsed_time = stats.get("elapsed_time", 0.0)
  survival_time_label.text = "Survival Time: %s" % _format_time(elapsed_time)
  
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
