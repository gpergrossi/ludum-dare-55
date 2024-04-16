class_name UnitPumpkin extends UnitBase

@export var roll_top_speed := 100.0
@export var hit_interval := 0.01

const begin_slope := -0.08
const end_slope := 1.5

@onready var _unit_anims := %UnitAnimations as AnimationPlayer

var _accum_time := 0.0

func _ready() -> void:
	state_changed.connect(_on_state_changed)
	_unit_targeting.target_acquired.connect(_on_target_acquired)
	super._ready()


func _on_target_acquired(new_target : UnitBase, new_count : int):
	if _state == UnitState.ATTACKING:
		new_target.take_damage(self.damage, self.knockback)


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(old_state):
		UnitState.ATTACKING:
			_unit_targeting.pause()
	
	match(new_state):
		UnitState.INITIALIZE:
			change_state(UnitState.MOVING) 
		
		UnitState.MOVING: 
			_unit_anims.play("walking")
		
		UnitState.ATTACKING:
			_unit_anims.play("attacking")
			_unit_targeting.resume()
		
		_:
			_unit_anims.stop()


func process_unit(delta : float) -> void:
	_accum_time += delta
	
	match(_state):
		UnitState.MOVING:
			walk(top_speed, delta)
			if get_ground_slope(_position.x) * get_facing_x() < begin_slope:
				change_state(UnitState.ATTACKING)
		
		UnitState.ATTACKING:
			walk(roll_top_speed, delta)
			if _accum_time > hit_interval:
				_accum_time -= hit_interval
				_unit_targeting.search_now()
			
			if get_ground_slope(_position.x) * get_facing_x() > end_slope:
				change_state(UnitState.MOVING)
			
