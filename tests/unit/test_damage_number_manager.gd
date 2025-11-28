extends GutTest

## Unit tests for damage numbers component

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
	assert_gt(component._number_pool.size(), 0, "Should create labels in the pool")
	assert_gt(component._active_numbers.size(), 0, "Should have active numbers")

func test_damage_numbers_color_coding():
	# Arrange
	var parent = Node3D.new()
	var component = Component_DamageNumbers.new()
	parent.add_child(component)
	add_child_autofree(parent)
	await get_tree().process_frame
	
	# Test fire damage (orange)
	component.show_damage(10, "fire")
	await get_tree().process_frame
	
	if component._active_numbers.size() > 0:
		var label = component._active_numbers[0].label
		assert_eq(label.modulate.r, Color.ORANGE.r, "Fire damage should be orange")

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
	
	# Assert
	if component._active_numbers.size() > 0:
		var label = component._active_numbers[0].label
		assert_eq(label.text, "+25", "Scrap gain should show + prefix")
		assert_eq(label.modulate.r, Color.GOLD.r, "Scrap gain should be gold")

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
	assert_eq(component._active_numbers.size(), 0, "Should not show damage when disabled")

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
	assert_eq(component._active_numbers.size(), 0, "Should not show scrap when disabled")

func test_damage_numbers_pool_limit():
	# Arrange
	var parent = Node3D.new()
	var component = Component_DamageNumbers.new()
	component.max_pool_size = 3
	parent.add_child(component)
	add_child_autofree(parent)
	await get_tree().process_frame
	
	# Act - Create more than max pool size
	for i in range(5):
		component.show_damage(10 + i, "normal")
		await get_tree().process_frame
	
	# Assert
	assert_lte(component._number_pool.size(), 3, "Pool should not exceed max size")

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
	assert_gt(damage_numbers._active_numbers.size(), 0, "Damage numbers should be shown via component")
