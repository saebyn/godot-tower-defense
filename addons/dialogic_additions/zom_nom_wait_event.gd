@tool
class_name ZomNomWaitEvent
extends DialogicEvent

## Base class for all Zom Nom "wait for condition" Dialogic events.
## Handles hiding and showing the dialog textbox around the wait.
## Subclasses implement _wait() with the actual await logic.


#region EXECUTE
################################################################################

func _execute() -> void:
	dialogic.Text.hide_textbox()
	await _wait()
	dialogic.Text.show_textbox()
	finish()


## Override in subclasses to implement the actual wait condition.
## This method should contain an await expression.
func _wait() -> void:
	pass

#endregion
