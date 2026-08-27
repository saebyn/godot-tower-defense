extends Control

## Interactive reference scene for the first menu visual-language iteration.

const MAX_CARD_COLUMNS := 4
const MIN_CARD_COLUMNS := 2
const CARD_MIN_WIDTH := 360.0
const CARD_GAP := 20.0
const SAFE_AREA_HORIZONTAL_MARGIN := 96.0
const SCROLLBAR_GUTTER := 16.0

@onready var _feedback_label: Label = %FeedbackLabel
@onready var _hover_card: Button = %HoverCard
@onready var _hover_focus_card: Button = %HoverFocusCard
@onready var _cards_grid: GridContainer = %CardsGrid
@onready var _playground_first_card: Button = %PlaygroundCardA
@onready var _preview_focus_cards: Array[Button] = [
  %FocusCard,
  %HoverFocusCard,
  %SelectedFocusCard,
  %LockedFocusCard,
]
@onready var _state_cards: Array[Button] = [
  %DefaultCard,
  %HoverCard,
  %HoverFocusCard,
  %FocusCard,
  %SelectedCard,
  %SelectedFocusCard,
  %LockedFocusCard,
  %DisabledCard,
  %CompletedCard,
]
@onready var _playground_cards: Array[Button] = [
  %PlaygroundCardA,
  %PlaygroundCardB,
  %PlaygroundCardC,
]
@onready var _focusable_controls: Array[Control] = [
  %BackButton,
  %SecondaryButton,
  %PrimaryButton,
  %PlaygroundCardA,
  %PlaygroundCardB,
  %PlaygroundCardC,
]

func _ready() -> void:
  resized.connect(_update_responsive_layout)
  _update_responsive_layout()
  _apply_static_state_previews()
  _connect_card_feedback()
  _playground_first_card.call_deferred("grab_focus")

func _update_responsive_layout() -> void:
  if not is_node_ready():
    return

  _cards_grid.columns = _get_card_columns(get_viewport_rect().size.x)

func _get_card_columns(viewport_width: float) -> int:
  var available_width := viewport_width - SAFE_AREA_HORIZONTAL_MARGIN - SCROLLBAR_GUTTER
  var columns := floori((available_width + CARD_GAP) / (CARD_MIN_WIDTH + CARD_GAP))
  return clampi(columns, MIN_CARD_COLUMNS, MAX_CARD_COLUMNS)

func _apply_static_state_previews() -> void:
  # Static matrix cards are visual specimens; live focus is demonstrated below.
  for card in _state_cards:
    card.focus_mode = Control.FOCUS_NONE
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _hover_card.get_node("HoverFrame").visible = true
  _hover_focus_card.get_node("HoverFrame").visible = true
  for card in _preview_focus_cards:
    _add_focus_preview(card)

func _add_focus_preview(card: Button) -> void:
  card.get_node("FocusFrame").visible = true

func _connect_card_feedback() -> void:
  for card in _playground_cards:
    card.connect("selection_requested", _on_selection_requested)
    card.connect("locked_inspected", _on_locked_inspected)
  for card in _focusable_controls:
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
