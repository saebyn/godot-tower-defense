extends Node

var sound_effect_configs: Dictionary[Resource_SoundEffect.SoundEffect, Resource_SoundEffect] = {}

var sfx_directory: String = "res://Config/SoundEffects/"
var sfx_resource_extension: String = ".tres"


func _ready() -> void:
  # load resources from config directory into sound_effect_configs
  var dir = DirAccess.open(sfx_directory)
  if not dir:
    MyLogger.error("AudioManager", "Could not open sound effects directory: %s" % sfx_directory)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  while file_name != "":
    if file_name.ends_with(sfx_resource_extension):
      var file_path = sfx_directory + file_name
      var resource = ResourceLoader.load(file_path)
      if resource and resource is Resource_SoundEffect:
        sound_effect_configs[resource.get("sound_effect")] = resource
        MyLogger.debug("AudioManager", "Loaded sound effect: %s" % str(resource.get("sound_effect")))
      else:
        MyLogger.warn("AudioManager", "Failed to load sound effect from: %s" % file_path)

    file_name = dir.get_next()
  dir.list_dir_end()


func play_sound(audio_player: AudioStreamPlayer, effect: Resource_SoundEffect.SoundEffect) -> void:
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
func get_effect_config(effect: Resource_SoundEffect.SoundEffect) -> Resource_SoundEffect:
  return sound_effect_configs.get(effect, null)


## Get the category name as a string
func get_category_name(category: Resource_SoundEffect.SoundCategory) -> String:
  return Resource_SoundEffect.SoundCategory.keys()[category]