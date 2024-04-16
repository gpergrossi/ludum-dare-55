class_name UnitTomatoPlant extends UnitBase

@export var attack_interval := 0.5

@onready var _body := %BodyTransform as Node3D
@onready var _attack_timer := %AttackTimer

var _damage_taken_rolling_dps := 0.0

func _ready() -> void:
	state_changed.connect(_on_state_changed)
	_attack_timer.timeout.connect(_on_attack_timer)
	damage_taken.connect(_on_damage_taken)
	super._ready()


func _on_state_changed(_me : UnitBase, new_state : UnitTypeDefs.UnitState, _old_state : UnitTypeDefs.UnitState):
	match(new_state):
		UnitTypeDefs.UnitState.INITIALIZE: 
			change_state(UnitTypeDefs.UnitState.DEFENDING)
		UnitTypeDefs.UnitState.DEFENDING:
			_attack_timer.start()


func _on_damage_taken(_me : UnitBase, damage_amount : float, _new_health : float):
	_damage_taken_rolling_dps += damage_amount


func process_unit(delta : float) -> void:
	walk(0, delta)
	_damage_taken_rolling_dps *= pow(0.01, delta * 2)
	_body.rotation_degrees.z = (1.0 - 1.0 / (1.0 + _damage_taken_rolling_dps * 0.5)) * 30.0


func _on_attack_timer():
	for target in _unit_targeting.get_targets():
		var spell_def := {
			"target": target
		}
		_manager.summon(UnitTypeDefs.UnitType.TOMATO_PROJECTILE, spell_def, _position, team)
	
	# Restart attack timer
	_attack_timer.wait_time = attack_interval + randf() * 0.2
	_attack_timer.start()
