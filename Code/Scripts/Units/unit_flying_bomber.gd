class_name UnitFlyingBomber extends UnitBase

@onready var _unit_anims := %UnitAnimations as AnimationPlayer
@onready var _body := %BodyTransform as Node3D
@onready var _targeting_timer := %TargetingTimer as Timer

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
	_targeting_timer.timeout.connect(_on_targeting_timer); # Would love to do this in the base class, but couldn't figure out how to make it work.

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
	if (_position.y < flapHeight && _velocity.y < 0): flap();
	turnAroundIfReachedEndOfField();
	var diff = targetRotation - rotation.y;
	rotation.y += diff * delta * 5;

func flap():
	_velocity.y = flapMagnitude;

func turnAroundIfReachedEndOfField():
	if (travelDirection > 0 && position.x > fieldRightEnd):
		setTravelDirection(-1);
	if (travelDirection < 0 && position.x < fieldLeftEnd):
		setTravelDirection( 1);

func setTravelDirection(newDirection : int):
	travelDirection = newDirection;
	_velocity.x = travelDirection * moveSpeed;
	if (travelDirection == 1): targetRotation = 0;
	if (travelDirection == -1): targetRotation = PI;
	

func walk(target_speed : float, delta : float, allow_midair := false):
	pass;


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.DEFENDING)


func process_unit(delta : float) -> void:
	walk(0, delta, true)

func _on_targeting_timer():
	attemptAttack();

func attemptAttack():
	var target : UnitBase = find_target();
	if not target: return;
	# TODO drop egg

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

func is_valid_target(candidate_unit : UnitBase) -> bool:
	return super(candidate_unit) && !candidate_unit.is_flying_unit_type;







