extends GutTest

var lab_scene = preload("res://Stages/UI/menu_component_lab/menu_component_lab.tscn")
var card_state_specs = preload("res://Common/UI/menu_card/menu_card_state_specs.gd")
var lab

func before_each():
  lab = lab_scene.instantiate()
  add_child_autofree(lab)
  await wait_process_frames(1)

func test_card_grid_uses_three_columns_at_1280_width():
  assert_eq(lab._get_card_columns(1280.0), 3)

func test_card_grid_uses_four_columns_when_width_allows():
  assert_eq(lab._get_card_columns(1920.0), 4)
  assert_eq(lab._get_card_columns(3440.0), 4)

func test_card_grid_does_not_drop_below_two_columns():
  assert_eq(lab._get_card_columns(720.0), 2)

func test_state_matrix_cards_are_static_specimens():
  var grid: GridContainer = lab.get_node("SafeArea/Layout/StateScroll/StateContent/CardsGrid")
  var states: Array = card_state_specs.all()

  assert_eq(grid.get_child_count(), states.size())
  for index in states.size():
    var column: VBoxContainer = grid.get_child(index)
    var label: Label = column.get_child(0)
    var card: Control = column.get_child(1)

    assert_eq(label.text, states[index].label)
    assert_eq(card.card_id, states[index].id)
    assert_eq(card.focus_mode, Control.FOCUS_NONE)
    assert_eq(card.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_hover_focus_specimen_gives_focus_visual_priority():
  var card: Control = _get_state_card(&"hover_focus")

  assert_false(card.get_node("HoverFrame").visible)
  assert_true(card.get_node("FocusFrame").visible)

func _get_state_card(card_id: StringName) -> Control:
  var grid: GridContainer = lab.get_node("SafeArea/Layout/StateScroll/StateContent/CardsGrid")
  for column in grid.get_children():
    var card: Control = column.get_child(1)
    if card.card_id == card_id:
      return card
  return null

func test_interactive_playground_owns_live_focus():
  var playground_card = lab.get_node("SafeArea/Layout/StateScroll/StateContent/PlaygroundRow/PlaygroundCardA")

  assert_eq(playground_card.focus_mode, Control.FOCUS_ALL)
  assert_eq(lab.get_viewport().gui_get_focus_owner(), playground_card)

func test_legend_explains_focus_and_selection_symbols():
  var legend: Label = lab.get_node("SafeArea/Layout/StateScroll/StateContent/StateLegend")

  assert_string_contains(legend.text, "cyan outline means navigation focus")
  assert_string_contains(legend.text, "star ribbon means persistent selection")
