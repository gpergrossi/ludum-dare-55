class_name UnitBasicWalker extends UnitBase

@export var attack_interval := 1.0
@onready var sound := %"Broccoli Spear Sound Player" as AudioStreamPlayer;
@onready var _unit_anims := %UnitAnimations as AnimationPlayer


func _ready() -> void:
	state_changed.connect(_on_state_changed)
	_unit_targeting.target_acquired.connect(_on_target_acquired)
	_unit_targeting.target_lost.connect(_on_target_lost)
	_unit_targeting.target_killed.connect(_on_target_killed)
	super._ready()


# Need to expose this here so an animation sequence can call it.
func damage_target():
	super.damage_targets();
	sound.play();


func _on_target_acquired(_new_target : UnitBase, _new_target_count : int):
	change_state(UnitState.ATTACKING)


func _on_target_lost(_new_target : UnitBase, _new_target_count : int):
	change_state(UnitState.MOVING)


func _on_target_killed(_new_target : UnitBase, _new_target_count : int):
	change_state(UnitState.MOVING)


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(old_state):
		UnitState.MOVING:
			_unit_targeting.pause()
	
	match(new_state):
		UnitState.INITIALIZE:
			change_state(UnitState.MOVING) 
		
		UnitState.MOVING: 
			_unit_anims.play("walking")
			_unit_targeting.resume()
		
		UnitState.ATTACKING:
			_unit_anims.play("attacking")
		
		_:
			_unit_anims.stop()


func process_unit(delta : float) -> void:
	match(_state):
		UnitState.MOVING:
			walk(top_speed, delta)
		
		UnitState.ATTACKING:
			# This is necessary for them to stop moving when knockback sends them sliding
			walk(0, delta)
