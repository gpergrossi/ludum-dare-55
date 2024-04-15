class_name UnitFlyingBomber extends UnitBase

const scene_egg_bomb := preload("res://Scenes/Units/Projectile/egg_bomb.tscn") as PackedScene;
@onready var _unit_anims := %UnitAnimations as AnimationPlayer
@onready var _body := %BodyTransform as Node3D
@onready var _targeting_timer := %TargetingTimer as Timer

const eggCooldownDurationMillis := 1000;
var eggCooldown := 0;
const flapHeightRange = {
	'min': 8,
	'max': 30,
};
const flapMagnitudeRange = {
	'min': 6,
	'max': 17,
};
const moveSpeedRange = {
	'min': 6,
	'max': 17,
};
static var initialTravelDirection = {
	TeamDefs.Player.team_name: 1,
	TeamDefs.Enemy.team_name: -1,
}

var flapHeight : float;
var flapMagnitude : float;
var moveSpeed : float;
var travelDirection : int;
var targetRotation : float;

func _ready() -> void:
	is_flying_unit_type = true;
	selectIdiosyncracies();
	state_changed.connect(_on_state_changed)
	super._ready()
	setTravelDirection(initialTravelDirection[team.team_name]);

func selectIdiosyncracies():
	flapHeight = randomWeightMid(flapHeightRange['min'], flapHeightRange['max']);
	flapMagnitude = randomWeightMid(flapMagnitudeRange['min'], flapMagnitudeRange['max']);
	moveSpeed = randomWeightMid(moveSpeedRange['min'], moveSpeedRange['max']);

func randomWeightMid(min : float, max : float, weighting := 2):
	var roll := 0.0;
	for i in weighting: roll += randf();
	roll /= weighting;
	
	var delta = max - min;
	return min + roll * delta;

const patrolRange = 0.9; # Cover the central 90% of the field
@onready var fieldLeftEnd = UnitManager._unit_manager_static.summon_default_position_left.global_position.x * patrolRange;
@onready var fieldRightEnd = UnitManager._unit_manager_static.summon_default_position_right.global_position.x * patrolRange;

func _process(delta) -> void:
	if (position.y < flapHeight && velocity.y < 0): flap();
	turnAroundIfReachedEndOfField();
	var diff = targetRotation - rotation.y;
	rotation.y += diff * delta * 5;

func flap():
	velocity.y = flapMagnitude;

func turnAroundIfReachedEndOfField():
	if (travelDirection > 0 && position.x > fieldRightEnd):
		setTravelDirection(-1);
	if (travelDirection < 0 && position.x < fieldLeftEnd):
		setTravelDirection( 1);

func setTravelDirection(newDirection : int):
	travelDirection = newDirection;
	velocity.x = travelDirection * moveSpeed;
	if (travelDirection == 1): targetRotation = 0;
	if (travelDirection == -1): targetRotation = PI;

func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.DEFENDING)

func process_unit(delta : float) -> void:
	attemptAttack();

func attemptAttack():
	#var target : UnitBase = find_target();  # TODO fire only if target is in strike zone
	#if not target: return;
	var time := Time.get_ticks_msec();
	if time > eggCooldown:
		eggCooldown = time + eggCooldownDurationMillis;
		layEgg();

func layEgg():
	var projectile : Projectile = scene_egg_bomb.instantiate();
	projectile.set_team(team);
	projectile.position = position;
	ProjectileManager.singleton.add_child(projectile);

const eggSplatRadius = 5;
const targetRadiusSquared = eggSplatRadius * eggSplatRadius;
func find_target() -> UnitBase:
	print('finding');
	var strikeZone = predictStrikeZone();
	var candidates = _get_possible_targets();
	for unit : UnitBase in candidates:
		if strikeZone.distance_squared_to(unit.global_position) < targetRadiusSquared:
			return unit;
	return null;

func predictStrikeZone():
	return Vector2 (
		position.x,
		getTerrainHeightAtX(position.x)
	);

static func getTerrainHeightAtX(x: float) -> float:
	return 0.0;

func _isValidTarget(candidate_unit : UnitBase) -> bool:
	return super(candidate_unit) && !candidate_unit.is_flying_unit_type;







