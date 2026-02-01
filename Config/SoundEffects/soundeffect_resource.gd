extends Resource
class_name Resource_SoundEffect


enum SoundEffect {
  DEFAULT = 0,  ## Use this if no specific sound effect is assigned

  # User action sound effects
  PLAYER_ATTACK_HIT = 1,
  SCRAP_PICKUP = 6,

  # Combat related sound effects
  ZOMBIE_DEATH = 4,
  TURRET_FIRE = 2,
  TURRET_IDLE = 3,
  SURVIVOR_DEATH = 5,
  SURVIVOR_YELP = 25,  ## When a survivor is panicked but not hurt
  SURVIVOR_HIT = 19,  ## When a survivor takes damage
  ZOMBIE_ATTACK = 24,  ## When a zombie attacks a survivor or building
  WAVE_START = 27,  ## When a new wave of zombies starts
  WAVE_COMPLETE = 28,  ## When a wave of zombies is fully defeated
  SCENARIO_COMPLETE = 29,  ## When the player completes the scenario

  # Ambient sound effects
  ELECTRIC_CRACKLE = 10,
  FIRE_CRACKLE = 11,
  ZOMBIE_IDLE_GROAN = 12,

  # UI related sound effects
  UI_CONFIRM = 13,
  UI_CANCEL = 20,
  UI_HOVER = 22,
  ERROR = 14,
  TECH_UNLOCKED = 26,
  ACHIEVEMENT_UNLOCKED = 15,
  PLAYER_LEVEL_UP = 30,

  # Building related sound effects
  BUILDING_DAMAGED = 16,  ## When a building takes damage
  BUILDING_DESTROYED = 17,  ## When a building is destroyed
  BUILDING_PLACEMENT = 7,  ## (not yet used) When a building is placed (this is after placement preview)
  BUILDING_PROGRESS = 8,  ## (not yet used) When progressing building construction
  BUILDING_COMPLETE = 9,  ## When building construction is complete (presently when placement is finished)
  BUILDING_REMOVED = 21,  ## When a building is removed/dismantled by the player
  BUILDING_UPGRADED = 23,  ## (not yet used) When a building is upgraded

  NONE = 18,  ## No sound effect at all
}

enum SoundCategory {
  USER_INTERFACE,
  COMBAT,
  BUILDING,
  AMBIENCE,
  PLAYER_ACTION,
}

@export var sound_effect: SoundEffect = SoundEffect.DEFAULT
@export var samples: Array[AudioStream] = []
@export var category: SoundCategory = SoundCategory.COMBAT
@export_range(0.0, 2.0) var pitch_variation_min: float = 0.9
@export_range(0.0, 2.0) var pitch_variation_max: float = 1.1
@export_range(-80.0, 24.0, 0.1) var volume_db: float = 0.0