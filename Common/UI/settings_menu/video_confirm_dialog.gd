extends AcceptDialog
class_name VideoSettingsConfirmDialog

## Confirmation dialog for video settings changes with auto-revert timer

signal settings_confirmed()
signal settings_reverted()

const REVERT_TIME_SECONDS: int = 15

@onready var timer_label: Label = $VBoxContainer/TimerLabel
@onready var confirm_button: Button = get_ok_button()

var remaining_time: int = REVERT_TIME_SECONDS
var timer: Timer = null

func _ready() -> void:
  # Setup dialog properties
  title = "Confirm Video Settings"
  dialog_text = "Keep these video settings?"
  ok_button_text = "Keep Settings"
  
  # Create timer
  timer = Timer.new()
  timer.wait_time = 1.0
  timer.timeout.connect(_on_timer_timeout)
  add_child(timer)
  
  # Add custom Revert button
  add_button("Revert", false, "revert")
  custom_action.connect(_on_custom_action)
  
  # Connect signals
  confirmed.connect(_on_confirmed)
  close_requested.connect(_on_close_requested)

func show_dialog() -> void:
  remaining_time = REVERT_TIME_SECONDS
  _update_timer_label()
  timer.start()
  popup_centered()

func _update_timer_label() -> void:
  if timer_label:
    timer_label.text = "Settings will revert in %d seconds..." % remaining_time

func _on_timer_timeout() -> void:
  remaining_time -= 1
  _update_timer_label()
  
  if remaining_time <= 0:
    # Time's up, revert settings
    _revert_settings()

func _on_confirmed() -> void:
  timer.stop()
  settings_confirmed.emit()
  hide()

func _on_custom_action(action: String) -> void:
  if action == "revert":
    timer.stop()
    _revert_settings()

func _on_close_requested() -> void:
  timer.stop()
  _revert_settings()

func _revert_settings() -> void:
  settings_reverted.emit()
  hide()
