extends Resource
class_name Resource_AttackEffect

@export var damage_multiplier: float = 1.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 2.0
@export var crit_applies_to_splash: bool = false
@export var crit_applies_to_chain: bool = false
@export var aoe_radius: float = 0.0
@export var aoe_falloff: Curve = null
@export var chain_enabled: bool = false
@export var chain_radius: float = 0.0
@export var chain_max_hops: int = 0
@export var chain_falloff: Curve = null

## Stacks the effects of another Resource_AttackEffect onto this one.
## For each property, it adds the values together (for multipliers) or takes
## the value from the other effect if it's a boolean or a curve. 
## For boolean properties, if either effect has it set to true, the combined effect is true.
## This allows multiple effects to combine their properties when applied to an attack.
func stack_effect(other: Resource_AttackEffect):
  damage_multiplier += other.damage_multiplier
  crit_chance += other.crit_chance
  crit_multiplier += other.crit_multiplier
  crit_applies_to_splash = crit_applies_to_splash or other.crit_applies_to_splash
  crit_applies_to_chain = crit_applies_to_chain or other.crit_applies_to_chain
  aoe_radius += other.aoe_radius
  if other.aoe_falloff:
    aoe_falloff = other.aoe_falloff
  chain_enabled = chain_enabled or other.chain_enabled
  chain_radius += other.chain_radius
  chain_max_hops += other.chain_max_hops
  if other.chain_falloff:
    chain_falloff = other.chain_falloff