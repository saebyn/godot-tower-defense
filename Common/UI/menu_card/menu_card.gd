@tool
extends Button

class_name UI_MenuCard

## One focusable menu choice with composable choice, availability, and progression states.

signal selection_requested(card_id: StringName)
signal locked_inspected(card_id: StringName)

@export_group("Content")
@export var card_id: StringName = &""
@export var card_number := "01":
  set(value):
    card_number = value
    _refresh()
@export var title_text := "MENU CARD":
  set(value):
    title_text = value
    _refresh()
@export_multiline var description_text := "A representative menu card.":
  set(value):
    description_text = value
    _refresh()
@export var action_label := "AVAILABLE":
  set(value):
    action_label = value
    _refresh()
@export var artwork: Texture2D:
  set(value):
    artwork = value
    _refresh()

@export_group("Choice")
@export var selected := false:
  set(value):
    selected = value
    _refresh()

@export_group("Availability")
@export var locked := false:
  set(value):
    locked = value
    _refresh()
@export var lock_reason := "Complete the previous Scenario":
  set(value):
    lock_reason = value
    _refresh()
@export var temporarily_disabled := false:
  set(value):
    temporarily_disabled = value
    _refresh()
@export var disabled_reason := "Temporarily unavailable":
  set(value):
    disabled_reason = value
    _refresh()

@export_group("Progression")
@export var completed := false:
  set(value):
    completed = value
    _refresh()

@onready var _number_label: Label = %Number
@onready var _title_label: Label = %Title
@onready var _description_label: Label = %Description
@onready var _status_label: Label = %Status
@onready var _artwork_rect: TextureRect = %Artwork
@onready var _artwork_placeholder: Control = %ArtworkPlaceholder
@onready var _artwork_dim: ColorRect = %ArtworkDim
@onready var _lock_overlay: Control = %LockOverlay
@onready var _lock_reason_label: Label = %LockReason
@onready var _selection_marker: Control = %SelectionMarker
@onready var _completion_badge: Control = %CompletionBadge
@onready var _card_frame: Control = %CardFrame
@onready var _hover_frame: Control = %HoverFrame
@onready var _focus_frame: Control = %FocusFrame
@onready var _title_stack: Control = %TitleStack

var _hovered := false

func _ready() -> void:
  if not pressed.is_connected(_on_pressed):
    pressed.connect(_on_pressed)
  if not mouse_entered.is_connected(_on_mouse_entered):
    mouse_entered.connect(_on_mouse_entered)
  if not mouse_exited.is_connected(_on_mouse_exited):
    mouse_exited.connect(_on_mouse_exited)
  if not focus_entered.is_connected(_on_focus_changed):
    focus_entered.connect(_on_focus_changed)
  if not focus_exited.is_connected(_on_focus_changed):
    focus_exited.connect(_on_focus_changed)
  _ignore_mouse_on_children(self)
  _refresh()

func _refresh() -> void:
  if not is_node_ready():
    return

  _number_label.text = card_number
  _title_label.text = _format_title_text(title_text.to_upper())
  _description_label.text = _format_description_text(description_text)

  _artwork_rect.texture = artwork
  _artwork_rect.visible = artwork != null
  _artwork_placeholder.visible = artwork == null
  _artwork_dim.visible = locked or temporarily_disabled

  _selection_marker.visible = selected
  _completion_badge.visible = completed
  _lock_overlay.visible = locked and not temporarily_disabled
  _lock_reason_label.text = ""

  disabled = temporarily_disabled
  focus_mode = Control.FOCUS_NONE if temporarily_disabled else Control.FOCUS_ALL
  _status_label.text = _get_status_text()
  _refresh_content_dimming()
  _refresh_navigation_frames()

func _get_status_text() -> String:
  if temporarily_disabled:
    return "TEMPORARILY UNAVAILABLE"
  if locked:
    return "LOCKED"
  if selected:
    return "SELECTED"
  if completed:
    return "COMPLETED"
  return action_label.to_upper()

func _format_title_text(text: String) -> String:
  if text.length() <= 14 or not text.contains(" "):
    return text

  return _break_at_middle_space(text)

func _format_description_text(text: String) -> String:
  if text.length() <= 34 or not text.contains(" "):
    return text

  return _break_at_middle_space(text)

func _break_at_middle_space(text: String) -> String:
  if not text.contains(" "):
    return text

  var target_index := text.length() / 2.0
  var best_space_index := -1
  var best_distance := INF
  for index in range(text.length()):
    if text[index] != " ":
      continue

    var distance: float = abs(index - target_index)
    if distance < best_distance:
      best_distance = distance
      best_space_index = index

  if best_space_index == -1:
    return text

  return "%s\n%s" % [text.substr(0, best_space_index), text.substr(best_space_index + 1)]

func _on_pressed() -> void:
  if temporarily_disabled:
    return
  if locked:
    locked_inspected.emit(card_id)
    return
  selection_requested.emit(card_id)

func _on_mouse_entered() -> void:
  _hovered = true
  _refresh_navigation_frames()

func _on_mouse_exited() -> void:
  _hovered = false
  _refresh_navigation_frames()

func _on_focus_changed() -> void:
  _refresh_navigation_frames()

func _refresh_navigation_frames() -> void:
  var shows_focus := has_focus() and not temporarily_disabled
  var shows_hover := _hovered and not shows_focus and not temporarily_disabled

  _card_frame.visible = not shows_focus and not shows_hover
  _hover_frame.visible = shows_hover
  _focus_frame.visible = shows_focus

func _refresh_content_dimming() -> void:
  var dimmed_color := Color(0.62, 0.62, 0.62, 0.82) if locked or temporarily_disabled else Color.WHITE
  _artwork_placeholder.modulate = dimmed_color
  _artwork_rect.modulate = dimmed_color
  _title_stack.modulate = dimmed_color
  _description_label.modulate = dimmed_color

func _ignore_mouse_on_children(node: Node) -> void:
  for child in node.get_children():
    if child is Control:
      child.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _ignore_mouse_on_children(child)
