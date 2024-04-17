class_name UnitPumpkin extends UnitBase

@export var roll_top_speed := 150.0   # Affects damage scaling from 0.5x (at walk speed) to 1x (at top speed)
@export var roll_top_speed_time := 3.0

@export var accel_effect_max_slope := 0.3
@export var accel_affect_weight := 0.2

@onready var _unit_anims := %UnitAnimations as AnimationPlayer

var _damage_tick_accum_time := 0.0
var _rolling_accum_time := 0.0

func _virtual_ready() -> void:
	state_changed.connect(_on_state_changed)
	_unit_targeting.target_acquired.connect(_on_target_acquired)


func _on_target_acquired(new_target : UnitBase, _new_count : int):
	match(_state):
		UnitTypeDefs.UnitState.MOVING:
			change_state(UnitTypeDefs.UnitState.ATTACKING)
		
		UnitTypeDefs.UnitState.ATTACKING:
			var base_move_speed := get_move_speed()
			var speed_t := (absf(_velocity.x) - base_move_speed) / (roll_top_speed - base_move_speed)
			var velocity_scaling := lerpf(0.5, 1.0, speed_t)
			var velocity_based_damage := self.get_damage() * velocity_scaling
			var velocity_based_knockback := self.get_knockback() * velocity_scaling
			new_target.take_damage(velocity_based_damage, velocity_based_knockback)


func _on_state_changed(_me : UnitBase, new_state : UnitTypeDefs.UnitState, _old_state : UnitTypeDefs.UnitState):
	match(new_state):
		UnitTypeDefs.UnitState.INITIALIZE:
			change_state(UnitTypeDefs.UnitState.MOVING) 
		
		UnitTypeDefs.UnitState.MOVING: 
			_unit_anims.play("walking")
		
		UnitTypeDefs.UnitState.ATTACKING:
			_unit_anims.play("attacking")
		
		_:
			_unit_anims.stop()


func process_unit(delta : float) -> void:
	_damage_tick_accum_time += delta
	
	var slope := -get_ground_slope(_position.x) * get_facing_x()
	
	match(_state):
		UnitTypeDefs.UnitState.MOVING:
			move_forward(get_move_speed(), delta)
			if slope > 0.2:
				change_state(UnitTypeDefs.UnitState.ATTACKING)
		
		UnitTypeDefs.UnitState.ATTACKING:
			var slope_modifier := 1.0 + remap(slope, -accel_effect_max_slope, accel_effect_max_slope, -accel_affect_weight, accel_affect_weight)
			_rolling_accum_time += delta * slope_modifier
			
			var rolling_t := minf(1.0, _rolling_accum_time / roll_top_speed_time)
			var curr_speed := lerpf(get_move_speed(), roll_top_speed, rolling_t)
			move_forward(curr_speed, delta)
