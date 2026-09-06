@tool
class_name ZomNomWaitForMainSceneSignalEvent
extends ZomNomWaitEvent

## Pauses timeline execution until a named signal fires on the GameManager.


### Settings

## The signal name to wait for on the GameManager autoload.
var signal_name: String = "enemy_appeared"

## All signals that GameManager is expected to expose for tutorial use.
const GAME_MANAGER_SIGNALS := ["enemy_appeared", "enemy_attacked", "building_placed", "wave_cleared"]


#region EXECUTE
################################################################################
func _wait() -> void:
  if not GameManager.has_signal(signal_name):
    push_error("[ZomNom] WaitForMainSceneSignal: GameManager does not have signal '%s'" % signal_name)
    return

  var signal_ref = GameManager.get(signal_name)
  if signal_ref is Signal:
    await signal_ref
    return

  push_error("[ZomNom] WaitForMainSceneSignal: could not resolve signal '%s'" % signal_name)

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
  event_name = "Wait For Main Scene Signal"
  event_description = "Pauses the timeline until a named signal fires on the GameManager."
  set_default_color('Color5')
  event_category = "Zom Nom"
  event_sorting_index = 1

#endregion


#region SAVING/LOADING
################################################################################

func get_shortcode() -> String:
  return "zomnom_wait_main_signal"


func get_shortcode_parameters() -> Dictionary:
  return {
    "signal": {
      "property": "signal_name",
      "default": "enemy_appeared",
      "suggestions": _build_signal_suggestions
    }
  }


func _build_signal_suggestions() -> Dictionary:
  var suggestions := {}
  for signal_name_option in GAME_MANAGER_SIGNALS:
    suggestions[signal_name_option] = {"value": signal_name_option}
  return suggestions

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
  add_header_label("Wait for GameManager signal:")
  var options: Array[Dictionary] = []
  for signal_name_option in GAME_MANAGER_SIGNALS:
    options.append({"label": signal_name_option, "value": signal_name_option})
  add_header_edit("signal_name", ValueType.FIXED_OPTIONS, {
    "left_text": "",
    "options": options
  })

#endregion
