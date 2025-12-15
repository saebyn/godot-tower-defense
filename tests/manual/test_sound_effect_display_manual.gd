extends Control

## Manual test scene for sound effect display
## Allows testing the display functionality with keyboard input

@onready var sound_display: Control = $SoundEffectDisplay
@onready var test_timer: Timer = $TestTimer

var test_audio_player: AudioStreamPlayer

func _ready():
  # Create an audio player for testing
  test_audio_player = AudioStreamPlayer.new()
  add_child(test_audio_player)
  
  # Start with display visible for testing
  sound_display.visible = true
  
  print("Test scene ready. Press 1-5 to play sounds, F11 to toggle display, SPACE for rapid sounds")

func _process(_delta):
  # Handle key presses for testing
  if Input.is_action_just_pressed("toggle_sound_effects"):
    sound_display.toggle_display()
    print("Display toggled: ", "visible" if sound_display.visible else "hidden")
  
  # Test individual sound effects
  if Input.is_key_pressed(KEY_1):
    AudioManager.play_sound(test_audio_player, Resource_SoundEffect.SoundEffect.PLAYER_ATTACK_HIT)
  elif Input.is_key_pressed(KEY_2):
    AudioManager.play_sound(test_audio_player, Resource_SoundEffect.SoundEffect.TURRET_FIRE)
  elif Input.is_key_pressed(KEY_3):
    AudioManager.play_sound(test_audio_player, Resource_SoundEffect.SoundEffect.ZOMBIE_DEATH)
  elif Input.is_key_pressed(KEY_4):
    AudioManager.play_sound_2d(Resource_SoundEffect.SoundEffect.UI_CONFIRM)
  elif Input.is_key_pressed(KEY_5):
    AudioManager.play_sound_2d(Resource_SoundEffect.SoundEffect.UI_HOVER)
  
  # Test rapid firing (for aggregation)
  if Input.is_key_pressed(KEY_SPACE):
    if test_timer.is_stopped():
      test_timer.start(0.1)  # Fire every 0.1 seconds
  else:
    if not test_timer.is_stopped():
      test_timer.stop()

func _on_test_timer_timeout():
  # Play turret fire repeatedly to test aggregation
  AudioManager.play_sound(test_audio_player, Resource_SoundEffect.SoundEffect.TURRET_FIRE)
