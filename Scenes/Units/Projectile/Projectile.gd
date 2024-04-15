class_name Projectile extends Sprite3D

@onready var sound := %"Egg Splat Sound Player" as AudioStreamPlayer;
@onready var _terrain := $"../../TerrainGen" as TerrainGenerator;

enum EggMode {
	EGG,
	SPLAT,
};
const textures = {
	'Player': preload("res://Assets/mob/egg_green.png"),
	'Enemy': preload("res://Assets/mob/egg_red.png"),
};
const splat_textures = {
	'Player': preload("res://Assets/mob/eggsplat_green.png"),
	'Enemy': preload("res://Assets/mob/eggsplat_red.png"),
}

const gravity := 40.0;
const hit_radius := UnitFlyingBomber.eggSplatRadius;
const damage := 20.0;
const knockback := 8.0;

var team : Team;
var velocity := Vector3.ZERO;
var mode : EggMode = EggMode.EGG;
var spin : float = randf_range(-1.5, 1.5);

func set_team(t : Team):
	team = t;
	texture = textures[t.team_name];

func _ready():
	scale *= randf_range(0.8, 1.2);

func _process(delta):
	if mode == EggMode.EGG:
		rotate_z(spin * delta);
		apply_gravity(delta);
		check_hit_ground();
	if mode == EggMode.SPLAT:
		var size = scale.length();
		var newSize = size - delta * 3;
		if newSize < 0:
			self.queue_free();
		else:
			scale *= newSize / size;

func apply_gravity(delta):
	velocity.y -= gravity * delta;
	position += velocity * delta;

func check_hit_ground():
	var ground_height = _terrain.get_height(position.x);
	if (position.y <= ground_height):
		hit_ground();

func hit_ground():
	# Adjust position to just above the ground.
	var ground_height = _terrain.get_height(position.x);
	position.y = ground_height + 0.5;
	
	# Collect enemy targets in AoE range
	var possible_targets := UnitManager.get_all_units(
		TeamDefs.get_opposed_team(team)
	);
	var in_range : Array[UnitBase] = [];
	for unit in possible_targets:
		if (unit.position.distance_to(position) < hit_radius):
			in_range.push_back(unit);
	
	# Deal AoE damage
	for unit in in_range:
		unit.take_damage(damage, knockback);
	
	# Play splat sound
	print('PLaying egg splat sound');
	sound.play();
	
	# Place egg-splat decorative
	mode = EggMode.SPLAT;
	texture = splat_textures[team.team_name];
	scale *= 2;















