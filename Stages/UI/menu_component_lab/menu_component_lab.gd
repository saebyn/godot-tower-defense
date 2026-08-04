extends Control

## Interactive reference scene for the first menu visual-language iteration.

@onready var _feedback_label: Label = %FeedbackLabel
@onready var _primary_button: Button = %PrimaryButton
@onready var _hover_card: Button = %HoverCard
@onready var _preview_focus_cards: Array[Button] = [
  %FocusCard,
  %SelectedFocusCard,
  %LockedFocusCard,
]
@onready var _cards: Array[Button] = [
  %DefaultCard,
  %HoverCard,
  %FocusCard,
  %SelectedCard,
  %SelectedFocusCard,
  %LockedFocusCard,
  %DisabledCard,
  %CompletedCard,
]

func _ready() -> void:
  _apply_static_state_previews()
  _connect_card_feedback()
  _primary_button.call_deferred("grab_focus")

func _apply_static_state_previews() -> void:
  # The gallery keeps its labelled states visible even while actual focus moves.
  _hover_card.add_theme_stylebox_override(
    "normal",
    _hover_card.get_theme_stylebox("hover")
  )
  for card in _preview_focus_cards:
    _add_focus_preview(card)

func _add_focus_preview(card: Button) -> void:
  var preview := Panel.new()
  preview.name = "StatePreviewFocusRing"
  preview.z_index = 10
  preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
  preview.add_theme_stylebox_override("panel", card.get_theme_stylebox("focus"))
  card.add_child(preview)
  preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _connect_card_feedback() -> void:
  for card in _cards:
    card.connect("selection_requested", _on_selection_requested)
    card.connect("locked_inspected", _on_locked_inspected)
    card.focus_entered.connect(_on_card_focused.bind(card))

func _on_selection_requested(card_id: StringName) -> void:
  _feedback_label.text = "CONFIRM: %s requested selection" % card_id

func _on_locked_inspected(card_id: StringName) -> void:
  _feedback_label.text = "INSPECT: %s remains focusable but cannot be selected" % card_id

func _on_card_focused(card: Button) -> void:
  _feedback_label.text = "FOCUS: %s (selection state did not change)" % card.name

func _on_primary_button_pressed() -> void:
  _feedback_label.text = "PRIMARY ACTION: confirmed"

func _on_secondary_button_pressed() -> void:
  _feedback_label.text = "SECONDARY ACTION: confirmed"

func _on_back_button_pressed() -> void:
  _feedback_label.text = "BACK ACTION: confirmed"
