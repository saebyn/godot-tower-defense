extends Control

## Interactive reference scene for the first menu visual-language iteration.

const MAX_CARD_COLUMNS := 4
const MIN_CARD_COLUMNS := 2
const CARD_MIN_WIDTH := 360.0
const CARD_GAP := 24.0
const SAFE_AREA_HORIZONTAL_MARGIN := 128.0
const SCROLLBAR_GUTTER := 16.0
const CARD_SCENE := preload("res://Common/UI/menu_card/menu_card.tscn")
const CARD_STATE_SPECS := preload("res://Common/UI/menu_card/menu_card_state_specs.gd")

@onready var _feedback_label: Label = %FeedbackLabel
@onready var _cards_grid: GridContainer = %CardsGrid
@onready var _playground_first_card: Button = %PlaygroundCardA
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

var _state_cards: Array[Button] = []
var _state_specs: Array = []

func _ready() -> void:
  _generate_state_grid()
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

func _generate_state_grid() -> void:
  _state_specs = CARD_STATE_SPECS.all()
  _state_cards.clear()

  for child in _cards_grid.get_children():
    child.queue_free()

  for state in _state_specs:
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    _cards_grid.add_child(column)

    var label := Label.new()
    label.theme_type_variation = &"MenuMeta"
    label.text = state.label
    column.add_child(label)

    var card: Button = CARD_SCENE.instantiate()
    CARD_STATE_SPECS.apply_to_card(card, state)
    column.add_child(card)
    _state_cards.append(card)

func _apply_static_state_previews() -> void:
  # Static matrix cards are visual specimens; live focus is demonstrated below.
  for index in _state_cards.size():
    var card := _state_cards[index]
    card.focus_mode = Control.FOCUS_NONE
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    CARD_STATE_SPECS.apply_navigation_preview(card, _state_specs[index])

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
