# GUT (Godot Unit Testing) Framework

This project uses [GUT (Godot Unit Testing)](https://github.com/bitwes/Gut) v9.3.0 for automated testing.

## Overview

GUT is a unit testing framework for Godot that provides:
- Test discovery and execution
- Assertions and expectations
- Test doubles (mocks, stubs, spies)
- Integration with Godot's scene tree
- Command-line test running for CI/CD

## Running Tests

### Command Line

The easiest way to run tests is using the provided script:

```bash
./run_tests.sh
```

This will run all tests in the `tests/` directory and display results in the console.

### From Godot Editor

1. Open the project in Godot Editor
2. Go to the bottom panel and select the "Gut" tab
3. Click "Run All" to execute all tests
4. View results in the GUT panel

### CI/CD Integration

For CI/CD pipelines, run tests headlessly:

```bash
./godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

Exit code 0 indicates all tests passed; non-zero indicates failures.

## Test Structure

Tests are organized into two main directories:

```
tests/
├── unit/               # Unit tests for individual components
│   ├── test_currency_manager.gd
│   └── test_logger.gd
└── integration/        # Integration tests for system interactions
    └── test_system_integration.gd
```

### Unit Tests

Unit tests focus on testing individual components in isolation. They should:
- Test a single class or function
- Use test doubles for dependencies
- Be fast and independent
- Follow the Arrange-Act-Assert pattern

### Integration Tests

Integration tests verify that multiple components work correctly together. They should:
- Test interactions between systems
- Verify data flows correctly through the application
- Test autoload interactions
- Be independent of each other

## Writing Tests

All test files must:
1. Extend `GutTest`
2. Have names starting with `test_` (configurable in `.gutconfig.json`)
3. End with `.gd` extension
4. Contain functions starting with `test_` for test cases

### Example Test

```gdscript
extends GutTest

func before_each():
  # Setup code run before each test
  pass

func after_each():
  # Cleanup code run after each test
  pass

func test_example():
  # Arrange
  var expected = 42
  
  # Act
  var actual = some_function()
  
  # Assert
  assert_eq(actual, expected, "Should return 42")
```

## Common Assertions

- `assert_eq(got, expected, message)` - Values are equal
- `assert_ne(got, expected, message)` - Values are not equal
- `assert_true(got, message)` - Value is true
- `assert_false(got, message)` - Value is false
- `assert_null(got, message)` - Value is null
- `assert_not_null(got, message)` - Value is not null
- `assert_has(container, item, message)` - Container has item
- `assert_does_not_have(container, item, message)` - Container doesn't have item

See [GUT documentation](https://github.com/bitwes/Gut/wiki/Asserts-and-Methods) for complete assertion list.

## Configuration

Test configuration is in `.gutconfig.json`:

```json
{
  "dirs": ["res://tests/unit", "res://tests/integration"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd"
}
```

## Test Doubles

GUT supports creating test doubles (mocks, spies, stubs):

```gdscript
# Create a double
var double = double(MyClass)

# Stub a method
stub(double, 'my_method').to_return(42)

# Spy on method calls
var spy = spy(MyClass)
spy.my_method()
assert_called(spy, 'my_method')
```

## Best Practices

1. **Test Isolation**: Each test should be independent and not rely on other tests
2. **Setup/Teardown**: Use `before_each()` and `after_each()` for setup and cleanup
3. **Clear Names**: Use descriptive test names that explain what is being tested
4. **One Assertion Per Concept**: Test one thing at a time
5. **Arrange-Act-Assert**: Follow the AAA pattern for clarity
6. **Fast Tests**: Keep tests fast by avoiding unnecessary delays
7. **No External Dependencies**: Tests should not depend on network, filesystem (except user://), etc.

## Resources

- [GUT GitHub Repository](https://github.com/bitwes/Gut)
- [GUT Documentation](https://github.com/bitwes/Gut/wiki)
- [GUT API Reference](https://github.com/bitwes/Gut/wiki/Asserts-and-Methods)

## Troubleshooting

### Tests Not Running

- Ensure GUT plugin is enabled in Project Settings → Plugins
- Check that test files follow naming convention (`test_*.gd`)
- Verify `.gutconfig.json` paths are correct

### Import Errors

- Run asset import: `./godot --headless --import --path .`
- Restart Godot editor after adding new test files

### Autoload Issues

- Tests have access to autoloaded singletons (Logger, CurrencyManager, etc.)
- Reset autoload state in `before_each()` to ensure test isolation
