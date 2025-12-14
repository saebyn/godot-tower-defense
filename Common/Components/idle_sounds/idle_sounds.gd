extends Node3D
class_name Component_IdleSounds

@export var idle_sound: Resource_SoundEffect.SoundEffect = Resource_SoundEffect.SoundEffect.DEFAULT
@export var audio_player: AudioStreamPlayer3D
@export var min_idle_interval: float = 5.0 ## Minimum time between idle sounds (in seconds)
@export var max_idle_interval: float = 15.0 ## Maximum time between idle sounds (in seconds)

var _idle_timer: Timer

func _ready():
  # Setup idle timer
  _idle_timer = Timer.new()
  _idle_timer.wait_time = randf_range(min_idle_interval, max_idle_interval)
  _idle_timer.one_shot = true
  _idle_timer.autostart = true
  _idle_timer.connect("timeout", _on_idle_timer_timeout)
  add_child(_idle_timer)

  if not audio_player:
    MyLogger.warn("IdleSounds", "No AudioStreamPlayer3D assigned for idle sounds.")
  
  MyLogger.debug("IdleSounds", "IdleSounds component initialized (interval: %fs - %fs)" % [min_idle_interval, max_idle_interval])

func _on_idle_timer_timeout():
  if audio_player:
    AudioManager.play_sound(audio_player, idle_sound)
  
  # Reset timer with new random interval
  _idle_timer.wait_time = randf_range(min_idle_interval, max_idle_interval)
  _idle_timer.start()