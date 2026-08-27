extends SceneTree

const LAB_SCENE := "res://Stages/UI/menu_component_lab/menu_component_lab.tscn"
const CARD_SCENE := "res://Common/UI/menu_card/menu_card.tscn"
const MENU_THEME := "res://Config/ztd_menu_theme.tres"
const OUTPUT_DIR := "res://artifacts/visual/menu_component_lab"

const CARD_STATES := [
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

func _initialize() -> void:
  call_deferred("_run")

func _run() -> void:
  _ensure_output_dir()
  await _capture_lab_viewports()
  await _capture_card_state_matrix()
  await _capture_individual_card_states()
  quit()

func _ensure_output_dir() -> void:
  DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

func _capture_lab_viewports() -> void:
  await _clear_root()
  var lab: Node = load(LAB_SCENE).instantiate()
  root.add_child(lab)
  await _settle()

  _save_root_image("lab_project_viewport.png")

func _capture_card_state_matrix() -> void:
  await _clear_root()
  root.size = Vector2i(1680, 3880)

  var theme: Theme = load(MENU_THEME)
  var card_scene: PackedScene = load(CARD_SCENE)
  var page := Control.new()
  page.set_anchors_preset(Control.PRESET_FULL_RECT)
  page.theme = theme
  root.add_child(page)

  var background := ColorRect.new()
  background.set_anchors_preset(Control.PRESET_FULL_RECT)
  background.color = Color(0.239, 0.184, 0.251, 1.0)
  page.add_child(background)

  var margin := MarginContainer.new()
  margin.set_anchors_preset(Control.PRESET_FULL_RECT)
  margin.add_theme_constant_override("margin_left", 40)
  margin.add_theme_constant_override("margin_top", 40)
  margin.add_theme_constant_override("margin_right", 40)
  margin.add_theme_constant_override("margin_bottom", 40)
  page.add_child(margin)

  var grid := GridContainer.new()
  grid.columns = 4
  grid.add_theme_constant_override("h_separation", 20)
  grid.add_theme_constant_override("v_separation", 20)
  margin.add_child(grid)

  for state in CARD_STATES:
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    grid.add_child(column)

    var label := Label.new()
    label.theme_type_variation = &"MenuMeta"
    label.text = state.label
    column.add_child(label)

    var card: Node = card_scene.instantiate()
    _configure_card(card, state)
    column.add_child(card)

  await _settle()

  for column in grid.get_children():
    var card: Control = column.get_child(1)
    var state = CARD_STATES[column.get_index()]
    card.get_node("HoverFrame").visible = state.get("hover", false)
    card.get_node("FocusFrame").visible = state.get("focus", false)

  await _settle()
  _save_root_image("card_states.png")

func _capture_individual_card_states() -> void:
  for state in CARD_STATES:
    await _clear_root()

    var theme: Theme = load(MENU_THEME)
    var card_scene: PackedScene = load(CARD_SCENE)
    var viewport := SubViewport.new()
    viewport.size = Vector2i(520, 820)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)

    var page := Control.new()
    page.size = Vector2(viewport.size)
    page.theme = theme
    viewport.add_child(page)

    var background := ColorRect.new()
    background.size = Vector2(viewport.size)
    background.color = Color(0.239, 0.184, 0.251, 1.0)
    page.add_child(background)

    var card: Control = card_scene.instantiate()
    card.position = Vector2(80, 50)
    card.size = Vector2(360, 720)
    page.add_child(card)
    _configure_card(card, state)

    await _settle()
    card.get_node("HoverFrame").visible = state.get("hover", false)
    card.get_node("FocusFrame").visible = state.get("focus", false)

    await _settle()
    _save_viewport_image(viewport, "card_state_%s.png" % state.file)

func _configure_card(card: Node, state: Dictionary) -> void:
  card.card_id = state.id
  card.card_number = "02"
  card.title_text = "Campfire Survivors"
  card.description_text = "Protect Survivors with constructed defenses."
  card.selected = state.get("selected", false)
  card.locked = state.get("locked", false)
  card.temporarily_disabled = state.get("temporarily_disabled", false)
  card.completed = state.get("completed", false)

func _clear_root() -> void:
  for child in root.get_children():
    child.queue_free()
  await process_frame

func _settle() -> void:
  await process_frame
  await process_frame

func _save_root_image(file_name: String) -> void:
  _save_viewport_image(root, file_name)

func _save_viewport_image(viewport: Viewport, file_name: String) -> void:
  print("Capturing %s at %sx%s" % [file_name, viewport.size.x, viewport.size.y])
  var image := viewport.get_texture().get_image()
  if image == null:
    push_error("Failed to capture %s: viewport texture is null" % file_name)
    return

  var output_path := "%s/%s" % [OUTPUT_DIR, file_name]
  var error := image.save_png(output_path)
  if error != OK:
    push_error("Failed to save %s: %s" % [output_path, error])
  else:
    print("Saved %s" % output_path)
