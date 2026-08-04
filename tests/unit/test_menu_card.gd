extends GutTest

var menu_card_scene = preload("res://Common/UI/menu_card/menu_card.tscn")
var menu_card

func before_each():
  menu_card = menu_card_scene.instantiate()
  add_child_autofree(menu_card)
  await wait_process_frames(1)

func test_default_card_is_available_and_focusable():
  assert_false(menu_card.disabled)
  assert_eq(menu_card.focus_mode, Control.FOCUS_ALL)
  assert_false(menu_card.get_node("ContentMargin/Content/ArtworkFrame/LockOverlay").visible)
  assert_false(menu_card.get_node("SelectionMarker").visible)
  assert_eq(menu_card.get_node("ContentMargin/Content/Status").text, "AVAILABLE")

func test_selection_is_persistent_component_state():
  menu_card.selected = true

  assert_true(menu_card.get_node("SelectionMarker").visible)
  assert_eq(menu_card.get_node("ContentMargin/Content/Status").text, "SELECTED")

func test_locked_card_remains_focusable_and_emits_inspection():
  menu_card.card_id = &"pool_party"
  menu_card.locked = true
  menu_card.lock_reason = "Complete Campfire Survivors"
  watch_signals(menu_card)

  menu_card.emit_signal("pressed")

  assert_false(menu_card.disabled)
  assert_eq(menu_card.focus_mode, Control.FOCUS_ALL)
  assert_true(menu_card.get_node("ContentMargin/Content/ArtworkFrame/LockOverlay").visible)
  assert_signal_emitted_with_parameters(menu_card, "locked_inspected", [&"pool_party"])
  assert_signal_not_emitted(menu_card, "selection_requested")

func test_disabled_card_is_removed_from_focus_navigation():
  menu_card.card_id = &"challenge"
  menu_card.temporarily_disabled = true
  menu_card.disabled_reason = "Coming later"
  watch_signals(menu_card)

  menu_card.emit_signal("pressed")

  assert_true(menu_card.disabled)
  assert_eq(menu_card.focus_mode, Control.FOCUS_NONE)
  assert_true(menu_card.get_node("ContentMargin/Content/ArtworkFrame/ArtworkDim").visible)
  assert_eq(menu_card.get_node("ContentMargin/Content/Status").text, "COMING LATER")
  assert_signal_not_emitted(menu_card, "selection_requested")
  assert_signal_not_emitted(menu_card, "locked_inspected")

func test_available_card_requests_selection():
  menu_card.card_id = &"campfire"
  watch_signals(menu_card)

  menu_card.emit_signal("pressed")

  assert_signal_emitted_with_parameters(menu_card, "selection_requested", [&"campfire"])
  assert_signal_not_emitted(menu_card, "locked_inspected")

func test_completed_state_does_not_change_availability():
  menu_card.completed = true

  assert_false(menu_card.disabled)
  assert_eq(menu_card.focus_mode, Control.FOCUS_ALL)
  assert_true(menu_card.get_node("ContentMargin/Content/TitleRow/CompletionBadge").visible)
  assert_eq(menu_card.get_node("ContentMargin/Content/Status").text, "COMPLETED")

func test_children_do_not_compete_for_mouse_input():
  for child in _all_control_descendants(menu_card):
    assert_eq(child.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func _all_control_descendants(node: Node) -> Array[Control]:
  var controls: Array[Control] = []
  for child in node.get_children():
    if child is Control:
      controls.append(child)
    controls.append_array(_all_control_descendants(child))
  return controls
