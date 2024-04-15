class_name UnitFlyingBomber extends UnitBase

@onready var _unit_anims := %UnitAnimations as AnimationPlayer
@onready var _body := %BodyTransform as Node3D


func _ready() -> void:
	state_changed.connect(_on_state_changed)
	super._ready()


# Need to expose this here so an animation sequence can call it.
func damage_target():
	super.damage_target()


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.DEFENDING)


func process_unit(delta : float) -> void:
	walk(0, delta, true)


func _on_targeting_timer():
	find_target()  # May trigger _on_target_acquired, if there is a target
