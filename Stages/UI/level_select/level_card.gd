extends PanelContainer

## Individual level card that displays level info and handles selection
## Shows level name, status (locked/available/completed), and best stats

signal level_selected(level_id: String)

var level_id: String = ""
var is_unlocked: bool = false
var scene_path: String = ""

@onready var level_name_label = $MarginContainer/VBoxContainer/HeaderHBox/LevelName
@onready var status_label = $MarginContainer/VBoxContainer/HeaderHBox/StatusLabel
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var stats_label = $MarginContainer/VBoxContainer/StatsLabel
@onready var lock_message_label = $MarginContainer/VBoxContainer/LockMessageLabel
@onready var play_button = $MarginContainer/VBoxContainer/PlayButton

func _ready():
  # Connect button signal
  if play_button:
    play_button.pressed.connect(_on_play_button_pressed)

## Configure the level card with level data
func configure(
  p_level_id: String,
  p_level_name: String,
  p_description: String,
  p_is_unlocked: bool,
  p_is_completed: bool,
  p_best_time: float,
  p_best_score: int
):
  level_id = p_level_id
  is_unlocked = p_is_unlocked
  
  # Set level name
  level_name_label.text = p_level_name
  
  # Set description
  description_label.text = p_description
  
  # Set status indicator
  if p_is_completed:
    status_label.text = "✅"
    status_label.tooltip_text = "Completed"
  elif p_is_unlocked:
    status_label.text = "⭐"
    status_label.tooltip_text = "Available"
  else:
    status_label.text = "🔒"
    status_label.tooltip_text = "Locked"
  
  # Show/hide elements based on lock status
  if not p_is_unlocked:
    # Show lock message
    var required_level = LevelProgressManager.get_unlock_requirement(level_id)
    var required_metadata = LevelProgressManager.get_level_metadata(required_level)
    var required_name = required_metadata.get("name", required_level)
    lock_message_label.text = "Complete %s to unlock" % required_name
    lock_message_label.visible = true
    
    # Hide stats and play button
    stats_label.visible = false
    play_button.visible = false
    play_button.disabled = true
  else:
    # Hide lock message
    lock_message_label.visible = false
    
    # Show/update stats if completed
    if p_is_completed and (p_best_time > 0.0 or p_best_score > 0):
      var stats_text = ""
      if p_best_time > 0.0:
        var minutes = int(p_best_time) / 60
        var seconds = int(p_best_time) % 60
        stats_text += "Best Time: %d:%02d" % [minutes, seconds]
      if p_best_score > 0:
        if not stats_text.is_empty():
          stats_text += " | "
        stats_text += "Best Score: %d" % p_best_score
      stats_label.text = stats_text
      stats_label.visible = true
    else:
      stats_label.visible = false
    
    # Show play button
    play_button.visible = true
    play_button.disabled = false

## Handle play button press
func _on_play_button_pressed():
  if is_unlocked:
    Logger.info("LevelCard", "Level selected: %s" % level_id)
    level_selected.emit(level_id)
