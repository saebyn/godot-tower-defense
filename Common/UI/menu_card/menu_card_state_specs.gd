extends RefCounted

class_name UI_MenuCardStateSpecs

const CARD_NUMBER := "02"
const TITLE_TEXT := "Campfire Survivors"
const DESCRIPTION_TEXT := "Protect Survivors with constructed defenses."

const STATES := [
  {"label": "DEFAULT", "file": "default", "id": &"default"},
  {"label": "HOVER", "file": "hover", "id": &"hover", "hover": true},
  {"label": "HOVER + FOCUS", "file": "hover_focus", "id": &"hover_focus", "hover": true, "focus": true},
  {"label": "FOCUS", "file": "focus", "id": &"focus", "focus": true},
  {"label": "SELECTED", "file": "selected", "id": &"selected", "selected": true},
  {"label": "SELECTED + FOCUS", "file": "selected_focus", "id": &"selected_focus", "selected": true, "focus": true},
  {"label": "LOCKED", "file": "locked", "id": &"locked", "locked": true},
  {"label": "LOCKED + HOVER", "file": "locked_hover", "id": &"locked_hover", "locked": true, "hover": true},
  {"label": "LOCKED + FOCUS", "file": "locked_focus", "id": &"locked_focus", "locked": true, "focus": true},
  {"label": "LOCKED + HOVER + FOCUS", "file": "locked_hover_focus", "id": &"locked_hover_focus", "locked": true, "hover": true, "focus": true},
  {"label": "DISABLED", "file": "disabled", "id": &"disabled", "temporarily_disabled": true},
  {"label": "COMPLETED", "file": "completed", "id": &"completed", "completed": true},
  {"label": "COMPLETED + HOVER", "file": "completed_hover", "id": &"completed_hover", "completed": true, "hover": true},
  {"label": "COMPLETED + FOCUS", "file": "completed_focus", "id": &"completed_focus", "completed": true, "focus": true},
  {"label": "SELECTED + COMPLETED", "file": "selected_completed", "id": &"selected_completed", "selected": true, "completed": true},
  {"label": "SELECTED + HOVER + FOCUS", "file": "selected_hover_focus", "id": &"selected_hover_focus", "selected": true, "hover": true, "focus": true},
]

static func all() -> Array:
  return STATES.duplicate(true)

static func apply_to_card(card: Node, state: Dictionary) -> void:
  card.card_id = state.id
  card.card_number = state.get("card_number", CARD_NUMBER)
  card.title_text = state.get("title_text", TITLE_TEXT)
  card.description_text = state.get("description_text", DESCRIPTION_TEXT)
  card.selected = state.get("selected", false)
  card.locked = state.get("locked", false)
  card.lock_reason = state.get("lock_reason", "Complete Campfire Survivors")
  card.temporarily_disabled = state.get("temporarily_disabled", false)
  card.disabled_reason = state.get("disabled_reason", "Coming later")
  card.completed = state.get("completed", false)

static func apply_navigation_preview(card: Control, state: Dictionary) -> void:
  card.apply_preview_navigation_state(state.get("hover", false), state.get("focus", false))
