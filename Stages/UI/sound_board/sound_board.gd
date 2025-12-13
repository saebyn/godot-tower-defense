extends Control

class_name UI_SoundBoard

## Sound board UI for testing and playing sound effects from AudioManager
## Provides buttons to play each sound effect defined in the AudioManager

@onready var sound_list_container: VBoxContainer = %SoundListContainer
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var close_button: Button = %CloseButton

func _ready():
  MyLogger.info("SoundBoard", "Sound board loaded")
  _populate_sound_list()
  
  if close_button:
    close_button.pressed.connect(_on_close_button_pressed)

func _populate_sound_list():
  if not sound_list_container:
    MyLogger.warn("SoundBoard", "Sound list container not found")
    return
  
  # Get all sound effects from the AudioManager enum
  var sound_effect_names = AudioManager.SoundEffect.keys()
  
  MyLogger.info("SoundBoard", "Creating buttons for %d sound effects" % sound_effect_names.size())
  
  for effect_name in sound_effect_names:
    var button = Button.new()
    var effect_value = AudioManager.SoundEffect.get(effect_name)
    
    # Format the button text (convert SNAKE_CASE to Title Case)
    var display_name = effect_name.capitalize()
    button.text = display_name
    button.custom_minimum_size = Vector2(300, 40)
    
    # Connect button to play the sound
    button.pressed.connect(_on_sound_button_pressed.bind(effect_value, effect_name))
    
    sound_list_container.add_child(button)

func _on_sound_button_pressed(effect: AudioManager.SoundEffect, effect_name: String):
  MyLogger.info("SoundBoard", "Playing sound effect: %s" % effect_name)
  AudioManager.play_sound(audio_player, effect)

func _on_close_button_pressed():
  MyLogger.info("SoundBoard", "Close button pressed")
  queue_free()
