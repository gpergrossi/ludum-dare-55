class_name UnitFlyingBomber extends UnitBase

const eggCooldownDurationMillis := 1000
var eggCooldown := 0

@export_category("Just Bird Things")
@export var flapHeightMin := 8.0
@export var flapHeightMax := 30.0

@export var flapMagnitudeMin := 6.0
@export var flapMagnitudeMax := 17.0

@export var moveSpeedMin := 6.0
@export var moveSpeedMax := 17.0

@export var patrolRange = 0.9; # Cover the central 90% of the field

var flapHeight : float
var flapMagnitude : float
var moveSpeed : float

func _ready() -> void:
	selectIdiosyncracies();
	state_changed.connect(_on_state_changed)
	
	_unit_targeting.target_acquired.connect(
		func (new_target : UnitBase, new_target_count : int):  
			print(name + ": Target acquired " + new_target.name + " (" + str(new_target_count) + ")")
	)
	_unit_targeting.target_lost.connect(
		func (new_target : UnitBase, new_target_count : int):  
			print(name + ": Target lost " + new_target.name + " (" + str(new_target_count) + ")")
	)
	_unit_targeting.target_killed.connect(
		func (new_target : UnitBase, new_target_count : int):  
			print(name + ": Target killed " + new_target.name + " (" + str(new_target_count) + ")")
	)
	
	super._ready()


func selectIdiosyncracies():
	flapHeight = randomWeightMid(flapHeightMin, flapHeightMax);
	flapMagnitude = randomWeightMid(flapMagnitudeMin, flapMagnitudeMax);
	moveSpeed = randomWeightMid(moveSpeedMin, moveSpeedMax);


func randomWeightMid(min : float, max : float, weighting := 2):
	var roll := 0.0;
	for i in weighting: roll += randf();
	roll /= weighting;
	
	var delta = max - min;
	return min + roll * delta;


func flap():
	_velocity.y = flapMagnitude;


func _on_state_changed(_me : UnitBase, new_state : UnitState, _old_state : UnitState):
	match(new_state):
		UnitState.INITIALIZE: 
			change_state(UnitState.MOVING)


func process_unit(delta : float) -> void:
	match(_state):
		UnitState.MOVING:
			walk(top_speed, delta, true)
			if (_position.y < flapHeight && _velocity.y < 0): 
				flap();
			if (get_facing_x() > 0 && position.x > _manager.get_right_map_edge_x() * patrolRange):
				facing = UnitFacing.LEFT
			if (get_facing_x() < 0 && position.x < _manager.get_left_map_edge_x() * patrolRange):
				facing = UnitFacing.RIGHT
			
			var targets := _unit_targeting.get_targets()
			if len(targets) > 0:
				var target_x := targets[0].position.x
				if absf(position.x - target_x) < 5.0:
					# Drop egg
					var time := Time.get_ticks_msec()
					if time > eggCooldown:
						eggCooldown = time + eggCooldownDurationMillis
						_manager.summonEggProjectile({}, _position, team)
