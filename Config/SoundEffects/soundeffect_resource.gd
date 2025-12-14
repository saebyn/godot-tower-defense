extends Resource
class_name Resource_SoundEffect


enum SoundEffect {
  DEFAULT, # Use this if no specific sound effect is assigned
  PLAYER_ATTACK_HIT,
  TURRET_FIRE,
  ZOMBIE_DEATH,
  SURVIVOR_DEATH,
  SCRAP_PICKUP,
  BUILDING_PLACEMENT,
  BUILDING_PROGRESS,
  BUILDING_COMPLETE,
  ELECTRIC_CRACKLE,
  FIRE_CRACKLE,
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

@export var sound_effect: SoundEffect = SoundEffect.DEFAULT
@export var samples: Array[AudioStream] = []
@export var category: SoundCategory = SoundCategory.COMBAT
@export_range(0.0, 2.0) var pitch_variation_min: float = 0.9
@export_range(0.0, 2.0) var pitch_variation_max: float = 1.1