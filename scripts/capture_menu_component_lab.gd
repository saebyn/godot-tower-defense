extends SceneTree

const LAB_SCENE := "res://Stages/UI/menu_component_lab/menu_component_lab.tscn"
const CARD_SCENE := "res://Common/UI/menu_card/menu_card.tscn"
const MENU_THEME := "res://Config/ztd_menu_theme.tres"
const OUTPUT_DIR := "res://artifacts/visual/menu_component_lab"
const CARD_STATE_SPECS := preload("res://Common/UI/menu_card/menu_card_state_specs.gd")
const MATRIX_VIEWPORT_SIZE := Vector2i(1280, 2048)
const MATRIX_GUTTER := 48
const MATRIX_CARD_SCALE := 0.58
const MATRIX_CARD_SOURCE_SIZE := Vector2(360, 720)
const MATRIX_CARD_SLOT_SIZE := Vector2(232, 450)

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

  var states := CARD_STATE_SPECS.all()
  var theme: Theme = load(MENU_THEME)
  var card_scene: PackedScene = load(CARD_SCENE)
  var viewport := SubViewport.new()
  viewport.size = MATRIX_VIEWPORT_SIZE
  viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  root.add_child(viewport)

  var page := Control.new()
  page.size = Vector2(viewport.size)
  page.theme = theme
  viewport.add_child(page)

  var background := ColorRect.new()
  background.size = Vector2(viewport.size)
  background.color = Color(0.075, 0.082, 0.068, 1.0)
  page.add_child(background)

  var margin := MarginContainer.new()
  margin.size = Vector2(viewport.size)
  margin.add_theme_constant_override("margin_left", MATRIX_GUTTER)
  margin.add_theme_constant_override("margin_top", MATRIX_GUTTER)
  margin.add_theme_constant_override("margin_right", MATRIX_GUTTER)
  margin.add_theme_constant_override("margin_bottom", MATRIX_GUTTER)
  page.add_child(margin)

  var grid := GridContainer.new()
  grid.columns = 4
  grid.add_theme_constant_override("h_separation", 48)
  grid.add_theme_constant_override("v_separation", 28)
  margin.add_child(grid)

  for state in states:
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    grid.add_child(column)

    var label := Label.new()
    label.theme_type_variation = &"MenuMeta"
    label.text = state.label
    column.add_child(label)

    var slot := Control.new()
    slot.custom_minimum_size = MATRIX_CARD_SLOT_SIZE
    column.add_child(slot)

    var card: Control = card_scene.instantiate()
    card.position = Vector2((MATRIX_CARD_SLOT_SIZE.x - MATRIX_CARD_SOURCE_SIZE.x * MATRIX_CARD_SCALE) / 2.0, 0)
    card.size = MATRIX_CARD_SOURCE_SIZE
    card.scale = Vector2(MATRIX_CARD_SCALE, MATRIX_CARD_SCALE)
    CARD_STATE_SPECS.apply_to_card(card, state)
    slot.add_child(card)

  await _settle()

  for column in grid.get_children():
    var card: Control = column.get_child(1).get_child(0)
    var state = states[column.get_index()]
    CARD_STATE_SPECS.apply_navigation_preview(card, state)

  await _settle()
  _save_viewport_image(viewport, "card_states.png")

func _capture_individual_card_states() -> void:
  for state in CARD_STATE_SPECS.all():
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
    background.color = Color(0.075, 0.082, 0.068, 1.0)
    page.add_child(background)

    var card: Control = card_scene.instantiate()
    card.position = Vector2(80, 50)
    card.size = Vector2(360, 720)
    page.add_child(card)
    CARD_STATE_SPECS.apply_to_card(card, state)

    await _settle()
    CARD_STATE_SPECS.apply_navigation_preview(card, state)

    await _settle()
    _save_viewport_image(viewport, "card_state_%s.png" % state.file)

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
