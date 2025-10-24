extends Control
class_name AchievementCard

## Individual achievement card for the achievement list
## Shows achievement name, description, icon, and unlock status

@onready var panel: PanelContainer = $PanelContainer
@onready var icon: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Icon
@onready var name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DescriptionLabel
@onready var progress_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/ProgressLabel
@onready var unlock_date_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/UnlockDateLabel
@onready var locked_overlay: ColorRect = $PanelContainer/LockedOverlay

var achievement_id: String = ""

## Setup the card with achievement data
func setup(achievement: AchievementResource, is_unlocked: bool, progress: float, unlock_date: String) -> void:
  if not achievement:
    return
  
  achievement_id = achievement.id
  
  # Set achievement info
  name_label.text = achievement.name
  
  # Handle hidden achievements
  if achievement.hidden and not is_unlocked:
    name_label.text = "???"
    description_label.text = "Hidden achievement"
    progress_label.visible = false
    unlock_date_label.visible = false
    icon.visible = false
  else:
    description_label.text = achievement.description
    
    # Set icon if available
    if achievement.icon:
      icon.texture = achievement.icon
      icon.visible = true
    else:
      icon.visible = false
    
    # Show progress if not unlocked
    if is_unlocked:
      progress_label.visible = false
      unlock_date_label.visible = true
      unlock_date_label.text = "Unlocked: %s" % unlock_date
    else:
      progress_label.visible = true
      progress_label.text = "Progress: %d%%" % int(progress * 100.0)
      unlock_date_label.visible = false
  
  # Apply locked overlay if not unlocked
  if locked_overlay:
    locked_overlay.visible = not is_unlocked
    locked_overlay.modulate = Color(0, 0, 0, 0.6) if not is_unlocked else Color(0, 0, 0, 0)
