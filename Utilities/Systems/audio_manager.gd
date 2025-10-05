extends Node

enum SoundEffect {
  PLAYER_ATTACK_HIT,
}

var sound_effects: Dictionary[SoundEffect, Array] = {}


func _ready() -> void:
  sound_effects = {
    SoundEffect.PLAYER_ATTACK_HIT: [
      preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"),
      preload("res://Assets/Audio/SFX/qubodupImpactMeat02.ogg"),
    ],
  }


func play_sound(audio_player: AudioStreamPlayer, effect: SoundEffect) -> void:
  if effect in sound_effects:
    var random_sample_index = randi() % sound_effects[effect].size()
    audio_player.stream = sound_effects[effect][random_sample_index]
    audio_player.pitch_scale = 0.5 + randf() * 0.5 # Randomize pitch slightly
    audio_player.play()
  else:
    Logger.warn("AudioManager", "Sound effect %s not found!" % str(effect))