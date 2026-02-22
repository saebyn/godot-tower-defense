extends Stage_Scenario

@onready var car: Node3D = $MuscleCar
@onready var survivor: Node3D = $Survivor1

@export var survivor_fall_y: float = -3.278 ## Relative Y position the survivor will fall to when the car is destroyed
@export var survivor_fall_duration: float = 0.5


func car_destroyed(damage_source: String):
  MyLogger.info("Scenario1", "Car destroyed by " + damage_source)
  # Remove the car from the scene since it's destroyed
  car.queue_free()
  # Then we need to make the survivor fall down
  var tween = get_tree().create_tween()
  tween.tween_property(
    survivor,
    "position:y",
    survivor_fall_y,
    survivor_fall_duration
  ).as_relative().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
