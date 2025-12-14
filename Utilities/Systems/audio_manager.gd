extends Node

enum SoundEffect {
  PLAYER_ATTACK_HIT,
  TURRET_FIRE,
  ZOMBIE_DEATH,
  SCRAP_PICKUP,
  BUILDING_PLACEMENT,
  BUILDING_PROGRESS,
  BUILDING_COMPLETE,
  ELECTRIC_CRACKLE,
  ZOMBIE_IDLE_GROAN,
  UI_CONFIRM,
  ERROR,
  ACHIEVEMENT_UNLOCKED,
}

enum SoundCategory {
  USER_INTERFACE,
  COMBAT,
  BUILDING,
  AMBIENCE,
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
      0.8, # Min pitch
      1.2 # Max pitch
    ),
    SoundEffect.TURRET_FIRE: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper turret fire sound
      ],
      SoundCategory.COMBAT,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.ZOMBIE_DEATH: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper zombie death sound
      ],
      SoundCategory.COMBAT,
      0.7, # Min pitch
      1.3 # Max pitch
    ),
    SoundEffect.SCRAP_PICKUP: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper scrap pickup sound
      ],
      SoundCategory.USER_INTERFACE,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.BUILDING_PLACEMENT: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper building placement sound
      ],
      SoundCategory.BUILDING,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.BUILDING_PROGRESS: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper building progress sound
      ],
      SoundCategory.BUILDING,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.BUILDING_COMPLETE: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper building complete sound
      ],
      SoundCategory.BUILDING,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.ELECTRIC_CRACKLE: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper electric crackle sound
      ],
      SoundCategory.AMBIENCE,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.ZOMBIE_IDLE_GROAN: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper zombie idle groan sound
      ],
      SoundCategory.AMBIENCE,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.UI_CONFIRM: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper UI confirm sound
      ],
      SoundCategory.USER_INTERFACE,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.ERROR: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper error sound
      ],
      SoundCategory.USER_INTERFACE,
      0.9, # Min pitch
      1.1 # Max pitch
    ),
    SoundEffect.ACHIEVEMENT_UNLOCKED: SoundEffectConfig.new(
      [
        preload("res://Assets/Audio/SFX/qubodupImpactMeat01.ogg"), # Placeholder - needs proper achievement sound
      ],
      SoundCategory.USER_INTERFACE,
      0.9, # Min pitch
      1.1 # Max pitch
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
