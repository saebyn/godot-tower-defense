extends Node

enum SoundEffect {
  PLAYER_ATTACK_HIT,
  ACHIEVEMENT_UNLOCKED,
}

enum SoundCategory {
  COMBAT,
  UI,
  AMBIENT,
  MUSIC,
}

# Configuration for each sound effect
class SoundEffectConfig:
  var samples: Array[AudioStream] = []
  var category: SoundCategory = SoundCategory.COMBAT
  var pitch_variation_min: float = 0.5
  var pitch_variation_max: float = 1.0
  
  func _init(p_samples: Array[AudioStream], p_category: SoundCategory, p_pitch_min: float = 0.5, p_pitch_max: float = 1.0):
    samples = p_samples
    category = p_category
    pitch_variation_min = p_pitch_min
    pitch_variation_max = p_pitch_max

var sound_effect_configs: Dictionary[SoundEffect, SoundEffectConfig] = {}


func _ready() -> void:
  sound_effect_configs = {
    SoundEffect.PLAYER_ATTACK_HIT: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"),
        preload("res://Assets/Audio/SFX/qubodupImpactMeat02.ogg"),
      ],
      SoundCategory.COMBAT,
      0.8,  # Min pitch
      1.2   # Max pitch
    ),
    SoundEffect.ACHIEVEMENT_UNLOCKED: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper achievement sound
      ],
      SoundCategory.UI,
      0.9,  # Min pitch
      1.1   # Max pitch
    ),
  }


func play_sound(audio_player: AudioStreamPlayer, effect: SoundEffect) -> void:
  if effect in sound_effect_configs:
    var config = sound_effect_configs[effect]
    if config.samples.is_empty():
      MyLogger.warn("AudioManager", "No samples configured for effect %s" % str(effect))
      return
    var random_sample_index = randi() % config.samples.size()
    audio_player.stream = config.samples[random_sample_index]
    audio_player.pitch_scale = config.pitch_variation_min + randf() * (config.pitch_variation_max - config.pitch_variation_min)
    audio_player.play()
  else:
    MyLogger.warn("AudioManager", "Sound effect %s not found!" % str(effect))


## Get the configuration for a sound effect
func get_effect_config(effect: SoundEffect) -> SoundEffectConfig:
  return sound_effect_configs.get(effect, null)


## Get the category name as a string
func get_category_name(category: SoundCategory) -> String:
  return SoundCategory.keys()[category]