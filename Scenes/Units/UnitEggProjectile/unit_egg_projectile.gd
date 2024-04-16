class_name UnitEggProjectile extends UnitBase

@onready var sound := %"Egg Splat Sound Player" as AudioStreamPlayer;
@onready var egg_sprite := %EggSprite
@onready var splat_sprite := %SplatSprite
@onready var googley_eye := %GoogleyEyesPair

enum EggMode {
	EGG,
	SPLAT,
};

var spin : float = randf_range(-1.5, 1.5);
var mode : EggMode = EggMode.EGG;
	
func _ready() -> void:
	state_changed.connect(_on_state_changed)
	unit_on_ground.connect(_on_grounded)
	super._ready()
	scale *= randf_range(0.8, 1.2);

func _process(delta):
	if (mode == EggMode.EGG):
		rotate_z(spin * delta);
	
	# Slowly shink away
	if (mode == EggMode.SPLAT):
		var size = scale.length();
		var newSize = size - delta * 3;
		if newSize < 0:
			# Remove when fully shrunken
			die();
		else:
			scale *= newSize / size;
		
	

func _on_state_changed(_me : UnitBase, new_state : UnitTypeDefs.UnitState, old_state : UnitTypeDefs.UnitState):
	match(new_state):
		UnitTypeDefs.UnitState.INITIALIZE:
			change_state(UnitTypeDefs.UnitState.MOVING)


func process_unit(delta : float) -> void:
	walk(0.0, delta)


func _on_grounded(me : UnitBase):
	if (mode != EggMode.EGG): return;
	
	# Adjust position to just above the ground so the splat is better visible.
	position.y = get_ground_height(position.x) + 0.5;
	
	mode = EggMode.SPLAT;
	sound.play();
	egg_sprite.visible = false
	splat_sprite.visible = true
	splat_sprite.rotation.z = randf() * TAU
	googley_eye.visible = false
	
	_unit_targeting.search_now()
	for target in _unit_targeting.get_targets():
		target.take_damage(damage, knockback)
	
	scale *= 2;
