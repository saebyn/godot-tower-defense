extends GutTest

## Example unit test for CurrencyManager autoload
## This demonstrates basic GUT testing functionality

func before_each():
  # Reset the CurrencyManager state before each test
  CurrencyManager.current_scrap = 0
  CurrencyManager.current_xp = 0
  CurrencyManager.current_level = 1

func test_earn_scrap_increases_total():
  # Arrange
  var initial_scrap = CurrencyManager.current_scrap
  
  # Act
  CurrencyManager.earn_scrap(50)
  
  # Assert
  assert_eq(CurrencyManager.current_scrap, initial_scrap + 50, "Scrap should increase by 50")

func test_spend_scrap_returns_true_when_enough_scrap():
  # Arrange
  CurrencyManager.current_scrap = 100
  
  # Act
  var result = CurrencyManager.spend_scrap(50)
  
  # Assert
  assert_true(result, "Should return true when spending with sufficient scrap")
  assert_eq(CurrencyManager.current_scrap, 50, "Should have 50 scrap remaining")

func test_spend_scrap_returns_false_when_insufficient_scrap():
  # Arrange
  CurrencyManager.current_scrap = 30
  
  # Act
  var result = CurrencyManager.spend_scrap(50)
  
  # Assert
  assert_false(result, "Should return false when spending with insufficient scrap")
  assert_eq(CurrencyManager.current_scrap, 30, "Scrap should remain unchanged")

func test_earn_xp_increases_total():
  # Arrange
  var initial_xp = CurrencyManager.current_xp
  
  # Act
  CurrencyManager.earn_xp(25)
  
  # Assert
  assert_eq(CurrencyManager.current_xp, initial_xp + 25, "XP should increase by 25")

func test_level_up_occurs_at_xp_threshold():
  # Arrange
  CurrencyManager.current_level = 1
  CurrencyManager.current_xp = 0
  
  # Act - Earn exactly enough XP to level up (100 XP for level 1->2)
  CurrencyManager.earn_xp(100)
  
  # Assert
  assert_eq(CurrencyManager.current_level, 2, "Should level up to level 2")
  assert_eq(CurrencyManager.current_xp, 0, "XP should reset to 0 after leveling up")

func test_multiple_level_ups_from_large_xp_gain():
  # Arrange
  CurrencyManager.current_level = 1
  CurrencyManager.current_xp = 0
  
  # Act - Earn enough XP for multiple level ups (100 + 200 = 300 XP for levels 1->2->3)
  CurrencyManager.earn_xp(300)
  
  # Assert
  assert_eq(CurrencyManager.current_level, 3, "Should level up to level 3")
  assert_eq(CurrencyManager.current_xp, 0, "XP should reset to 0 after leveling up")
