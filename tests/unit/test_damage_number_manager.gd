extends GutTest

## Unit tests for damage number functionality in health component

func test_damage_number_scene_exists():
  # Verify the damage number scene can be loaded
  var scene = load("res://Common/UI/damage_numbers/damage_number.tscn")
  assert_not_null(scene, "Damage number scene should exist")

func test_damage_number_displays_correctly():
  # Arrange
  var damage_number_scene = load("res://Common/UI/damage_numbers/damage_number.tscn")
  var damage_number = damage_number_scene.instantiate()
  add_child_autofree(damage_number)
  await get_tree().process_frame
  
  # Act
  damage_number.display_damage(50, Vector3.ZERO)
  
  # Assert
  assert_true(damage_number.is_active, "Number should be active after display")
  assert_true(damage_number.visible, "Number should be visible after display")

func test_damage_number_deactivates_after_duration():
  # Arrange
  var damage_number_scene = load("res://Common/UI/damage_numbers/damage_number.tscn")
  var damage_number = damage_number_scene.instantiate()
  add_child_autofree(damage_number)
  await get_tree().process_frame
  
  # Act
  damage_number.display_damage(50, Vector3.ZERO)
  assert_true(damage_number.is_active, "Number should be active immediately")
  
  # Wait for fade duration
  await get_tree().create_timer(damage_number.fade_duration + 0.1).timeout
  
  # Assert
  assert_false(damage_number.is_active, "Number should deactivate after fade duration")

func test_damage_number_color_coding():
  # Arrange
  var damage_number_scene = load("res://Common/UI/damage_numbers/damage_number.tscn")
  var damage_number = damage_number_scene.instantiate()
  add_child_autofree(damage_number)
  await get_tree().process_frame
  
  # Test normal damage (white)
  damage_number.display_damage(10, Vector3.ZERO, UI_DamageNumber.NumberType.DAMAGE_NORMAL)
  assert_eq(damage_number.label_3d.modulate.r, Color.WHITE.r, "Normal damage should be white")
  damage_number.deactivate()
  
  # Test fire damage (orange)
  damage_number.display_damage(10, Vector3.ZERO, UI_DamageNumber.NumberType.DAMAGE_FIRE)
  assert_eq(damage_number.label_3d.modulate.r, Color.ORANGE.r, "Fire damage should be orange")
  damage_number.deactivate()
  
  # Test scrap gain (gold)
  damage_number.display_damage(10, Vector3.ZERO, UI_DamageNumber.NumberType.SCRAP_GAIN)
  assert_eq(damage_number.label_3d.modulate.r, Color.GOLD.r, "Scrap gain should be gold")

func test_health_component_has_damage_number_option():
  # Arrange
  var health_scene = load("res://Common/Components/health/health.tscn")
  var health = health_scene.instantiate()
  add_child_autofree(health)
  await get_tree().process_frame
  
  # Assert
  assert_true("show_damage_numbers" in health, "Health component should have show_damage_numbers property")

func test_scrap_gain_shows_plus_prefix():
  # Arrange
  var damage_number_scene = load("res://Common/UI/damage_numbers/damage_number.tscn")
  var damage_number = damage_number_scene.instantiate()
  add_child_autofree(damage_number)
  await get_tree().process_frame
  
  # Act
  damage_number.display_damage(25, Vector3.ZERO, UI_DamageNumber.NumberType.SCRAP_GAIN)
  
  # Assert
  assert_eq(damage_number.label_3d.text, "+25", "Scrap gain should show + prefix")

func test_damage_number_is_available_after_deactivate():
  # Arrange
  var damage_number_scene = load("res://Common/UI/damage_numbers/damage_number.tscn")
  var damage_number = damage_number_scene.instantiate()
  add_child_autofree(damage_number)
  await get_tree().process_frame
  
  # Act
  damage_number.display_damage(50, Vector3.ZERO)
  assert_false(damage_number.is_available(), "Should not be available while active")
  
  damage_number.deactivate()
  
  # Assert
  assert_true(damage_number.is_available(), "Should be available after deactivate")
