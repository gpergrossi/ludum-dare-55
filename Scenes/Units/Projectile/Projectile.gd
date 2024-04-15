extends Sprite3D

const textures = {
	'Player': preload("res://Assets/mob/egg_green.png"),
	'Enemy': preload("res://Assets/mob/egg_red.png"),
};

const gravity := 40.0;
const hit_radius := UnitFlyingBomber.eggSplatRadius;
const damage := 20.0;
const knockback := 5.0;

@onready var _terrain := %TerrainGen as TerrainGenerator
var team : Team;
var velocity := Vector3.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_team(t : Team):
	team = t;
	texture = textures[t.team_name];

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	apply_gravity(delta);
	#check_hit_ground();

func apply_gravity(delta):
	velocity.y -= UnitBase.gravity * delta;
	position += velocity * delta;

func check_hit_ground():
	var ground_height = _terrain.get_height(position.x);
	if (position.y <= ground_height):
		hit_ground();

func hit_ground():
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
		
	# Place egg-splat decorative
	# TODO
		
	# Remove self
	self.queue_free();















