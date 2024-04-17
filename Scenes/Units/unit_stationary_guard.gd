class_name UnitStationaryGuard extends UnitBase

@onready var sound := %"Lettuce Crunch Sound Player" as AudioStreamPlayer;
@onready var _body := %BodyTransform as Node3D

var _damage_taken_rolling_dps := 0.0

func _virtual_ready() -> void:
	state_changed.connect(_on_state_changed)
	damage_taken.connect(_on_damage_taken)


func _on_damage_taken(_me : UnitBase, damage_amount : float, _new_health : float):
	_damage_taken_rolling_dps += damage_amount
	sound.play();


func _on_state_changed(_me : UnitBase, new_state : UnitTypeDefs.UnitState, _old_state : UnitTypeDefs.UnitState):
	match(new_state):
		UnitTypeDefs.UnitState.INITIALIZE: 
			change_state(UnitTypeDefs.UnitState.DEFENDING)


func process_unit(delta : float) -> void:
	move_forward(0, delta)
	_damage_taken_rolling_dps *= pow(0.01, delta * 2)
	_body.rotation_degrees.z = (1.0 - 1.0 / (1.0 + _damage_taken_rolling_dps * 0.5)) * 30.0