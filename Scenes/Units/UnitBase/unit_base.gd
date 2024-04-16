class_name UnitBase extends Node3D

static var next_uid := 0

const LAYER_WORLD := 1
const LAYER_LEFTSIDE := 2
const LAYER_RIGHTSIDE := 3

@export var unit_type : UnitTypeDefs.UnitType = UnitTypeDefs.UnitType.BROCOLLI

@export_category("Movement")
@export var unit_move_type := UnitTypeDefs.UnitMoveType.GROUND
@export var facing := UnitTypeDefs.UnitFacing.RIGHT
@export var base_move_speed := 10
@export var move_accel := 100.0
@export var gravity := 40.0
@export var turning_time := 0.333  # Only affects visuals 
@export var unit_collision_width := 1.5

@export_category("Defenses")
@export var max_health := 100.0
@export_range(0.0, 1.0) var knockback_immunity := 0.0
## Reduce all damage taken by a flat amount, to a minimum of 1.
@export var damage_reduction : int = 0;

@export_category("Attack")
@export var damage := 30.0
@export var knockback := 10.0
@export var reach_caster_damage := 10.0

@export_category("Rendering")
@export var max_shadow_dist := 0.5
@export var max_shadow_shrink_begin_dist := 0.25

# Signals
signal damage_taken(me : UnitBase, damage : float, new_health : float)
signal state_changed(me : UnitBase, new_state : UnitTypeDefs.UnitState, old_state : UnitTypeDefs.UnitState)
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
var _state := UnitTypeDefs.UnitState.UNINITIALIZED

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
	change_state(UnitTypeDefs.UnitState.INITIALIZE)
	
	name = UnitTypeDefs.get_unit_name(unit_type) + " #" + str(_id) + " (" + team.get_controlled_by_name() + ")"


func _physics_process(delta : float):
	if not is_on_floor():
		# Apply gravity
		_velocity += Vector2(0, -1) * gravity * delta
	
	# Other sources of velocity from child class
	process_unit(delta)
	
	# Movement
	_position += _velocity * delta
	
	do_unit_collisions()
	do_boundary_collisions()
	do_floor_collision()
	
	update_current_ground_angle()
	update_facing_spin(delta)


func do_unit_collisions():
	if self.unit_move_type == UnitTypeDefs.UnitMoveType.FLYING: return
	if self.unit_move_type == UnitTypeDefs.UnitMoveType.ROLLING: return
		
	# Collide with opponents' units
	for other_unit in get_all_collidable_units():
		var x_dist := other_unit._position.x - self._position.x
		var forward_sep := x_dist * get_facing_x()
		
		var combined_width := 0.5 * (self.unit_collision_width + other_unit.unit_collision_width)
		
		if forward_sep < -combined_width: 
			# Unit is behind me, no collision
			continue
		
		if forward_sep < combined_width:
			# Walked into opponent, fix position
			_position.x = other_unit._position.x - combined_width * get_facing_x()
			_velocity.x = maxf(0.0, _velocity.x)


func get_all_collidable_units() -> Array[UnitBase]:
	var results := [] as Array[UnitBase]
	for other in get_tree().get_nodes_in_group("units"):
		var other_unit := other as UnitBase
		if not is_instance_valid(other_unit): continue
		if other_unit.unit_move_type == UnitTypeDefs.UnitMoveType.FLYING: continue
		if other_unit.team == self.team: continue
		results.append(other_unit)
	return results


func do_boundary_collisions():
	# Left boundary enforcement / kill plane
	if _position.x < _manager.get_left_map_edge_x():
		# For right team, this is a kill plane
		if team.side == Team.TeamSide.RIGHT:
			unit_at_opponents_building.emit(self)
			queue_free()
		
		# Otherwise it's a wall
		else:
			_position.x = maxf(_position.x, _manager.get_left_map_edge_x())
	
	# Right boundary enforcement / kill plane
	elif _position.x > _manager.get_right_map_edge_x():
		# For left team, this is a kill plane
		if team.side == Team.TeamSide.LEFT:
			_manager.do_unit_hurt_opponent_caster(self)
			queue_free()
		
		# Otherwise it's a wall
		else:
			_position.x = minf(_position.x, _manager.get_right_map_edge_x())


func do_floor_collision():
	var floor_y := get_ground_height(_position.x)
	
	# Snap to floor (non-FLYING only)
	if unit_move_type != UnitTypeDefs.UnitMoveType.FLYING and _on_floor and absf(_position.y - floor_y) < 0.1:
		_position.y = floor_y
	
	# Detect floor and keep units above the floor
	elif _position.y < floor_y:
		_position.y = floor_y
		
		# We are now on the floor
		_on_floor = true
		if not _was_on_floor:
			unit_on_ground.emit(self)
			_was_on_floor = true
		
		# Remove velocity into the ground.
		var ground_normal := Vector2(sin(_current_ground_angle), -cos(_current_ground_angle))
		_velocity -= maxf(0.0, _velocity.dot(ground_normal)) * ground_normal
	
	# Detect when a unit has left the ground due to upward velocity.
	else:
		# We are now off the floor
		_on_floor = false
		if _was_on_floor:
			unit_off_ground.emit(self)
			_was_on_floor = false


func update_current_ground_angle():
	# Update slope/shadow
	var floor_y := get_ground_height(_position.x)
	_current_ground_angle = atan2(get_ground_slope(global_position.x), 1)
	
	_shadow.rotation.z = _current_ground_angle
	_shadow.visible = absf(_position.y - floor_y) < max_shadow_dist
	
	var shadow_scale := 1.0 - clampf((absf(_position.y - floor_y) - max_shadow_shrink_begin_dist) / (max_shadow_dist - max_shadow_shrink_begin_dist), 0.0, 1.0)
	_shadow.scale = Vector3(shadow_scale, shadow_scale, shadow_scale)


func update_facing_spin(delta : float):
	# Slowly turn around when facing is flipped
	var target_facing_angle_y := PI if facing == UnitTypeDefs.UnitFacing.LEFT else 0.0
	var max_turn := delta * PI / turning_time
	_facing_angle_y = move_toward(_facing_angle_y, target_facing_angle_y, max_turn)
	_facing_rotation.rotation.y = _facing_angle_y



##########################################################################
######   VIRTUAL METHODS FOR SUBCLASS   #####################################
################################################################################

func process_unit(delta : float) -> void:
	match(_state):
		UnitTypeDefs.UnitState.MOVING:
			walk(base_move_speed, delta)

# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(_spell_def : Dictionary):
	pass

func correct_spawn_position():
	_position.x = clampf(_position.x, _manager.get_left_map_edge_x(), _manager.get_right_map_edge_x())

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

# Call this from animation sequence to actually deal damage at the right time.
func damage_targets():
	var targets := _unit_targeting.get_targets()
	var cleave_count := float(len(targets))
	for target in targets:
		if is_instance_valid(target):
			target.take_damage(self.damage / cleave_count, self.knockback / cleave_count)

func get_ground_height(x : float) -> float:
	var ground_y := _terrain.get_height(x)
	#print("Getting ground height at " + str(x) + " got " + str(ground_y))
	return ground_y

func get_ground_slope(x : float, epsilon := 0.1) -> float:
	return _terrain.get_slope(x, epsilon)

func is_on_floor():
	return _on_floor

func change_state(new_state : UnitTypeDefs.UnitState):
	var old_state := _state
	_state = new_state
	state_changed.emit(self, new_state, old_state)

func get_facing_x() -> float:
	return UnitTypeDefs.get_facing_x(facing)

################################################################################
######   END HELPFUL METHODS FOR SUBCLASS  ##################################
##########################################################################



##########################################################################
######   TAKING DAMAGE   ####################################################
################################################################################

func take_damage(damage_amount : float, knockback_amount : float) -> void:
	var prev_health := _health
	
	if (damage_amount > 1):
		damage_amount = max(1, damage_amount - damage_reduction);
	
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
	if _state != UnitTypeDefs.UnitState.DEAD:
		change_state(UnitTypeDefs.UnitState.DEAD)
		if _on_floor:
			queue_free()
		else:
			unit_on_ground.connect(delayed_queue_free)


func delayed_queue_free(_me : UnitBase):
	queue_free()


# Based on damage, the eyes get sadder
func update_brow_tilt():
	_eyes.brow_tilt = lerp(_brow_tilt_no_damage, _brow_tilt_full_damage, (max_health - _health) / max_health)


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
		facing = UnitTypeDefs.UnitFacing.LEFT
		_facing_angle_y = PI
	else:
		facing = UnitTypeDefs.UnitFacing.RIGHT
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
