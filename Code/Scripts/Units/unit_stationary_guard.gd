class_name UnitStationaryGuard extends UnitBase

@onready var _unit_anims := %UnitAnimations as AnimationPlayer
@onready var _body := %BodyTransform as Node3D

var _damage_taken_rolling_dps := 0.0

func _ready() -> void:
	state_changed.connect(_on_state_changed)
	damage_taken.connect(_on_damage_taken)
	super._ready()


# Need to expose this here so an animation sequence can call it.
func damage_target():
	super.damage_target()


func _on_damage_taken(_me : UnitBase, damage_amount : float, new_health : float):
	_damage_taken_rolling_dps += damage_amount


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.DEFENDING)


func process_unit(delta : float) -> void:
	walk(0, delta)
	_damage_taken_rolling_dps *= pow(0.01, delta * 2)
	_body.rotation_degrees.z = (1.0 - 1.0 / (1.0 + _damage_taken_rolling_dps * 0.5)) * 30.0


func _on_targeting_timer():
	find_target()  # May trigger _on_target_acquired, if there is a target
