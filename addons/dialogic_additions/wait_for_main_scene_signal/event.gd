@tool
class_name ZomNomWaitForMainSceneSignalEvent
extends DialogicEvent

## Pauses timeline execution until a named signal fires on the main scene.
## The main scene must declare the signal (see main.gd).


### Settings

## The signal name to wait for on the main scene.
var signal_name: String = "enemy_appeared"

## All signals that main.gd is expected to expose for tutorial use.
const MAIN_SCENE_SIGNALS := ["enemy_appeared", "enemy_attacked", "building_placed", "wave_cleared"]


#region EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Text.hide_textbox()
	await _wait_for_signal()
	dialogic.Text.show_textbox()
	finish()


func _wait_for_signal() -> void:
	var main_scene := dialogic.get_tree().current_scene
	if main_scene == null or not main_scene.has_signal(signal_name):
		push_error("[ZomNom] WaitForMainSceneSignal: main scene does not have signal '%s'" % signal_name)
		return

	var signal_ref = main_scene.get(signal_name)
	if signal_ref is Signal:
		await signal_ref
		return

	push_error("[ZomNom] WaitForMainSceneSignal: could not resolve signal '%s'" % signal_name)

#endregion


#region INITIALIZE
################################################################################

func _init() -> void:
	event_name = "Wait For Main Scene Signal"
	event_description = "Pauses the timeline until a named signal fires on the main game scene."
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
	for signal_name_option in MAIN_SCENE_SIGNALS:
		suggestions[signal_name_option] = {"value": signal_name_option}
	return suggestions

#endregion


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	add_header_label("Wait for main scene signal:")
	var options: Array[Dictionary] = []
	for signal_name_option in MAIN_SCENE_SIGNALS:
		options.append({"label": signal_name_option, "value": signal_name_option})
	add_header_edit("signal_name", ValueType.FIXED_OPTIONS, {
		"left_text": "",
		"options": options
	})

#endregion
