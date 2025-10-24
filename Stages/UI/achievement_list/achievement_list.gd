extends Control
class_name AchievementList

## Achievement list screen that shows all achievements and their unlock status
## Can be opened from the main menu or pause menu

signal closed()

const AchievementCardScene = preload("res://Stages/UI/achievement_list/achievement_card.tscn")

@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var scroll_container: ScrollContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer
@onready var achievement_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/AchievementContainer
@onready var stats_label: Label = $Panel/MarginContainer/VBoxContainer/StatsLabel

var achievement_cards: Array[AchievementCard] = []

func _ready() -> void:
  # Connect signals
  close_button.pressed.connect(_on_close_pressed)
  
  # Refresh the achievement list
  refresh_achievements()
  
  Logger.info("AchievementList", "Achievement list UI initialized")

## Refresh the entire achievement list
func refresh_achievements() -> void:
  # Clear existing cards
  for card in achievement_cards:
    card.queue_free()
  achievement_cards.clear()
  
  for child in achievement_container.get_children():
    child.queue_free()
  
  if not AchievementManager:
    Logger.error("AchievementList", "AchievementManager not found!")
    return
  
  # Get all achievements
  var all_achievements = AchievementManager.get_all_achievements()
  
  # Sort achievements by unlock status (unlocked first) then by name
  all_achievements.sort_custom(_sort_achievements)
  
  # Create cards for each achievement
  for achievement in all_achievements:
    var is_unlocked = AchievementManager.is_achievement_unlocked(achievement.id)
    var progress = AchievementManager.get_achievement_progress(achievement.id)
    var state = AchievementManager.achievement_states.get(achievement.id)
    var unlock_date = state.unlock_date if state else ""
    
    var card = AchievementCardScene.instantiate()
    achievement_container.add_child(card)
    card.setup(achievement, is_unlocked, progress, unlock_date)
    achievement_cards.append(card)
  
  # Update stats
  _update_stats(all_achievements)

## Sort achievements: unlocked first, then by name
func _sort_achievements(a: AchievementResource, b: AchievementResource) -> bool:
  var a_unlocked = AchievementManager.is_achievement_unlocked(a.id)
  var b_unlocked = AchievementManager.is_achievement_unlocked(b.id)
  
  # Unlocked achievements come first
  if a_unlocked != b_unlocked:
    return a_unlocked
  
  # Then sort by name
  return a.name < b.name

## Update the stats label with unlock statistics
func _update_stats(all_achievements: Array[AchievementResource]) -> void:
  var total_count = all_achievements.size()
  var unlocked_count = 0
  
  for achievement in all_achievements:
    if AchievementManager.is_achievement_unlocked(achievement.id):
      unlocked_count += 1
  
  var percentage = 0
  if total_count > 0:
    percentage = int((float(unlocked_count) / float(total_count)) * 100.0)
  
  stats_label.text = "Achievements Unlocked: %d / %d (%d%%)" % [unlocked_count, total_count, percentage]

func _on_close_pressed() -> void:
  Logger.info("AchievementList", "Closing achievement list")
  closed.emit()
  queue_free()
