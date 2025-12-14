extends Resource
class_name Resource_SoundEffect


enum SoundEffect {
  DEFAULT = 0, # Use this if no specific sound effect is assigned
  PLAYER_ATTACK_HIT = 1,
  TURRET_FIRE = 2,
  TURRET_IDLE = 3,
  ZOMBIE_DEATH = 4,
  SURVIVOR_DEATH = 5,
  SCRAP_PICKUP = 6,
  BUILDING_PLACEMENT = 7,
  BUILDING_PROGRESS = 8,
  BUILDING_COMPLETE = 9,
  ELECTRIC_CRACKLE = 10,
  FIRE_CRACKLE = 11,
  ZOMBIE_IDLE_GROAN = 12,
  UI_CONFIRM = 13,
  ERROR = 14,
  ACHIEVEMENT_UNLOCKED = 15,

  BUILDING_DAMAGED = 16,
  BUILDING_DESTROYED = 17,

  NONE = 18, # No sound effect

  SURVIVOR_HIT = 19,
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