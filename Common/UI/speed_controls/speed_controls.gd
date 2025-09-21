"""
SpeedControls.gd

A UI component that provides game speed control buttons (pause/play, 1x, 2x, 4x speed).
Connects to the GameManager singleton to control game speed and pause state.
"""
extends Control
class_name SpeedControls

@onready var pause_button: Button = $HBoxContainer/PauseButton
@onready var speed_1x_button: Button = $HBoxContainer/Speed1xButton
@onready var speed_2x_button: Button = $HBoxContainer/Speed2xButton
@onready var speed_4x_button: Button = $HBoxContainer/Speed4xButton

var speed_buttons: Array[Button] = []

func _ready() -> void:
  _setup_buttons()
  _connect_signals()
  _update_button_states()

func _setup_buttons() -> void:
  # Configure pause button
  if pause_button:
    pause_button.text = "⏸️"
    pause_button.tooltip_text = "Pause Game"
  
  # Configure speed buttons
  if speed_1x_button:
    speed_1x_button.text = "1x"
    speed_1x_button.tooltip_text = "Normal Speed"
    speed_buttons.append(speed_1x_button)
  
  if speed_2x_button:
    speed_2x_button.text = "2x"
    speed_2x_button.tooltip_text = "Double Speed"
    speed_buttons.append(speed_2x_button)
  
  if speed_4x_button:
    speed_4x_button.text = "4x"
    speed_4x_button.tooltip_text = "Quadruple Speed"
    speed_buttons.append(speed_4x_button)

func _connect_signals() -> void:
  # Connect button signals
  if pause_button:
    pause_button.pressed.connect(_on_pause_pressed)
  
  if speed_1x_button:
    speed_1x_button.pressed.connect(_on_speed_1x_pressed)
  
  if speed_2x_button:
    speed_2x_button.pressed.connect(_on_speed_2x_pressed)
  
  if speed_4x_button:
    speed_4x_button.pressed.connect(_on_speed_4x_pressed)
  
  # Connect to GameManager signals
  GameManager.game_state_changed.connect(_on_game_state_changed)
  GameManager.speed_changed.connect(_on_speed_changed)

func _update_button_states() -> void:
  # Update speed button states
  var current_speed = GameManager.get_game_speed()
  if pause_button:
    if current_speed == 0.0:
      pause_button.text = "▶️"
      pause_button.tooltip_text = "Resume Game"
    else:
      pause_button.text = "⏸️"
      pause_button.tooltip_text = "Pause Game"

  for button in speed_buttons:
    if button:
      button.button_pressed = false
  
  # Highlight the current speed button
  if current_speed == 0.0 and pause_button:
    pause_button.button_pressed = true
  elif current_speed == 1.0 and speed_1x_button:
    speed_1x_button.button_pressed = true
  elif current_speed == 2.0 and speed_2x_button:
    speed_2x_button.button_pressed = true
  elif current_speed == 4.0 and speed_4x_button:
    speed_4x_button.button_pressed = true

func _on_pause_pressed() -> void:
  if GameManager.get_game_speed() > 0.0:
    GameManager.set_game_speed(0.0)
  else:
    GameManager.set_game_speed(1.0)

func _on_speed_1x_pressed() -> void:
  GameManager.set_game_speed(1.0)

func _on_speed_2x_pressed() -> void:
  GameManager.set_game_speed(2.0)

func _on_speed_4x_pressed() -> void:
  GameManager.set_game_speed(4.0)

func _on_game_state_changed(_new_state: GameManager.GameState) -> void:
  _update_button_states()

func _on_speed_changed(_new_speed: float) -> void:
  _update_button_states()