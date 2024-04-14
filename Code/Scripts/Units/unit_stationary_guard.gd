class_name UnitStationaryGuard extends UnitBase

@onready var _unit_anims := %UnitAnimations as AnimationPlayer


func _ready() -> void:
	state_changed.connect(_on_state_changed)
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
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.DEFENDING)


func process_unit(delta : float) -> void:
	walk(0, delta)


func _on_targeting_timer():
	find_target()  # May trigger _on_target_acquired, if there is a target
