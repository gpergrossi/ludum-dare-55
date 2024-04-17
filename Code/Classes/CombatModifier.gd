## Modifiers affect a SINGLE STAT.
class_name CombatModifier extends Resource

## Percent bonuses (like damage +30%) stack by adding together and THEN multiplying by base stats.
@export var percent_bonus : float = 0.0

## Flat bonuses are applied to stats AFTER the percent bonuses.
@export var flat_bonus : float = 0.0

## Multipliers are true multipliers, applied after both percent and flat bonuses. They stack multiplicatively.
@export var multiplier : float = 1.0


func _init(flat_bonus_ := 0.0, percent_bonus_ := 0.0, multiplier_ := 1.0):
	percent_bonus = percent_bonus_
	flat_bonus = flat_bonus_
	multiplier = multiplier_


## Produces a new modifier. Neither self nor other are changed.
func stack_with(other : CombatModifier) -> CombatModifier:
	return CombatModifier.new(percent_bonus + other.percent_bonus, flat_bonus + other.flat_bonus, multiplier * other.multiplier)


func apply(base_value : float) -> float:
	var result := base_value
	result *= 1.0 + (percent_bonus / 100.0)
	result += flat_bonus
	result *= multiplier
	return result


func _to_string():
	var parts : PackedStringArray = []
	if percent_bonus > 0.0:   
		parts.append("+" + str(int(percent_bonus)) + "%")
	if flat_bonus > 0.0:      
		parts.append("+" + str(int(flat_bonus)))
	if not is_zero_approx(multiplier - 1.0):      
		parts.append("x" + str(int(multiplier * 100.0)).insert(-2, "."))
	
	var result := ""
	for i in range(len(parts)):
		result += parts[i]
		if i < len(parts)-1:
			result += ",  "
	return result


## Overwrites curr_stack by combining with new_modifier.
static func add_stack_overwrite(curr_stack : CombatModifier, new_modifier : CombatModifier):
	curr_stack.percent_bonus += new_modifier.percent_bonus
	curr_stack.flat_bonus += new_modifier.flat_bonus
	curr_stack.multiplier *= new_modifier.multiplier


## Overwrites curr_stack by combining with new_modifier.
static func multiply_stack_overwrite(curr_stack : CombatModifier, multiplier_ : float):
	curr_stack.percent_bonus *= multiplier_
	curr_stack.flat_bonus *= multiplier_
	curr_stack.multiplier = pow(curr_stack.multiplier, multiplier_)
