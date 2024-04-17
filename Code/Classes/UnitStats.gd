class_name UnitStats

# Movement
var move_speed : float
var move_acceleration : float
var gravity : float

# Defense
var max_health : float
var knockback_immunity : float
var damage_reduction : float

# Attack
var damage : float
var knockback : float
var reach_caster_damage : float
var cleave_efficiency : float



########################################
############# Movement #################
########################################

func get_modified_move_speed(combined_effects : CombatEffect) -> float:
	if combined_effects == null: return move_speed
	if combined_effects.modifier_move_speed == null: return move_speed
	return combined_effects.modifier_move_speed.apply(move_speed)

func get_modified_move_acceleration(_combined_effects : CombatEffect) -> float:
	return move_acceleration
	
func get_modified_gravity(combined_effects : CombatEffect) -> float:
	if combined_effects == null: return gravity
	if combined_effects.modifier_gravity == null: return gravity
	return combined_effects.modifier_gravity.apply(gravity)



########################################
############# Defense ##################
########################################

func get_modified_max_health(_combined_effects : CombatEffect) -> float:
	return max_health

func get_modified_knockback_immunity(_combined_effects : CombatEffect) -> float:
	return knockback_immunity
	
func get_modified_damage_reduction(_combined_effects : CombatEffect) -> float:
	return damage_reduction



########################################
############# Attack ###################
########################################

func get_modified_damage(combined_effects : CombatEffect) -> float:
	if combined_effects == null: return damage
	if combined_effects.modifier_damage == null: return damage
	return combined_effects.modifier_damage.apply(damage)

func get_modified_knockback(combined_effects : CombatEffect) -> float:
	if combined_effects == null: return knockback
	if combined_effects.modifier_knockback == null: return knockback
	return combined_effects.modifier_knockback.apply(knockback)

func get_modified_reach_caster_damage(_combined_effects : CombatEffect) -> float:
	return reach_caster_damage
	
func get_modified_cleave_efficiency(_combined_effects : CombatEffect) -> float:
	return cleave_efficiency

