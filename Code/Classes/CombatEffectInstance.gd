class_name CombatEffectInstance extends Object

var _effect : CombatEffect
var _stack_count := 0

var _time_remaining := 0.0
var _multiply_effect := false
var _lose_all_stacks_on_expire := false
var _use_independent_timers := false

var _local_time : float
var _independent_end_times := [] as PackedFloat32Array

signal on_effect_stacks_changed(delta_stacks : int, new_count : int, effect_getter : Callable)


func _init(effect : CombatEffect):
	_effect = effect
	add_stack()


func add_stack():
	if _stack_count == _effect.effect_max_stacks:
		if not _effect.extra_stacks_restore_duration:
			return
	
	match (_effect.effect_stacking_mode):
		CombatEffect.StackingMode.NO_STACKING:
			_time_remaining = maxf(_time_remaining, _effect.effect_duration)
			_multiply_effect = false
			_lose_all_stacks_on_expire = true
			_use_independent_timers = false
			_independent_end_times.clear()
		
		CombatEffect.StackingMode.ONLY_DURATIONS:
			_time_remaining += _effect.effect_duration
			_multiply_effect = false
			_lose_all_stacks_on_expire = true
			_use_independent_timers = false
			_independent_end_times.clear()
		
		CombatEffect.StackingMode.IN_SEQUENCE:
			_time_remaining = maxf(_time_remaining, _effect.effect_duration)
			_multiply_effect = true
			_lose_all_stacks_on_expire = false
			_use_independent_timers = false
			_independent_end_times.clear()
		
		CombatEffect.StackingMode.EFFECT_AND_DURATION:
			_time_remaining += _effect.effect_duration
			_multiply_effect = true
			_lose_all_stacks_on_expire = false
			_use_independent_timers = false
			_independent_end_times.clear()
			
		CombatEffect.StackingMode.TRUE_INDEPENDENT:
			_time_remaining = maxf(_time_remaining, _effect.effect_duration)
			_multiply_effect = true
			_lose_all_stacks_on_expire = false
			_use_independent_timers = true
			if len(_independent_end_times) == _effect.effect_max_stacks:
				_independent_end_times.remove_at(0)
			_independent_end_times.append(_local_time + _effect.effect_duration)
	
	_stack_count += 1
	if _stack_count > _effect.effect_max_stacks:
		_stack_count = _effect.effect_max_stacks
	else:
		do_on_stacks_changed(1)
	
	_time_remaining = minf(_time_remaining, _stack_count * _effect.effect_duration)


func get_multiplied_effect() -> CombatEffect:
	if _multiply_effect:
		return _effect.multiply(_stack_count)
	else:
		return _effect.duplicate(true)


func process(delta : float):
	_local_time += delta
	if _stack_count == 0:
		_time_remaining = -1.0
		return
	
	if _use_independent_timers:
		_time_remaining -= delta
		
		# How many timers have expired?
		var expire_count := 0
		while expire_count < len(_independent_end_times) and _independent_end_times[expire_count] <= _local_time:
			expire_count += 1
		
		if expire_count > 0:
			_stack_count -= expire_count
			_independent_end_times = _independent_end_times.slice(expire_count)
			do_on_stacks_changed(-expire_count)
	
	else:
		_time_remaining -= delta
		if _time_remaining <= 0.0:
			if _lose_all_stacks_on_expire:
				var _prev_count = _stack_count
				_stack_count = 0
				_time_remaining = -1
				do_on_stacks_changed(_prev_count)
			else:
				_stack_count -= 1
				if _stack_count > 0:
					_time_remaining += _effect.effect_duration
				else:
					_time_remaining = -1
				do_on_stacks_changed(-1)


func do_on_stacks_changed(delta_stacks : int):
	print("Effect stack changed: " + str(_stack_count) + " (" + str(_time_remaining) + " seconds remaining)")
	on_effect_stacks_changed.emit(delta_stacks, _stack_count, self.get_multiplied_effect)
