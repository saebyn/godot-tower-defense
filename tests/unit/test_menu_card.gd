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
  assert_false(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/LockOverlay").visible)
  assert_false(menu_card.get_node("SelectionMarker").visible)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "AVAILABLE")

func test_selection_is_persistent_component_state():
  menu_card.selected = true

  assert_true(menu_card.get_node("SelectionMarker").visible)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "SELECTED")

func test_locked_card_remains_focusable_and_emits_inspection():
  menu_card.card_id = &"pool_party"
  menu_card.locked = true
  menu_card.lock_reason = "Complete Campfire Survivors"
  watch_signals(menu_card)

  menu_card.emit_signal("pressed")

  assert_false(menu_card.disabled)
  assert_eq(menu_card.focus_mode, Control.FOCUS_ALL)
  assert_eq(menu_card.tooltip_text, "Complete Campfire Survivors")
  assert_true(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/LockOverlay").visible)
  assert_signal_emitted_with_parameters(menu_card, "locked_inspected", [&"pool_party"])
  assert_signal_not_emitted(menu_card, "selection_requested")

func test_lock_reason_is_tooltip_not_card_text():
  menu_card.locked = true
  menu_card.lock_reason = "Complete Campfire Survivors"

  assert_eq(menu_card.tooltip_text, "Complete Campfire Survivors")
  assert_eq(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/LockOverlay/LockPanel/Margin/VBox/LockedLabel").text, "LOCKED")
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "COMPLETE\nCAMPFIRE")

func test_disabled_card_is_removed_from_focus_navigation():
  menu_card.card_id = &"challenge"
  menu_card.temporarily_disabled = true
  menu_card.disabled_reason = "Coming later"
  watch_signals(menu_card)

  menu_card.emit_signal("pressed")

  assert_true(menu_card.disabled)
  assert_eq(menu_card.focus_mode, Control.FOCUS_NONE)
  assert_eq(menu_card.tooltip_text, "Coming later")
  assert_true(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/ArtworkDim").visible)
  assert_false(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/LockOverlay").visible)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "UNAVAILABLE")
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
  assert_true(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status/CompletionBadge").visible)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "COMPLETED")

func test_default_focus_uses_outline_without_hiding_content():
  menu_card.grab_focus()
  await wait_process_frames(1)

  var focus_frame: NinePatchRect = menu_card.get_node("FocusFrame")
  assert_true(focus_frame.visible)
  assert_eq(focus_frame.mouse_filter, Control.MOUSE_FILTER_IGNORE)
  assert_eq(focus_frame.texture.resource_path, "res://Assets/Textures/UI/cyan-frame.png")
  assert_false(focus_frame.draw_center)
  assert_gt(focus_frame.z_index, menu_card.get_node("CardFrame").z_index)
  assert_true(menu_card.get_node("ContentMargin/CardBody/InfoArea/TitleStack/Number").visible)
  assert_true(menu_card.get_node("ContentMargin/CardBody/InfoArea/TitleStack/Title").visible)
  assert_true(menu_card.get_node("ContentMargin/CardBody/InfoArea/Description").visible)
  assert_true(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").visible)

func test_selected_focus_keeps_ribbon_and_outline():
  menu_card.selected = true
  menu_card.grab_focus()
  await wait_process_frames(1)

  assert_true(menu_card.get_node("SelectionMarker").visible)
  assert_true(menu_card.get_node("FocusFrame").visible)
  assert_gt(menu_card.get_node("SelectionMarker").z_index, menu_card.get_node("FocusFrame").z_index)

func test_focus_takes_visual_priority_over_hover_frame():
  menu_card.apply_preview_navigation_state(true, false)
  assert_true(menu_card.get_node("HoverFrame").visible)

  menu_card.apply_preview_navigation_state(true, true)

  assert_false(menu_card.get_node("HoverFrame").visible)
  assert_true(menu_card.get_node("FocusFrame").visible)

func test_locked_focus_keeps_dimming_requirement_icon_and_outline():
  menu_card.locked = true
  menu_card.grab_focus()
  await wait_process_frames(1)

  assert_true(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/ArtworkDim").visible)
  assert_true(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/LockOverlay").visible)
  assert_true(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/LockOverlay/LockPanel/Margin/VBox/LockIcon").visible)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "COMPLETE\nPREVIOUS")
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status/StatusPlate").texture.resource_path, "res://Assets/Textures/UI/olive-steel-plate.png")
  assert_true(menu_card.get_node("FocusFrame").visible)
  assert_gt(menu_card.get_node("FocusFrame").z_index, menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/ArtworkDim").z_index)

func test_disabled_takes_precedence_over_locked_visuals():
  menu_card.locked = true
  menu_card.temporarily_disabled = true

  assert_true(menu_card.disabled)
  assert_eq(menu_card.focus_mode, Control.FOCUS_NONE)
  assert_true(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/ArtworkDim").visible)
  assert_false(menu_card.get_node("ContentMargin/CardBody/ArtworkFrame/LockOverlay").visible)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "UNAVAILABLE")

func test_completed_can_coexist_with_selected_and_focus():
  menu_card.completed = true
  menu_card.selected = true
  menu_card.grab_focus()
  await wait_process_frames(1)

  assert_true(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status/CompletionBadge").visible)
  assert_true(menu_card.get_node("SelectionMarker").visible)
  assert_true(menu_card.get_node("FocusFrame").visible)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").text, "COMPLETED")

func test_dimming_leaves_status_and_semantic_icons_legible():
  menu_card.locked = true
  menu_card.completed = true
  menu_card.grab_focus()
  await wait_process_frames(1)

  assert_ne(menu_card.get_node("ContentMargin/CardBody/InfoArea/TitleStack").modulate, Color.WHITE)
  assert_ne(menu_card.get_node("ContentMargin/CardBody/InfoArea/Description").modulate, Color.WHITE)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status").modulate, Color.WHITE)
  assert_eq(menu_card.get_node("ContentMargin/CardBody/InfoArea/Status/CompletionBadge").modulate, Color.WHITE)
  assert_eq(menu_card.get_node("FocusFrame").modulate, Color.WHITE)

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
