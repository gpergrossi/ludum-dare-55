class_name UnitFlyingBomber extends UnitBase

const eggCooldownDurationMillis := 1000
var eggCooldown := 0

@export_category("Just Bird Things")
@export var flapHeightMin := 8.0
@export var flapHeightMax := 35.0

@export var flapMagnitudeMin := 6.0
@export var flapMagnitudeMax := 25.0

@export var moveSpeedMin := 6.0
@export var moveSpeedMax := 25.0

@export var patrol_margin = 10;  # If <= 0, the user can summon crows directly onto enemy building and they vanish.

var flapHeight : float
var flapMagnitude : float

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


# Override
func correct_spawn_position():
	_position.x = clampf(_position.x, _manager.get_left_map_edge_x() + patrol_margin, _manager.get_right_map_edge_x() - patrol_margin)


func selectIdiosyncracies():
	flapHeight = randomWeightMid(flapHeightMin, flapHeightMax);
	flapMagnitude = randomWeightMid(flapMagnitudeMin, flapMagnitudeMax);
	base_move_speed = randomWeightMid(moveSpeedMin, moveSpeedMax);


func randomWeightMid(min : float, max : float, weighting := 2):
	var roll := 0.0;
	for i in weighting: roll += randf();
	roll /= weighting;
	
	var delta = max - min;
	return min + roll * delta;


func flap():
	_velocity.y = flapMagnitude;


func _on_state_changed(_me : UnitBase, new_state : UnitTypeDefs.UnitState, _old_state : UnitTypeDefs.UnitState):
	match(new_state):
		UnitTypeDefs.UnitState.INITIALIZE: 
			change_state(UnitTypeDefs.UnitState.MOVING)


func process_unit(delta : float) -> void:
	match(_state):
		UnitTypeDefs.UnitState.MOVING:
			walk(base_move_speed, delta, true)
			if (_position.y < flapHeight && _velocity.y < 0): 
				flap();
			if (get_facing_x() > 0 && position.x > _manager.get_right_map_edge_x() - patrol_margin):
				facing = UnitTypeDefs.UnitFacing.LEFT
			if (get_facing_x() < 0 && position.x < _manager.get_left_map_edge_x() + patrol_margin):
				facing = UnitTypeDefs.UnitFacing.RIGHT
			
			var targets := _unit_targeting.get_targets()
			if len(targets) > 0:
				var target_x := targets[0].position.x
				if absf(position.x - target_x) < 2.0:
					# Drop egg
					var time := Time.get_ticks_msec()
					if time > eggCooldown:
						eggCooldown = time + eggCooldownDurationMillis
						_manager.summon(UnitTypeDefs.UnitType.CROW_EGG, {}, _position, team)
