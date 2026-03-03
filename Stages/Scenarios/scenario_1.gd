extends Stage_Scenario

@onready var car: Node3D = $MuscleCar
@onready var survivor: Node3D = $Survivor1

@export var survivor_fall_y: float = -3.278 ## Relative Y position the survivor will fall to when the car is destroyed
@export var survivor_fall_duration: float = 0.5

## Dialogic timeline paths for scenario 1 story and tutorial
const TIMELINE_INTRO := "res://Dialogic/Timelines/scenario_1_intro.dtl"
const TIMELINE_TUT_WELCOME := "res://Dialogic/Timelines/scenario_1_tut_welcome.dtl"
const TIMELINE_TUT_ATTACK := "res://Dialogic/Timelines/scenario_1_tut_attack.dtl"
const TIMELINE_TUT_OBSTACLE := "res://Dialogic/Timelines/scenario_1_tut_obstacle.dtl"
const TIMELINE_TUT_READ_UI := "res://Dialogic/Timelines/scenario_1_tut_read_ui.dtl"
const TIMELINE_TUT_TECH_TREE := "res://Dialogic/Timelines/scenario_1_tut_tech_tree.dtl"

enum TutState {
  INACTIVE,
  INTRO,
  WELCOME,
  TUT_ATTACK,
  AWAITING_ATTACK,
  TUT_OBSTACLE,
  AWAITING_OBSTACLE,
  TUT_READ_UI,
  TUT_TECH_TREE,
  DONE,
}

var _tut_state: TutState = TutState.INACTIVE
var _tutorial_accepted: bool = false


func _ready() -> void:
  super._ready()
  call_deferred("_start_intro_dialog")


func _start_intro_dialog() -> void:
  if not has_node("/root/Dialogic"):
    MyLogger.warn("Scenario1", "Dialogic autoload not found — skipping dialog")
    return
  _tut_state = TutState.INTRO
  Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
  Dialogic.signal_event.connect(_on_dialogic_signal)
  get_tree().paused = true
  Dialogic.start(TIMELINE_INTRO)


## Advance tutorial state when a Dialogic timeline finishes
func _on_dialogic_timeline_ended() -> void:
  match _tut_state:
    TutState.INTRO:
      if SettingsManager.tutorial_enabled:
        _tut_state = TutState.WELCOME
        Dialogic.start(TIMELINE_TUT_WELCOME)
      else:
        _end_dialog()

    TutState.WELCOME:
      if _tutorial_accepted:
        _tut_state = TutState.TUT_ATTACK
        Dialogic.start(TIMELINE_TUT_ATTACK)
      else:
        _end_dialog()

    TutState.TUT_ATTACK:
      # Attack instructions delivered — unpause and wait for the player to attack
      _tut_state = TutState.AWAITING_ATTACK
      get_tree().paused = false
      var main := get_tree().current_scene
      if main and main.has_signal("enemy_attacked"):
        main.enemy_attacked.connect(_on_enemy_attacked_for_tutorial, CONNECT_ONE_SHOT)
      else:
        MyLogger.warn("Scenario1", "enemy_attacked signal not found, skipping attack step")
        _tut_state = TutState.TUT_OBSTACLE
        get_tree().paused = true
        Dialogic.start(TIMELINE_TUT_OBSTACLE)

    TutState.TUT_OBSTACLE:
      # Obstacle instructions delivered — unpause and wait for placement
      _tut_state = TutState.AWAITING_OBSTACLE
      get_tree().paused = false
      var main := get_tree().current_scene
      var op := main.get_node_or_null("ObstaclePlacement") if main else null
      if op and op.has_signal("obstacle_placed"):
        op.obstacle_placed.connect(_on_obstacle_placed_for_tutorial, CONNECT_ONE_SHOT)
      else:
        MyLogger.warn("Scenario1", "obstacle_placed signal not found, skipping obstacle step")
        _tut_state = TutState.TUT_READ_UI
        get_tree().paused = true
        Dialogic.start(TIMELINE_TUT_READ_UI)

    TutState.TUT_READ_UI:
      _tut_state = TutState.TUT_TECH_TREE
      Dialogic.start(TIMELINE_TUT_TECH_TREE)

    TutState.TUT_TECH_TREE:
      _tut_state = TutState.DONE
      _end_dialog()


## Handle signal events emitted from Dialogic timelines
func _on_dialogic_signal(arg: Variant) -> void:
  match str(arg):
    "tutorial_accepted":
      _tutorial_accepted = true
    "tutorial_skipped":
      _tutorial_accepted = false


## Called when the player attacks during the attack tutorial step
func _on_enemy_attacked_for_tutorial() -> void:
  if _tut_state != TutState.AWAITING_ATTACK:
    return
  _tut_state = TutState.TUT_OBSTACLE
  get_tree().paused = true
  Dialogic.start(TIMELINE_TUT_OBSTACLE)


## Called when the player places an obstacle during the obstacle tutorial step
func _on_obstacle_placed_for_tutorial() -> void:
  if _tut_state != TutState.AWAITING_OBSTACLE:
    return
  _tut_state = TutState.TUT_READ_UI
  get_tree().paused = true
  Dialogic.start(TIMELINE_TUT_READ_UI)


## Disconnect Dialogic signals and unpause the game
func _end_dialog() -> void:
  if Dialogic.timeline_ended.is_connected(_on_dialogic_timeline_ended):
    Dialogic.timeline_ended.disconnect(_on_dialogic_timeline_ended)
  if Dialogic.signal_event.is_connected(_on_dialogic_signal):
    Dialogic.signal_event.disconnect(_on_dialogic_signal)
  _tut_state = TutState.INACTIVE
  get_tree().paused = false
  MyLogger.info("Scenario1", "Dialog sequence finished, game running")


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
