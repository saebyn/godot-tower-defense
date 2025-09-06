"""
Test script to validate EnemySpawner functionality in both modes.
This would be used manually in the Godot editor to test the functionality.
"""
extends Node3D

@export var test_legacy_mode: bool = false
@export var test_wave_mode: bool = false

func _ready():
	if test_legacy_mode:
		_test_legacy_mode()
	elif test_wave_mode:
		_test_wave_mode()

func _test_legacy_mode():
	print("Testing Legacy Mode...")
	
	# Create a spawner without Wave children
	var spawner = preload("res://Common/Systems/spawner/enemy_spawner.tscn").instantiate()
	add_child(spawner)
	
	# It should use legacy mode automatically
	await get_tree().create_timer(2.0).timeout
	print("Legacy mode test completed")

func _test_wave_mode():
	print("Testing Wave Mode...")
	
	# Create a spawner with Wave children
	var spawner = preload("res://Common/Systems/spawner/enemy_spawner.tscn").instantiate()
	
	# Add a test wave
	var wave = preload("res://Common/Systems/spawner/wave.tscn").instantiate()
	wave.duration = 5.0
	wave.enemy_scenes = [preload("res://Entities/Enemies/Templates/base_enemy/enemy.tscn")]
	wave.enemy_counts = [3]
	wave.spawn_interval = 1.0
	
	spawner.add_child(wave)
	add_child(spawner)
	
	# Connect signals
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_completed.connect(_on_wave_completed)
	spawner.all_waves_completed.connect(_on_all_waves_completed)
	
	print("Wave mode test setup completed")

func _on_wave_started(wave):
	print("Test: Wave started!")

func _on_wave_completed(wave):
	print("Test: Wave completed!")

func _on_all_waves_completed():
	print("Test: All waves completed!")