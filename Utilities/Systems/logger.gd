extends Node

## Comprehensive logging framework for Tower Defense game
## Provides scoped logging with configurable log levels similar to debug npm package
## 
## Usage:
##   Logger.info("Player", "Game started with %d enemies" % enemy_count)
##   Logger.debug("Combat", "Attack dealt %d damage" % damage)
##   Logger.warn("Economy", "Currency running low: %d remaining" % currency)
##   Logger.error("System", "Failed to load enemy config: %s" % config_path)

enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3,
	NONE = 4  # Disables all logging
}

# Current global log level - can be overridden in project settings
var current_log_level: LogLevel = LogLevel.INFO

# Scope-based filtering - similar to debug npm package
# Format: ["scope1", "scope2", "*"] where "*" means all scopes
var enabled_scopes: PackedStringArray = ["*"]

# Internal settings
var _log_level_names: PackedStringArray = ["DEBUG", "INFO", "WARN", "ERROR"]
var _log_level_colors: PackedStringArray = ["[color=gray]", "[color=white]", "[color=yellow]", "[color=red]"]

# Console commands for runtime control
var _console_commands: Dictionary = {}

signal log_message_emitted(level: LogLevel, scope: String, message: String, timestamp: String)

func _ready() -> void:
	# Load settings from project settings
	_load_project_settings()
	
	# Register console commands for runtime control
	_register_console_commands()
	
	# Log framework initialization
	info("Logger", "Logging framework initialized - Level: %s, Scopes: %s" % [
		_log_level_names[current_log_level], 
		", ".join(enabled_scopes)
	])

## Load logging configuration from project settings
func _load_project_settings() -> void:
	# Log level setting
	current_log_level = ProjectSettings.get_setting("logging/log_level", LogLevel.INFO)
	
	# Scopes setting - comma-separated string
	var scopes_setting = ProjectSettings.get_setting("logging/enabled_scopes", "*")
	if scopes_setting is String:
		enabled_scopes = scopes_setting.split(",")
		# Trim whitespace from each scope
		for i in range(enabled_scopes.size()):
			enabled_scopes[i] = enabled_scopes[i].strip_edges()

## Register console commands for runtime log control
func _register_console_commands() -> void:
	_console_commands = {
		"log_level": _cmd_set_log_level,
		"log_scopes": _cmd_set_scopes,
		"log_info": _cmd_show_info
	}

## Main logging function - checks level and scope before outputting
func _log(level: LogLevel, scope: String, message: String) -> void:
	# Check if logging level is enabled
	if level < current_log_level:
		return
	
	# Check if scope is enabled
	if not _is_scope_enabled(scope):
		return
	
	# Format timestamp
	var time = Time.get_datetime_dict_from_system()
	var unix_time = Time.get_unix_time_from_system()
	var milliseconds = int((unix_time - int(unix_time)) * 1000)
	var timestamp = "%02d:%02d:%02d.%03d" % [
		time.hour, time.minute, time.second, milliseconds
	]
	
	# Format the log message
	var level_name = _log_level_names[level]
	var color_tag = _log_level_colors[level]
	var formatted_message = "%s[%s] [%s] %s: %s[/color]" % [
		color_tag, timestamp, level_name, scope, message
	]
	
	# Output to console
	print_rich(formatted_message)
	
	# Emit signal for external listeners (UI, file logging, etc.)
	log_message_emitted.emit(level, scope, message, timestamp)

## Check if a scope is enabled for logging
func _is_scope_enabled(scope: String) -> bool:
	# If "*" is in enabled scopes, all scopes are enabled
	if "*" in enabled_scopes:
		return true
	
	# Check for exact scope match
	if scope in enabled_scopes:
		return true
	
	# Check for wildcard patterns (e.g., "Combat*" matches "Combat.Attack")
	for enabled_scope in enabled_scopes:
		if enabled_scope.ends_with("*"):
			var prefix = enabled_scope.trim_suffix("*")
			if scope.begins_with(prefix):
				return true
	
	return false

## Public logging methods for each level

func debug(scope: String, message: String) -> void:
	_log(LogLevel.DEBUG, scope, message)

func info(scope: String, message: String) -> void:
	_log(LogLevel.INFO, scope, message)

func warn(scope: String, message: String) -> void:
	_log(LogLevel.WARN, scope, message)

func error(scope: String, message: String) -> void:
	_log(LogLevel.ERROR, scope, message)

## Runtime configuration methods

## Set the current log level
func set_log_level(level: LogLevel) -> void:
	current_log_level = level
	info("Logger", "Log level changed to: %s" % _log_level_names[level])

## Set enabled scopes (array of scope names or wildcard patterns)
func set_enabled_scopes(scopes: PackedStringArray) -> void:
	enabled_scopes = scopes
	info("Logger", "Enabled scopes changed to: %s" % ", ".join(scopes))

## Add a scope to the enabled scopes list
func enable_scope(scope: String) -> void:
	if scope not in enabled_scopes:
		enabled_scopes.append(scope)
		info("Logger", "Enabled scope: %s" % scope)

## Remove a scope from the enabled scopes list
func disable_scope(scope: String) -> void:
	var index = enabled_scopes.find(scope)
	if index >= 0:
		enabled_scopes.remove_at(index)
		info("Logger", "Disabled scope: %s" % scope)

## Console command handlers

func _cmd_set_log_level(args: PackedStringArray) -> void:
	if args.size() < 1:
		print("Usage: log_level <DEBUG|INFO|WARN|ERROR|NONE>")
		return
	
	var level_name = args[0].to_upper()
	var level_index = _log_level_names.find(level_name)
	if level_index >= 0:
		set_log_level(level_index as LogLevel)
	elif level_name == "NONE":
		set_log_level(LogLevel.NONE)
	else:
		print("Invalid log level: %s" % level_name)

func _cmd_set_scopes(args: PackedStringArray) -> void:
	if args.size() < 1:
		print("Usage: log_scopes <scope1,scope2,...> or log_scopes *")
		print("Current scopes: %s" % ", ".join(enabled_scopes))
		return
	
	var scopes_arg = args[0]
	if scopes_arg == "*":
		set_enabled_scopes(["*"])
	else:
		var new_scopes = scopes_arg.split(",")
		for i in range(new_scopes.size()):
			new_scopes[i] = new_scopes[i].strip_edges()
		set_enabled_scopes(new_scopes)

func _cmd_show_info(_args: PackedStringArray) -> void:
	print("=== Logger Configuration ===")
	print("Current Log Level: %s" % _log_level_names[current_log_level])
	print("Enabled Scopes: %s" % ", ".join(enabled_scopes))
	print("Available Commands:")
	print("  log_level <DEBUG|INFO|WARN|ERROR|NONE> - Set log level")
	print("  log_scopes <scope1,scope2,...> - Set enabled scopes")
	print("  log_info - Show this information")

## Handle console input (to be called from input handler)
func handle_console_command(command: String, args: PackedStringArray) -> bool:
	if command in _console_commands:
		_console_commands[command].call(args)
		return true
	return false

## Utility method to get current configuration as a dictionary
func get_config() -> Dictionary:
	return {
		"log_level": current_log_level,
		"log_level_name": _log_level_names[current_log_level],
		"enabled_scopes": enabled_scopes
	}