extends Node

## MusicManager - Manages background music state based on game state and settings
##
## Handles pausing/resuming music when the game is paused based on user preferences

var music_player: AudioStreamPlayer = null

func _ready() -> void:
  # Connect to GameManager state changes
  GameManager.game_state_changed.connect(_on_game_state_changed)
  Logger.info("MusicManager", "Music Manager initialized")

## Set the music player that this manager will control
func set_music_player(player: AudioStreamPlayer) -> void:
  music_player = player
  Logger.debug("MusicManager", "Music player set")

## Handle game state changes to pause/resume music as needed
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
  if music_player == null:
    return
  
  # Check if we should pause music when entering IN_GAME_MENU
  if new_state == GameManager.GameState.IN_GAME_MENU:
    if SettingsManager.pause_music_on_pause:
      music_player.stream_paused = true
      Logger.debug("MusicManager", "Music paused (game paused)")
  elif new_state == GameManager.GameState.PLAYING:
    # Resume music when returning to gameplay (if it was paused)
    if music_player.stream_paused:
      music_player.stream_paused = false
      Logger.debug("MusicManager", "Music resumed (game resumed)")
