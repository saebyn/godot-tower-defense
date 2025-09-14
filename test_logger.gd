extends Node

## Simple test script to verify Logger functionality
## Run this as a minimal scene to test logging

func _ready():
	# Test basic logging at different levels
	print("=== Testing Logger Framework ===")
	
	# Test different log levels
	Logger.debug("Test", "This is a debug message")
	Logger.info("Test", "This is an info message")
	Logger.warn("Test", "This is a warning message")
	Logger.error("Test", "This is an error message")
	
	# Test scoped logging
	Logger.info("Player", "Player spawned with 100 health")
	Logger.info("Combat", "Attack dealt 25 damage")
	Logger.info("Economy", "Currency earned: 50 gold")
	
	# Test scope filtering
	print("\n--- Testing scope filtering ---")
	Logger.set_enabled_scopes(["Player", "Economy"])
	Logger.info("Player", "This should appear (Player scope enabled)")
	Logger.info("Combat", "This should NOT appear (Combat scope disabled)")
	Logger.info("Economy", "This should appear (Economy scope enabled)")
	
	# Test wildcard scope
	print("\n--- Testing wildcard scope ---")
	Logger.set_enabled_scopes(["Combat*"])
	Logger.info("Combat", "This should appear (Combat scope)")
	Logger.info("Combat.Attack", "This should appear (Combat.Attack matches Combat*)")
	Logger.info("Player", "This should NOT appear (Player doesn't match Combat*)")
	
	# Test log level filtering
	print("\n--- Testing log level filtering ---")
	Logger.set_enabled_scopes(["*"])  # Reset to show all scopes
	Logger.set_log_level(Logger.LogLevel.WARN)
	Logger.debug("Test", "This should NOT appear (DEBUG < WARN)")
	Logger.info("Test", "This should NOT appear (INFO < WARN)")
	Logger.warn("Test", "This should appear (WARN >= WARN)")
	Logger.error("Test", "This should appear (ERROR > WARN)")
	
	# Test configuration
	print("\n--- Testing configuration ---")
	var config = Logger.get_config()
	print("Current config: ", config)
	
	print("\n=== Logger test completed ===")
	
	# Exit after tests
	get_tree().quit()