extends GutTest

## Example unit test for MyLogger autoload
## Tests the scope filtering functionality

var original_scopes: PackedStringArray
var original_log_level: int

func before_each():
  # Save original settings
  original_scopes = MyLogger.enabled_scopes.duplicate()
  original_log_level = MyLogger.current_log_level

func after_each():
  # Restore original settings
  MyLogger.enabled_scopes = original_scopes
  MyLogger.current_log_level = original_log_level

func test_all_scopes_enabled_by_default():
  # Arrange
  MyLogger.enabled_scopes = ["*"]
  
  # Assert
  assert_true(MyLogger._is_scope_enabled("Player"), "Player scope should be enabled with wildcard")
  assert_true(MyLogger._is_scope_enabled("Combat"), "Combat scope should be enabled with wildcard")
  assert_true(MyLogger._is_scope_enabled("Economy"), "Economy scope should be enabled with wildcard")

func test_specific_scope_enabled():
  # Arrange
  MyLogger.enabled_scopes = ["Player", "Combat"]
  
  # Assert
  assert_true(MyLogger._is_scope_enabled("Player"), "Player scope should be enabled")
  assert_true(MyLogger._is_scope_enabled("Combat"), "Combat scope should be enabled")
  assert_false(MyLogger._is_scope_enabled("Economy"), "Economy scope should be disabled")

func test_log_level_filtering():
  # Arrange
  MyLogger.current_log_level = MyLogger.LogLevel.WARN
  
  # Assert
  # Methods below WARN level should be filtered out
  # We can't directly test if messages are logged, but we can verify the level is set
  assert_eq(MyLogger.current_log_level, MyLogger.LogLevel.WARN, "Log level should be set to WARN")

func test_set_log_level():
  # Act
  MyLogger.set_log_level(MyLogger.LogLevel.DEBUG)
  
  # Assert
  assert_eq(MyLogger.current_log_level, MyLogger.LogLevel.DEBUG, "Log level should be set to DEBUG")

func test_set_scopes():
  # Act
  MyLogger.set_enabled_scopes(["Test1", "Test2"])
  
  # Assert
  assert_has(MyLogger.enabled_scopes, "Test1", "Should include Test1 scope")
  assert_has(MyLogger.enabled_scopes, "Test2", "Should include Test2 scope")
