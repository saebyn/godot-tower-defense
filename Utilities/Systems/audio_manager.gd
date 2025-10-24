extends Node

enum SoundEffect {
  PLAYER_ATTACK_HIT,
  ACHIEVEMENT_UNLOCKED,
}

var sound_effects: Dictionary[SoundEffect, Array] = {}


func _ready() -> void:
  sound_effects = {
    SoundEffect.PLAYER_ATTACK_HIT: [
      preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"),
      preload("res://Assets/Audio/SFX/qubodupImpactMeat02.ogg"),
    ],
    SoundEffect.ACHIEVEMENT_UNLOCKED: [
      preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper achievement sound
    ],
  }


func play_sound(audio_player: AudioStreamPlayer, effect: SoundEffect) -> void:
  if effect in sound_effects:
    var samples = sound_effects[effect]
    if samples.is_empty():
      Logger.warn("AudioManager", "No samples configured for effect %s" % str(effect))
      return
    var random_sample_index = randi() % samples.size()
    audio_player.stream = samples[random_sample_index]
    audio_player.pitch_scale = 0.5 + randf() * 0.5 # Randomize pitch slightly
    audio_player.play()
  else:
    Logger.warn("AudioManager", "Sound effect %s not found!" % str(effect))