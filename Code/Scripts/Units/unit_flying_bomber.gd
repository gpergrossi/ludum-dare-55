class_name UnitFlyingBomber extends UnitBase

@onready var _unit_anims := %UnitAnimations as AnimationPlayer
@onready var _body := %BodyTransform as Node3D

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
	

func walk(target_speed : float, delta : float, allow_midair := false):
	pass;

# Need to expose this here so an animation sequence can call it.
func damage_target():
	super.damage_target()


func _on_state_changed(_me : UnitBase, new_state : UnitState, old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.DEFENDING)


func process_unit(delta : float) -> void:
	walk(0, delta, true)


func _on_targeting_timer():
	find_target()  # May trigger _on_target_acquired, if there is a target
