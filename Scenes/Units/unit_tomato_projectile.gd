class_name UnitTomatoProjectile extends UnitBase

@onready var _body := %BodyTransform as Node3D
@onready var _projectile_sprite : TeamSprite = %TomatoProjectileSprite
@onready var _splat_sprite : TeamSprite = %TomatoSplatSprite
@onready var _googley_eyes : GoogleyEyesPair = %GoogleyEyesPair

@export var spin := TAU

var _target : UnitBase
var _spin := spin
var _falling := false

func _virtual_ready() -> void:
	state_changed.connect(_on_state_changed)
	_unit_targeting.target_acquired.connect(_on_target_acquired)


func _on_state_changed(_me : UnitBase, new_state : UnitTypeDefs.UnitState, _old_state : UnitTypeDefs.UnitState):
	match(new_state):
		UnitTypeDefs.UnitState.INITIALIZE: 
			change_state(UnitTypeDefs.UnitState.MOVING)

# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(_spell_def : Dictionary):
	_target = _spell_def["target"] as UnitBase


func _on_target_acquired(_new_target : UnitBase, _new_count : int):
	# Deal damage
	_new_target.take_damage(get_damage(), get_knockback())
	become_splat()
	begin_falling()


func become_splat():
	# Convert to splat
	_splat_sprite.rotate(Vector3.FORWARD, Vector2(0, 1).angle_to(_velocity.normalized()))
	_splat_sprite.visible = true
	_projectile_sprite.visible = false
	_googley_eyes.visible = false


func begin_falling():
	if not _falling:
		_velocity *= 0.05
	_falling = true
	
	_target = null
	set_gravity(20.0)
	
	# Cleanup eventually
	get_tree().create_timer(1).timeout.connect(delayed_die)


func delayed_die():
	die()


func process_unit(delta : float) -> void:
	_body.rotate(Vector3.BACK, delta * _spin)
	
	if is_instance_valid(_target) and _target._state != UnitTypeDefs.UnitState.DEAD:
		var dir := (_target.global_position - global_position)
		dir.z = 0.0
		dir = dir.normalized()
		_velocity = Vector2(dir.x, dir.y) * get_move_speed()
	else:
		_spin = _spin * pow(0.1, delta)
		if not _falling:
			begin_falling()
