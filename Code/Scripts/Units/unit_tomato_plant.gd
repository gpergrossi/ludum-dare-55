class_name UnitTomatoPlant extends UnitBase

@export var attack_interval := 0.5

@onready var _body := %BodyTransform as Node3D
@onready var _attack_timer := %AttackTimer

func _ready() -> void:
	state_changed.connect(_on_state_changed)
	_attack_timer.timeout.connect(_on_attack_timer)
	super._ready()


func _on_state_changed(_me : UnitBase, new_state : UnitState, _old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.DEFENDING)
		UnitState.DEFENDING:
			_attack_timer.start()


func process_unit(delta : float) -> void:
	if _state == UnitState.DEFENDING:
		_attack_timer


func _on_attack_timer():
	for target in _unit_targeting.get_targets():
		var spell_def := {
			"target": target
		}
		_manager.summonTomatoProjectile(spell_def, _position, team)
	
	# Restart attack timer
	_attack_timer.wait_time = attack_interval + randf() * 0.2
	_attack_timer.start()
