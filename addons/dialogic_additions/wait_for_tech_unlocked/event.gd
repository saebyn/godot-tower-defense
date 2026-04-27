@tool
class_name ZomNomWaitForTechUnlockedEvent
extends ZomNomWaitEvent

## Pauses timeline execution until a specific tech node is unlocked.
## If the tech is already unlocked, continues immediately.


### Settings

## The ID of the tech node to wait for.
var tech_id: String = ""


#region EXECUTE
################################################################################
func _wait() -> void:
  if tech_id.is_empty():
    push_error("[ZomNom] WaitForTechUnlocked: tech_id is empty.")
    return

  if TechTreeManager.is_tech_unlocked(tech_id):
    return

  while true:
    var unlocked_tech_id = await TechTreeManager.tech_unlocked
    if unlocked_tech_id == tech_id:
      break

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
  event_name = "Wait For Tech Unlocked"
  event_description = "Pauses the timeline until the specified tech node is unlocked in the Tech Tree."
  set_default_color('Color5')
  event_category = "Zom Nom"
  event_sorting_index = 2

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
  return "zomnom_wait_tech_unlocked"


func get_shortcode_parameters() -> Dictionary:
  return {
    "tech": {"property": "tech_id", "default": ""}
  }

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
  add_header_label("Wait for tech unlocked:")
  add_header_edit("tech_id", ValueType.SINGLELINE_TEXT, {"left_text": "Tech ID:"})

#endregion
