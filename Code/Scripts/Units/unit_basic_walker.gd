class_name UnitBasicWalker extends UnitBase

@export var attack_interval := 1.0

@onready var _unit_anims := %UnitAnimations as AnimationPlayer
@onready var _targeting_timer := %TargetingTimer as Timer


func _ready() -> void:
	state_changed.connect(_on_state_changed)
	target_acquired.connect(_on_target_acquired)
	target_lost.connect(_on_target_lost)
	target_dead.connect(_on_target_dead)
	_targeting_timer.timeout.connect(_on_targeting_timer)
	super._ready()


# Need to expose this here so an animation sequence can call it.
func damage_target():
	super.damage_target()


func _on_target_acquired(_me : UnitBase, _target : UnitBase):
	change_state(UnitState.ATTACKING)


func _on_target_lost(_me : UnitBase, _prev_target : UnitBase):
	change_state(UnitState.MOVING)


func _on_target_dead(_me : UnitBase, _prev_target : UnitBase):
	change_state(UnitState.MOVING)


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(old_state):
		UnitState.MOVING:
			_targeting_timer.stop()
	
	match(new_state):
		UnitState.INITIALIZE:
			change_state(UnitState.MOVING) 
		
		UnitState.MOVING: 
			_unit_anims.play("walk")
			# Slight random offset to target timer so they don't synchronize.
			_targeting_timer.start(attack_interval * 0.1 * (1.0 + randf()))
		
		UnitState.ATTACKING:
			_unit_anims.play("attack")
		
		_:
			_unit_anims.stop()


func process_unit(delta : float) -> void:
	match(_state):
		UnitState.MOVING:
			walk(top_speed, delta)
		UnitState.ATTACKING:
			# This is necessary for them to stop moving when knockback sends them sliding
			walk(0, delta)


func _on_targeting_timer():
	internal_find_target()  # May trigger _on_target_acquired, if there is a target
