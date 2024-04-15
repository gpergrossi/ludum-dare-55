class_name UnitEggProjectile extends UnitBase

@onready var egg_sprite := %EggSprite
@onready var splat_sprite := %SplatSprite
@onready var googley_eye := %GoogleyEyesPair

func _ready() -> void:
	state_changed.connect(_on_state_changed)
	unit_on_ground.connect(_on_grounded)
	super._ready()


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE:
			change_state(UnitState.MOVING)


func process_unit(delta : float) -> void:
	pass


func _on_grounded(me : UnitBase):
	egg_sprite.visible = false
	splat_sprite.visible = true
	splat_sprite.rotation.z = randf() * TAU
	googley_eye.visible = false
	
	_unit_targeting.search_now()
	for target in _unit_targeting.get_targets():
		target.take_damage(damage, knockback)
	
	get_tree().create_timer(1).timeout.connect(delayed_die)


func delayed_die():
	die()
