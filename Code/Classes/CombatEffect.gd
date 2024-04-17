class_name CombatEffect extends Resource

## The stacking modes below work together with a stack count and a boolean:
## "extra_stacks_restore_duration", which allows stacks beyond the max_stack size 
## to restore duration up to max_stacks * duration, when the stacking mode allows.
enum StackingMode {
	## Only one copy of the modifiers is applied. On expire, all stacks are removed. Additional stacks restore duration up to 1x duration.
	NO_STACKING,
	
	## Only one copy of the modifiers is applied. On expire, all stacks are removed. Additional stacks extend/restore the total duration up to max_stacks * duration.
	ONLY_DURATIONS,
	
	## Modifiers are multiplied by current stack count. Each stack expires one at a time. After a stack expires, the stack count is reduce by one and the timer is reset to 1x duration.
	IN_SEQUENCE,
	
	## Modifiers are multiplied by current stack count. On expire, all stacks are removed. Additional stacks extend the total time up to max_stacks * duration.
	EFFECT_AND_DURATION,
	
	## Modifiers are multiplied by current stack count. Simulates each stack's duration independently.
	TRUE_INDEPENDENT
}



@export_category("CombatEffect")
@export var effect_name : String
@export var effect_duration := 1.0

@export_group("Stacking")
## When the duration expires, it will remove ONE stack and reset the timer.
@export var effect_stacking_mode := StackingMode.NO_STACKING

## The maximum number of times this effect can be stacked.
@export var effect_max_stacks := 1

## If the stack count is already at max, additional stacks will still be allowed to reset the timer / add their duration to the stack up to the total max duration (based on stacking mode).
@export var extra_stacks_restore_duration := true



@export_group("Stat Modifiers")
const modifier_properties : Array[StringName] = ["modifier_move_speed", "modifier_gravity", "modifier_damage", "modifier_knockback"]

@export var modifier_move_speed : CombatModifier
@export var modifier_gravity : CombatModifier

@export var modifier_damage : CombatModifier
@export var modifier_knockback : CombatModifier




func multiply(multiplier : float) -> CombatEffect:
	var copy := duplicate(true) as CombatEffect
	copy.print_effects()
	CombatEffect.multiply_stack_overwrite(copy, multiplier)
	return copy


func add(other : CombatEffect) -> CombatEffect:
	var copy := duplicate(true)
	CombatEffect.add_stack_overwrite(copy, other)
	return copy


func print_effects():
	for property in modifier_properties:
		if get(property) != null:
			print(property + ":  " + (get(property) as CombatModifier).to_string())


static func add_stack_overwrite(curr_stack : CombatEffect, new_effect : CombatEffect):
	for property in modifier_properties:
		CombatEffect._add_stack_overwrite_one_stat(property, curr_stack, new_effect)


static func _add_stack_overwrite_one_stat(property : String, curr_stack : CombatEffect, new_effect : CombatEffect):
	var curr_value = curr_stack.get(property)
	var other_value = new_effect.get(property)
	
	if curr_value == null:
		curr_stack.set(property, other_value)
	elif other_value != null:
		curr_stack.set(property, CombatModifier.add_stack_overwrite(curr_value, other_value))


static func multiply_stack_overwrite(curr_stack : CombatEffect, multiplier : float):
	for property in modifier_properties:
		CombatEffect._multiply_stack_overwrite_one_stat(property, curr_stack, multiplier)


static func _multiply_stack_overwrite_one_stat(property : String, curr_stack : CombatEffect, multiplier : float):
	var curr_value = curr_stack.get(property) as CombatModifier
	if curr_value == null:  return
	CombatModifier.multiply_stack_overwrite(curr_value, multiplier)
