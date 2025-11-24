extends GutTest

## Unit tests for the damage number manager

var damage_number_manager: UI_DamageNumberManager

func before_each():
  # Create a fresh damage number manager for each test
  var manager_scene = load("res://Common/UI/damage_numbers/damage_number_manager.tscn")
  damage_number_manager = manager_scene.instantiate()
  add_child_autofree(damage_number_manager)
  # Wait a frame for _ready to complete
  await get_tree().process_frame

func test_manager_initializes_with_pool():
  # Assert
  assert_not_null(damage_number_manager, "Damage number manager should be created")
  assert_eq(damage_number_manager.damage_number_pool.size(), damage_number_manager.initial_pool_size, 
    "Pool should be initialized with correct size")

func test_show_damage_creates_active_number():
  # Arrange
  var initial_active_count = damage_number_manager.active_damage_numbers.size()
  
  # Act
  damage_number_manager.show_damage(50, Vector3(0, 0, 0))
  
  # Assert
  assert_gt(damage_number_manager.active_damage_numbers.size(), initial_active_count, 
    "Should have more active damage numbers")

func test_show_damage_respects_settings():
  # Arrange
  damage_number_manager.damage_numbers_enabled = false
  
  # Act
  damage_number_manager.show_damage(50, Vector3(0, 0, 0))
  
  # Assert
  assert_eq(damage_number_manager.active_damage_numbers.size(), 0, 
    "Should not create damage numbers when disabled")

func test_show_scrap_respects_settings():
  # Arrange
  damage_number_manager.scrap_numbers_enabled = false
  
  # Act
  damage_number_manager.show_scrap_gain(10, Vector3(0, 0, 0))
  
  # Assert
  assert_eq(damage_number_manager.active_damage_numbers.size(), 0, 
    "Should not create scrap numbers when disabled")

func test_pool_expands_when_needed():
  # Arrange
  var initial_pool_size = damage_number_manager.damage_number_pool.size()
  
  # Act - Use up all numbers in the pool
  for i in range(initial_pool_size + 5):
    damage_number_manager.show_damage(10, Vector3(i, 0, 0))
  
  # Assert
  assert_gt(damage_number_manager.damage_number_pool.size(), initial_pool_size, 
    "Pool should expand when needed")

func test_pool_does_not_exceed_max_size():
  # Arrange
  var max_size = damage_number_manager.max_pool_size
  
  # Act - Try to create more numbers than max pool size
  for i in range(max_size + 10):
    damage_number_manager.show_damage(10, Vector3(i, 0, 0))
  
  # Assert
  assert_lte(damage_number_manager.damage_number_pool.size(), max_size, 
    "Pool should not exceed max size")

func test_connect_to_enemy_succeeds():
  # Arrange
  var enemy_scene = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")
  var enemy = enemy_scene.instantiate()
  add_child_autofree(enemy)
  await get_tree().process_frame
  
  # Act
  damage_number_manager.connect_to_enemy(enemy)
  
  # No assertion needed - just verify it doesn't crash
  pass_test("Successfully connected to enemy")

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
