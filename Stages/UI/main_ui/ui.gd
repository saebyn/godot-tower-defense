extends Control


signal obstacle_spawn_requested(obstacle_instance: Node3D)

@onready var spawn_indicator: Control = $SpawnIndicator
@onready var slot_ui_panel: SlotUIPanel = $SlotUIPanel

func request_obstacle_spawn(obstacle_instance: Node3D) -> void:
  obstacle_spawn_requested.emit(obstacle_instance)

## Called when an enemy spawns to show the spawn indicator (legacy)
func _on_enemy_spawned(enemy: Node3D) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_spawn_notification"):
    spawn_indicator.show_spawn_notification(enemy)
  # Also update wave progress if we have a current wave
  if spawn_indicator and spawn_indicator.has_method("_update_wave_display"):
    spawn_indicator._update_wave_display()

## Called when a wave starts to show wave information
func _on_wave_started(wave: Wave, wave_number: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_wave_started"):
    spawn_indicator.show_wave_started(wave, wave_number)

## Called when a wave is completed
func _on_wave_completed(wave: Wave, wave_number: int) -> void:
  if spawn_indicator and spawn_indicator.has_method("show_wave_completed"):
    spawn_indicator.show_wave_completed(wave, wave_number)

## Connect the slot UI panel to the slot manager
func setup_slot_ui(slot_manager: ObstacleSlotManager) -> void:
  if slot_ui_panel:
    slot_ui_panel.set_slot_manager(slot_manager)
    Logger.info("UI", "Slot UI panel connected to slot manager")