extends UnitBase

@export var attack_range : float
@export var damage : float

@onready var _attack_timer := $AttackTimer

func _ready() -> void:
	super._ready()
	_attack_timer.timeout.connect(_maybe_attack)
	
func _maybe_attack() -> void:
	var enemy = find_nearest_enemy(attack_range)
	if not enemy:
		return

	enemy.take_damage(damage)