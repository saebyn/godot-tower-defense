"""
# DefaultAttackEffects.gd

Script to create and configure the default attack effects database.
This is used to generate the default_attack_effects.tres resource.
"""
extends Resource

static func create_default_database() -> AttackEffectDatabase:
	var database = AttackEffectDatabase.new()
	
	# None effect (no visual)
	var none_effect = AttackEffectResource.new()
	none_effect.effect_name = "None"
	none_effect.effect_scene = null
	none_effect.description = "No visual effect"
	database.add_effect(none_effect)
	
	# Bullet effect
	var bullet_effect = AttackEffectResource.new()
	bullet_effect.effect_name = "Bullet"
	bullet_effect.effect_scene = preload("res://Common/Effects/attack_effects/bullet_attack_effect.tscn")
	bullet_effect.effect_parameters = {
		"bullet_speed": 20.0,
		"bullet_color": Color.YELLOW
	}
	bullet_effect.description = "Fast-moving yellow projectile with glowing emission"
	database.add_effect(bullet_effect)
	
	# Fireball effect
	var fireball_effect = AttackEffectResource.new()
	fireball_effect.effect_name = "Fireball"
	fireball_effect.effect_scene = preload("res://Common/Effects/attack_effects/fireball_attack_effect.tscn")
	fireball_effect.effect_parameters = {
		"projectile_speed": 15.0,
		"fireball_color": Color.ORANGE
	}
	fireball_effect.description = "Orange fireball with particle trail and explosion on impact"
	database.add_effect(fireball_effect)
	
	# Magic Sparkles effect
	var magic_effect = AttackEffectResource.new()
	magic_effect.effect_name = "Magic Sparkles"
	magic_effect.effect_scene = preload("res://Common/Effects/attack_effects/magic_sparkles_attack_effect.tscn")
	magic_effect.effect_parameters = {
		"projectile_speed": 25.0,
		"sparkle_color": Color.CYAN
	}
	magic_effect.description = "Cyan magical projectile with sparkle trail and arcing movement"
	database.add_effect(magic_effect)
	
	# Laser Beam effect
	var laser_effect = AttackEffectResource.new()
	laser_effect.effect_name = "Laser Beam"
	laser_effect.effect_scene = preload("res://Common/Effects/attack_effects/laser_beam_attack_effect.tscn")
	laser_effect.effect_parameters = {
		"beam_duration": 0.3,
		"laser_color": Color.RED
	}
	laser_effect.description = "Instant red laser beam with impact particles"
	database.add_effect(laser_effect)
	
	return database