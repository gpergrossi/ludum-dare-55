# An editor defined stat block. Not editable at runtime.
class_name UnitStatsResource extends Resource

@export_category("Unit Stats")

@export_group("Movement")
@export var move_speed := 10.0
@export var move_acceleration := 100.0
@export var gravity := 40.0

@export_group("Attack")
@export var damage := 30
@export var knockback := 10
@export var reach_caster_damage := 10
@export_range(0.0, 1.0) var cleave_efficiency := 0.0

@export_group("Defense")
@export var max_health := 100

## Reduce all damage taken by a flat amount, to a minimum of 1.
@export var damage_reduction : int = 0

## All knockback dealt to this unit will be multiplied by (1.0 - knockback_immunity).
@export_range(0.0, 1.0) var knockback_immunity := 0.0


func get_stats() -> UnitStats:
	var stats := UnitStats.new()
	stats.move_speed = move_speed
	stats.move_acceleration = move_acceleration
	stats.gravity = gravity
	
	stats.damage = damage
	stats.knockback = knockback
	stats.reach_caster_damage = reach_caster_damage
	stats.cleave_efficiency = cleave_efficiency
	
	stats.max_health = max_health
	stats.damage_reduction = damage_reduction
	stats.knockback_immunity = knockback_immunity
	return stats
