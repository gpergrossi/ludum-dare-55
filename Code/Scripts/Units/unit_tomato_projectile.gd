class_name UnitTomatoProjectile extends UnitBase

@onready var _body := %BodyTransform as Node3D
@onready var _projectile_sprite := %TomatoProjectileSprite as TeamSprite
@onready var _splat_sprite := %TomatoSplatSprite as TeamSprite
@onready var _googley_eyes := %GoogleyEyesPair as GoogleyEyesPair

@export var flight_speed := 50.0
@export var spin := TAU

var _target : UnitBase
var _spin := spin

func _ready() -> void:
	state_changed.connect(_on_state_changed)
	_unit_targeting.target_acquired.connect(_on_target_acquired)
	super._ready()



func _on_state_changed(_me : UnitBase, new_state : UnitState, _old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.MOVING)

# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(_spell_def : Dictionary):
	_target = _spell_def["target"] as UnitBase


func _on_target_acquired(_new_target : UnitBase, _new_count : int):
	print ("tomato saw a " + _new_target.name)
	# Convert to splat
	_splat_sprite.rotate(Vector3.FORWARD, Vector2(0, 1).angle_to(_velocity.normalized()))
	_splat_sprite.visible = true
	_projectile_sprite.visible = false
	_googley_eyes.visible = false
	
	# Deal damage
	_new_target.take_damage(self.damage, self.knockback)
	
	# Begin falling
	_target = null
	gravity = 20.0
	_velocity *= 0.05
	
	# Cleanup eventually
	get_tree().create_timer(1).timeout.connect(delayed_die)


func delayed_die():
	die()


func process_unit(delta : float) -> void:
	_body.rotate(Vector3.BACK, delta * _spin)
	
	if is_instance_valid(_target):
		if _target._state != UnitState.DEAD:
			var dir := (_target.global_position - global_position)
			dir.z = 0.0
			dir = dir.normalized()
			_velocity = Vector2(dir.x, dir.y) * flight_speed
		else:
			_spin = _spin * pow(0.1, delta)
	else:
		_spin = _spin * pow(0.1, delta)
