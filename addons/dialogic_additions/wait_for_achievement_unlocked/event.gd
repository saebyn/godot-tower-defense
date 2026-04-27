@tool
class_name ZomNomWaitForAchievementUnlockedEvent
extends ZomNomWaitEvent

## Pauses timeline execution until a specific achievement is unlocked.
## If the achievement is already unlocked, continues immediately.


### Settings

## The ID of the achievement to wait for.
var achievement_id: String = ""


#region EXECUTE
################################################################################
func _wait() -> void:
  if achievement_id.is_empty():
    push_error("[ZomNom] WaitForAchievementUnlocked: achievement_id is empty.")
    return

  if AchievementManager.is_achievement_unlocked(achievement_id):
    return

  while true:
    var achievement = await AchievementManager.achievement_unlocked
    if achievement.id == achievement_id:
      break

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
  event_name = "Wait For Achievement Unlocked"
  event_description = "Pauses the timeline until the specified achievement is unlocked."
  set_default_color('Color5')
  event_category = "Zom Nom"
  event_sorting_index = 3

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
  return "zomnom_wait_achievement_unlocked"


func get_shortcode_parameters() -> Dictionary:
  return {
    "achievement": {"property": "achievement_id", "default": ""}
  }

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
  add_header_label("Wait for achievement unlocked:")
  add_header_edit("achievement_id", ValueType.SINGLELINE_TEXT, {"left_text": "Achievement ID:"})

#endregion
