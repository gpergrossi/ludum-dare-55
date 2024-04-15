class_name UnitBase extends Node3D

# Common list of states, not all states used in a given unit class.
enum UnitState {
	UNINITIALIZED,
	INITIALIZE,
	MOVING,
	ATTACKING,
	DEFENDING,
	DEAD
}

# Used for turning collision with enemies on and off.
enum UnitMoveType {
	GROUND,
	FLYING
}

# Which way to flip the art
enum UnitFacing {
	LEFT,
	RIGHT
}

static var next_uid := 0

const LAYER_WORLD := 1
const LAYER_LEFTSIDE := 2
const LAYER_RIGHTSIDE := 3

@export var unit_name : String

@export_category("Movement")
@export var unit_move_type := UnitMoveType.GROUND
@export var facing := UnitFacing.RIGHT
@export var top_speed := 10
@export var move_accel := 100.0
@export var gravity := 40.0
@export var turning_time := 0.333  # Only affects visuals 

@export_category("Defenses")
@export var max_health := 100.0
@export_range(0.0, 1.0) var knockback_immunity := 0.0

@export_category("Attack")
@export var attack_range := 2.0
@export var damage := 30.0
@export var reach_caster_damage := 10.0
@export var knockback := 10.0


# Signals
signal damage_taken(me : UnitBase, damage : float, new_health : float)
signal state_changed(me : UnitBase, new_state : UnitState, old_state : UnitState)
signal unit_on_ground(me : UnitBase)
signal unit_off_ground(me : UnitBase)
signal unit_at_opponents_building(me : UnitBase)


@onready var _shadow := %Shadow as MeshInstance3D
@onready var _eyes := _find_eyes()
@onready var _team_sprites := _find_team_sprites()
@onready var _facing_rotation := %FacingRotation as Node3D
@onready var _unit_targeting := %UnitTargeting as UnitTargeting

# System
var _id := 0
var _state := UnitState.UNINITIALIZED

# Assigned by manager
var _manager : UnitManager
var _terrain : TerrainGenerator
var _lane_offset := Vector3.ZERO : set = set_lane_offset

# Team specifics
var team : Team : set = set_team
var _facing_angle_y := 0.0

# Health indicator
var _health : float
var _brow_tilt_no_damage := -5.0
var _brow_tilt_full_damage := -20.0

# Custom physics
var _on_floor := false
var _was_on_floor := false
var _velocity := Vector2.ZERO
var _position := Vector2.ZERO : set = _set_position
var _current_ground_angle := 0.0


func _ready():
	_id = next_uid
	next_uid += 1
	
	_health = max_health
	change_state(UnitState.INITIALIZE)
	
	name = unit_name + " #" + str(_id) + " (" + team.get_controlled_by_name() + ")"


func _physics_process(delta : float):	
	if is_on_floor():
		# Update slope/shadow
		_current_ground_angle = atan2(get_ground_slope(global_position.x), 1)
		_shadow.rotation.z = _current_ground_angle
		_shadow.visible = true
		
		if not _was_on_floor:
			unit_on_ground.emit(self)
			_was_on_floor = true
		
	else:
		# Apply gravity
		_velocity += Vector2(0, -1) * gravity * delta
		
		# Update slope/shadow
		_current_ground_angle = 0.0
		_shadow.visible = false
		
		if _was_on_floor:
			unit_off_ground.emit(self)
			_was_on_floor = false
	
	process_unit(delta)
	
	# Movement
	_position += _velocity * delta
	
	# Note: FLYING units don't collide at all
	if self.unit_move_type == UnitMoveType.GROUND:
		# Collide with opponents' units
		for other in get_tree().get_nodes_in_group("units"):
			var other_unit := other as UnitBase
			if not is_instance_valid(other_unit): continue
			if other_unit.unit_move_type != UnitMoveType.GROUND: continue
			if other_unit.team == self.team: continue
			
			var x_dist := other_unit._position.x - self._position.x
			var forward_sep := x_dist * get_facing_x()
			
			if forward_sep < 0.0: continue  # Unit is behind me, no collision
			
			if forward_sep < 1.5:
				# Walked into opponent
				_position.x = other_unit._position.x - 1.5 * get_facing_x()
				_velocity.x = 0.0
	
	
	# Collision
	var ground_y := get_ground_height(_position.x)
	
	# Snap to floor (non-FLYING only)
	if unit_move_type != UnitMoveType.FLYING and _on_floor and absf(_position.y - ground_y) < 0.1:
		_position.y = ground_y
	
	# Keep units above the floor
	if _position.y < ground_y:
		# Otherwise stay on top of the floor.
		_position.y = ground_y
		_on_floor = true
		
		# Remove velocity into the ground.
		var ground_normal := Vector2(-sin(_current_ground_angle), cos(_current_ground_angle))
		_velocity -= maxf(0.0, _velocity.dot(ground_normal)) * ground_normal
	
	else:
		# Left the floor due to upward velocity.
		_on_floor = false
	
	# Slowly turn around when facing is flipped
	var target_facing_angle_y := PI if facing == UnitFacing.LEFT else 0.0
	var max_turn := delta * PI / turning_time
	_facing_angle_y = move_toward(_facing_angle_y, target_facing_angle_y, max_turn)
	_facing_rotation.rotation.y = _facing_angle_y
	
	# Left boundary enforcement / kill plane
	if _position.x < _manager.get_left_map_edge_x():
		if team.get_move_direction_x() < -0.5:
			_manager.do_kill_plane(self)
			do_kill_plane()
		else:
			_position.x = maxf(_position.x, _manager.get_left_map_edge_x())
	
	# Right boundary enforcement / kill plane
	elif _position.x > _manager.get_right_map_edge_x():
		if team.get_move_direction_x() > 0.5:
			_manager.do_kill_plane(self)
			do_kill_plane()
		else:
			_position.x = minf(_position.x, _manager.get_right_map_edge_x())


##########################################################################
######   VIRTUAL METHODS FOR SUBCLASS   #####################################
################################################################################

func process_unit(delta : float) -> void:
	match(_state):
		UnitState.MOVING:
			walk(top_speed, delta)

# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(_spell_def : Dictionary):
	pass

################################################################################
######   END VIRTUAL METHODS FOR SUBCLASS  ##################################
##########################################################################





##########################################################################
######   HELPFUL METHODS FOR SUBCLASS   #####################################
################################################################################

func walk(target_speed : float, delta : float, allow_midair := false):
	if is_on_floor() or allow_midair:
		var target_move_x := get_facing_x() * target_speed
		if absf(_velocity.x - target_move_x) > 0.0:
			_velocity.x = move_toward(_velocity.x, target_move_x, move_accel * delta)

func get_ground_height(x : float) -> float:
	return _terrain.get_height(x)

func get_ground_slope(x : float, epsilon := 0.1) -> float:
	return _terrain.get_slope(x, epsilon)

func is_on_floor():
	return _on_floor

func change_state(new_state : UnitState):
	var old_state := _state
	_state = new_state
	state_changed.emit(self, new_state, old_state)

func get_facing_x() -> float:
	return -1.0 if (facing == UnitFacing.LEFT) else 1.0

################################################################################
######   END HELPFUL METHODS FOR SUBCLASS  ##################################
##########################################################################



##########################################################################
######   TAKING DAMAGE   ####################################################
################################################################################

# Call this from animation sequence to actually deal damage at the right time.
func damage_targets():
	var targets := _unit_targeting.get_targets()
	var cleave_count := float(len(targets))
	for target in targets:
		if is_instance_valid(target):
			target.take_damage(self.damage / cleave_count, self.knockback / cleave_count)


func take_damage(damage_amount : float, knockback_amount : float) -> void:
	var prev_health := _health
	
	_health -= damage_amount
	damage_taken.emit(self, damage_amount, _health)
	
	if not is_equal_approx(_health, prev_health):
		update_brow_tilt()
		for sprite in _team_sprites:
			sprite.do_damage_flash()
		
		var knockback_force := (1.0 - knockback_immunity) * Vector2(-team.get_move_direction_x(), 1.0).normalized() * knockback_amount
		_velocity += knockback_force
		
		if _health <= 0:
			die()


func die() -> void:
	change_state(UnitState.DEAD)
	
	if _on_floor:
		queue_free()
	else:
		print("Dead unit " + name + " waiting for next ground touch...")
		unit_on_ground.connect(delayed_queue_free)


func delayed_queue_free(_me : UnitBase):
	print("Dead unit " + name + " touched the ground!")
	if _state == UnitState.DEAD:
		queue_free()


# Based on damage, the eyes get sadder
func update_brow_tilt():
	_eyes.brow_tilt = lerp(_brow_tilt_no_damage, _brow_tilt_full_damage, (max_health - _health) / max_health)


func do_kill_plane() -> void:
	change_state(UnitState.DEAD)
	queue_free()

################################################################################
######   END TAKING DAMAGE  #################################################
##########################################################################



func set_team(assigned_team : Team):
	team = assigned_team
	
	for sprite in _team_sprites:
		sprite.team_color = team.color
	
	# Enemy team gets thicker, angry eye brows
	if is_instance_valid(_eyes):
		if team.controller == Team.TeamController.AI:
			_eyes.brow_thickness = 0.15
			_brow_tilt_no_damage = 15
			update_brow_tilt()
	
	# Initial facing
	if team.get_move_direction_x() < 0:
		facing = UnitFacing.LEFT
		_facing_angle_y = PI
	else:
		facing = UnitFacing.RIGHT
		_facing_angle_y = 0.0


func set_lane_offset(offset : Vector3):
	_lane_offset = offset
	var offset_node := $LaneOffset as Node3D
	if is_instance_valid(offset_node):
		# Don't let a unit move "in front of" (team based) it's collision position.
		offset.x = -team.get_move_direction_x() * absf(offset.x)
		offset_node.position = offset


func _set_position(pos : Vector2):
	_position = pos
	# Convert to 3D and apply to Node3D position
	position.x = pos.x
	position.y = pos.y


func _find_eyes() -> GoogleyEyesPair:
	var eye_children := find_children("GoogleyEyesPair")
	if len(eye_children) == 0: printerr("Missing the eyes!")
	for eye_child in eye_children:
		var eyes := eye_child as GoogleyEyesPair
		if is_instance_valid(eyes):
			return eyes
	printerr("No eyes found!")
	return null


func _find_team_sprites() -> Array[TeamSprite]:
	var _team_sprites := [] as Array[TeamSprite]
	var nodes := find_children("*", "TeamSprite", true, true)
	for node in nodes:
		_team_sprites.append(node as TeamSprite)
	assert(len(_team_sprites) > 0, "No team sprites found!")
	return _team_sprites
