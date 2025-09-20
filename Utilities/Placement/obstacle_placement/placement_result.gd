class_name PlacementResult

enum ValidationError {
  NONE,
  NO_PLACEABLE_OBSTACLE,
  OUTSIDE_NAVIGATION_REGION,
  OBSTACLE_COLLISION,
  NO_TERRAIN_SUPPORT,
  INSUFFICIENT_CLEARANCE,
  INSUFFICIENT_FUNDS,
}

var is_valid: bool
var error: ValidationError
var error_message: String

func _init(valid: bool, err: ValidationError = ValidationError.NONE, msg: String = ""):
  is_valid = valid
  error = err
  error_message = msg
