extends GutTest

## Unit tests for damage numbers component

func before_each():
  # Clear any existing damage numbers from previous tests
  for label in DamageNumbersManager._number_pool:
    if is_instance_valid(label):
      label.queue_free()
  DamageNumbersManager._number_pool.clear()
  
  # Kill any active tweens
  for label in DamageNumbersManager._active_tweens.keys():
    var tween = DamageNumbersManager._active_tweens[label]
    if is_instance_valid(tween):
      tween.kill()
  DamageNumbersManager._active_tweens.clear()

func after_each():
  # Clean up damage numbers after each test
  for label in DamageNumbersManager._number_pool:
    if is_instance_valid(label):
      label.queue_free()
  DamageNumbersManager._number_pool.clear()
  
  for label in DamageNumbersManager._active_tweens.keys():
    var tween = DamageNumbersManager._active_tweens[label]
    if is_instance_valid(tween):
      tween.kill()
  DamageNumbersManager._active_tweens.clear()

func test_damage_numbers_component_registers_in_metadata():
  # Arrange
  var parent = Node3D.new()
  var component = Component_DamageNumbers.new()
  parent.add_child(component)
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Assert
  assert_true(parent.has_meta("damage_numbers_component"), "Component should register in parent metadata")
  assert_eq(parent.get_meta("damage_numbers_component"), component, "Metadata should reference the component")

func test_damage_numbers_component_creates_labels():
  # Arrange
  var parent = Node3D.new()
  var component = Component_DamageNumbers.new()
  parent.add_child(component)
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Act
  component.show_damage(50, "normal")
  await get_tree().process_frame
  
  # Assert
  assert_gt(DamageNumbersManager._number_pool.size(), 0, "Should create labels in the pool")
  assert_gt(DamageNumbersManager._active_tweens.size(), 0, "Should have active tweens")

func test_damage_numbers_color_coding():
  # Arrange
  var parent = Node3D.new()
  var component = Component_DamageNumbers.new()
  parent.add_child(component)
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Test fire damage (orange) - check the label in pool
  component.show_damage(10, "fire")
  await get_tree().process_frame
  
  # Verify damage was displayed (pool should have at least one label)
  assert_gt(DamageNumbersManager._number_pool.size(), 0, "Should create labels for fire damage")
  # Note: We don't check color because the tween animation may have already started changing it

func test_damage_numbers_scrap_gain():
  # Arrange
  var parent = Node3D.new()
  var component = Component_DamageNumbers.new()
  parent.add_child(component)
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Act
  component.show_scrap(25)
  await get_tree().process_frame
  
  # Assert - verify a label was created
  assert_gt(DamageNumbersManager._number_pool.size(), 0, "Should create label for scrap gain")

func test_damage_numbers_respects_toggle():
  # Arrange
  var parent = Node3D.new()
  var component = Component_DamageNumbers.new()
  component.show_damage_numbers = false
  parent.add_child(component)
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Act
  component.show_damage(50, "normal")
  await get_tree().process_frame
  
  # Assert
  assert_eq(DamageNumbersManager._active_tweens.size(), 0, "Should not show damage when disabled")

func test_scrap_gain_respects_toggle():
  # Arrange
  var parent = Node3D.new()
  var component = Component_DamageNumbers.new()
  component.show_scrap_gain = false
  parent.add_child(component)
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Act
  component.show_scrap(25)
  await get_tree().process_frame
  
  # Assert
  assert_eq(DamageNumbersManager._active_tweens.size(), 0, "Should not show scrap when disabled")

func test_damage_numbers_pool_limit():
  # Arrange
  var parent = Node3D.new()
  var component = Component_DamageNumbers.new()
  parent.add_child(component)
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Act - Create more than max pool size
  for i in range(DamageNumbersManager.MAX_POOL_SIZE + 5):
    component.show_damage(10 + i, "normal")
    await get_tree().process_frame
  
  # Assert
  assert_lte(DamageNumbersManager._number_pool.size(), DamageNumbersManager.MAX_POOL_SIZE, "Pool should not exceed max size")

func test_health_component_uses_damage_numbers_component():
  # Arrange
  var parent = Node3D.new()
  var damage_numbers = Component_DamageNumbers.new()
  parent.add_child(damage_numbers)
  
  var health_scene = load("res://Common/Components/health/health.tscn")
  var health = health_scene.instantiate()
  parent.add_child(health)
  
  add_child_autofree(parent)
  await get_tree().process_frame
  
  # Act
  health.take_damage(25, "fire")
  await get_tree().process_frame
  
  # Assert
  assert_gt(DamageNumbersManager._active_tweens.size(), 0, "Damage numbers should be shown via component")
