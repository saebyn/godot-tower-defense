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

func _ready() -> void:
  if not pressed.is_connected(_on_pressed):
    pressed.connect(_on_pressed)
  _ignore_mouse_on_children(self)
  _refresh()

func _refresh() -> void:
  if not is_node_ready():
    return

  _number_label.text = card_number
  _title_label.text = title_text.to_upper()
  _description_label.text = description_text

  _artwork_rect.texture = artwork
  _artwork_rect.visible = artwork != null
  _artwork_placeholder.visible = artwork == null
  _artwork_dim.visible = locked or temporarily_disabled

  _selection_marker.visible = selected
  _completion_badge.visible = completed
  _lock_overlay.visible = locked
  _lock_reason_label.text = lock_reason.to_upper()

  disabled = temporarily_disabled
  focus_mode = Control.FOCUS_NONE if temporarily_disabled else Control.FOCUS_ALL
  _status_label.text = _get_status_text()

func _get_status_text() -> String:
  if temporarily_disabled:
    return disabled_reason.to_upper()
  if locked:
    return lock_reason.to_upper()
  if selected:
    return "SELECTED"
  if completed:
    return "COMPLETED"
  return action_label.to_upper()

func _on_pressed() -> void:
  if temporarily_disabled:
    return
  if locked:
    locked_inspected.emit(card_id)
    return
  selection_requested.emit(card_id)

func _ignore_mouse_on_children(node: Node) -> void:
  for child in node.get_children():
    if child is Control:
      child.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _ignore_mouse_on_children(child)
