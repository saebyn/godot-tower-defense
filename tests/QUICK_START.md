# Quick Start: Testing with GUT

This guide helps you get started writing tests for the Zom Nom Defense project.

## Running Tests

```bash
# Run all tests
./run_tests.sh

# From Godot Editor
# Open project → Bottom panel → Gut tab → Click "Run All"
```

## Writing Your First Test

1. **Create a test file** in `tests/unit/` or `tests/integration/`
   - Filename must start with `test_` (e.g., `test_my_feature.gd`)

2. **Basic test structure**:
```gdscript
extends GutTest

func before_each():
  # Setup code runs before each test
  pass

func test_something_works():
  # Arrange - Set up test data
  var value = 42
  
  # Act - Call the code you're testing
  var result = some_function(value)
  
  # Assert - Verify the result
  assert_eq(result, expected_value, "Should return expected value")
```

## Common Testing Patterns

### Testing Autoloads
```gdscript
func test_currency_manager():
  # Reset state
  CurrencyManager.current_scrap = 0
  
  # Test behavior
  CurrencyManager.earn_scrap(100)
  assert_eq(CurrencyManager.current_scrap, 100)
```

### Testing Signals
```gdscript
func test_signal_emitted():
  watch_signals(CurrencyManager)
  CurrencyManager.earn_scrap(50)
  assert_signal_emitted(CurrencyManager, "scrap_earned")
```

### Testing Scenes
```gdscript
func test_enemy_scene():
  var enemy = load("res://Entities/Enemies/Templates/base_enemy/enemy.tscn").instantiate()
  add_child_autofree(enemy)  # Auto-cleanup after test
  
  assert_not_null(enemy.get_node("Health"))
```

## Useful Assertions

```gdscript
# Equality
assert_eq(got, expected, "message")
assert_ne(got, expected, "message")

# Boolean
assert_true(condition, "message")
assert_false(condition, "message")

# Null checks
assert_null(value, "message")
assert_not_null(value, "message")

# Collections
assert_has(array, item, "message")
assert_does_not_have(array, item, "message")

# Approximate equality (for floats)
assert_almost_eq(got, expected, threshold, "message")

# Signals
watch_signals(object)
assert_signal_emitted(object, "signal_name")
assert_signal_not_emitted(object, "signal_name")
```

## Test Organization

### Unit Tests (`tests/unit/`)
- Test individual functions/methods
- Mock external dependencies
- Fast and isolated
- Example: `test_currency_manager.gd`

### Integration Tests (`tests/integration/`)
- Test multiple components together
- Verify system interactions
- May involve autoloads
- Example: `test_system_integration.gd`

## Tips

1. **Keep tests independent** - Each test should work regardless of test order
2. **Use `before_each()` for setup** - Reset state before each test
3. **Use `after_each()` for cleanup** - Clean up resources after tests
4. **Test one thing at a time** - Each test should verify one behavior
5. **Use descriptive names** - Test names should explain what they test
6. **Add assertions** - Every test needs at least one assert

## Examples in This Project

- `tests/unit/test_currency_manager.gd` - Unit tests for economy system
- `tests/unit/test_logger.gd` - Unit tests for logging system
- `tests/integration/test_system_integration.gd` - Integration tests

## Need Help?

- See `tests/README.md` for comprehensive documentation
- Check [GUT Wiki](https://github.com/bitwes/Gut/wiki) for detailed reference
- Look at existing tests for patterns

## CI/CD

Tests automatically run on:
- Every push to `main` branch
- Every pull request

Check GitHub Actions tab for test results.
