class_name UnitBase extends CharacterBody3D

enum UnitState {
	UNINITIALIZED,
	INITIALIZE,
	MOVING,
	ATTACKING,
	DEFENDING,
	DEAD
}

static var next_uid := 0

const LAYER_WORLD := 1
const LAYER_LEFTSIDE := 2
const LAYER_RIGHTSIDE := 3

@export_enum("Player", "Enemy") var team_name := "Player" : set = set_team_name
var team : Team

@export var unit_name : String

@export_category("Movement")
@export var top_speed := 10
@export var move_accel := 100.0
@export var gravity := 40.0
@export var knockback_multiplier_self := 1.0

@export_category("Health")
@export var max_health := 100.0

@export_category("Attack")
@export var attack_range := 2.0
@export var damage := 30.0
@export var reach_caster_damage := 10.0
@export var knockback := 10.0

@export_category("Rendering")
@export var color_tint := Color.WHITE : set = set_color_tint
@export var damage_flash_time := 0.3
@export var damage_flash_intensity := 0.3
@export var damage_flash_color := Color.RED





signal damage_taken(me : UnitBase, damage : float, new_health : float)
signal state_changed(me : UnitBase, new_state : UnitState, old_state : UnitState)
signal target_acquired(me : UnitBase, new_current_target : UnitBase)
signal target_lost(me : UnitBase, prev_current_target : UnitBase)
signal target_dead(me : UnitBase, new_current_target : UnitBase)
signal unit_on_ground(me : UnitBase)
signal unit_off_ground(me : UnitBase)





@onready var _slope_detect_left := %TerrainSlopeDetectLeft as SpringArm3D
@onready var _slope_detect_right := %TerrainSlopeDetectRight as SpringArm3D
@onready var _shadow := %Shadow as MeshInstance3D
@onready var _eyes := _find_eyes()


var _health : float

var _id := 0
var _state := UnitState.UNINITIALIZED
var _current_target : UnitBase = null

var _left_list := [] as Array[UnitBase]
var _right_list := [] as Array[UnitBase]

var _current_ground_angle := 0.0

var _brow_tilt_no_damage := -5.0
var _brow_tilt_full_damage := -20.0

var _was_on_floor := false

var _lane_offset := Vector3.ZERO : set = set_lane_offset
var _damage_flash_time_remaining := 0.0




func _ready():
	_id = next_uid
	next_uid += 1
	
	_health = max_health
	_left_list.clear()
	_right_list.clear()
	
	# Ensure we have  the correct team appearance
	_on_team_assigned(team)
	
	change_state(UnitState.INITIALIZE)


func _physics_process(delta : float):
	# Color animation because I had to use code to get this working
	if _damage_flash_time_remaining > 0.0:
		print(str(_damage_flash_time_remaining))
		_damage_flash_time_remaining -= delta
		var intensity := get_damage_flash_intensity()
		for meshInst in get_renderables():
			set_color_tint_on_mesh(meshInst, color_tint.lerp(damage_flash_color, intensity))
		
	
	if is_on_floor():
		# Update slope/shadow
		var slope := _slope_detect_right.get_hit_length() - _slope_detect_left.get_hit_length()
		_current_ground_angle = atan2(slope, 1)
		_shadow.rotation.z = -_current_ground_angle
		_shadow.visible = true
		
		if not _was_on_floor:
			unit_on_ground.emit(self)
			_was_on_floor = true
		
	else:
		# Apply gravity
		velocity += Vector3.DOWN * gravity * delta
		
		# Update slope/shadow
		_current_ground_angle = 0.0
		_shadow.visible = false
		
		if _was_on_floor:
			unit_off_ground.emit(self)
			_was_on_floor = false
	
	process_unit(delta)
	move_and_slide()




##########################################################################
######   VIRTUAL METHODS FOR SUBCLASS   #####################################
################################################################################

func process_unit(delta : float) -> void:
	match(_state):
		UnitState.MOVING:
			walk(top_speed, delta)

func find_target() -> UnitBase:
	return find_target_from_scanners()

func assign_collision_layers() -> void:
	# Get team layer number
	var team_layer : int
	var other_team_layer : int
	if team.team_side < 0: 
		team_layer = LAYER_LEFTSIDE
		other_team_layer = LAYER_RIGHTSIDE
	else:
		team_layer = LAYER_RIGHTSIDE
		other_team_layer = LAYER_LEFTSIDE
		
	# Assign to own team layer + world objects layer
	set_collision_layer_value(LAYER_WORLD, false)
	set_collision_layer_value(team_layer, true)
	set_collision_layer_value(other_team_layer, false)
	
	# Collide with other team layer + world objects layer
	set_collision_mask_value(LAYER_WORLD, true)
	set_collision_mask_value(other_team_layer, true)
	set_collision_mask_value(team_layer, false)

################################################################################
######   END VIRTUAL METHODS FOR SUBCLASS  ##################################
##########################################################################





##########################################################################
######   HELPFUL METHODS FOR SUBCLASS   #####################################
################################################################################

func internal_find_target() -> void:
	var target := find_target()
	if target:
		_current_target = target
		target_acquired.emit(self, _current_target)
		_current_target.state_changed.connect(internal_check_target_dead)
	else:
		clear_target()


func find_target_from_scanners() -> UnitBase:
	return _find_nearest_target_with_scanners(attack_range)



func walk(target_speed : float, delta : float, allow_midair := false):
	if is_on_floor() or allow_midair:
		if absf(velocity.x - team.get_team_move_x() * target_speed) > 0.0:
			var target_move_x := team.get_team_move_x() * target_speed
			velocity.x = move_toward(velocity.x, target_move_x, move_accel * delta)


func clear_target():
	if _current_target != null:
		if is_instance_valid(_current_target):
			_current_target.state_changed.disconnect(internal_check_target_dead)
		target_lost.emit(self, _current_target)
	_current_target = null


func get_renderables() -> Array[MeshInstance3D]:
	var render_children := [] as Array[Node]
	if team == TeamDefs.Player:
		render_children = find_children("*Green")
		print("Found " + str(len(render_children)) + " render children")
	elif team == TeamDefs.Enemy:
		render_children = find_children("*Red")
		print("Found " + str(len(render_children)) + " render children")
	
	var renderables := [] as Array[MeshInstance3D]
	for child in render_children:
		var meshInst := child as MeshInstance3D
		if is_instance_valid(meshInst):
			renderables.append(meshInst)
	return renderables


func set_color_tint_on_mesh(meshInst : MeshInstance3D, color : Color):
	var material := meshInst.mesh.surface_get_material(0) as ShaderMaterial
	material.set_shader_parameter("albedo", color)

################################################################################
######   END HELPFUL METHODS FOR SUBCLASS  ##################################
##########################################################################





# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(_spell_def : Dictionary):
	pass


func set_team_name(val : String):
	team_name = val
	team = TeamDefs.FromName(team_name)
	if is_node_ready():
		_on_team_assigned(team)


func set_color_tint(color : Color):
	color_tint = color
	# HACK: Force a color update 
	_damage_flash_time_remaining = minf(0.01, _damage_flash_time_remaining)


func do_kill_plane() -> void:
	change_state(UnitState.DEAD)
	queue_free()


func _to_string():
	return unit_name + " #" + str(_id) + " (" + team_name + ")"


func change_state(new_state : UnitState):
	var old_state := _state
	_state = new_state
	state_changed.emit(self, new_state, old_state)





##########################################################################
######   TAKING DAMAGE   ####################################################
################################################################################

# Call this from animation sequence to actually deal damage at the right time.
func damage_target():
	if is_instance_valid(_current_target):
		var dist := global_position.distance_to(_current_target.global_position)
		
		# Current swing is still allowed to hit up to 2x attack range
		if dist < attack_range * 2:
			# Apply damage
			_current_target.take_damage(damage, knockback)
		
		# But the target will still be dropped afterward if out of attack range.
		if dist > attack_range:
			clear_target()


func take_damage(damage_amount : float, knockback_amount : float) -> void:
	var prev_health := _health
	
	print("Taking damage: " + str(damage_amount))
	_health -= damage_amount
	damage_taken.emit(self, damage_amount, _health)
	
	if not is_equal_approx(_health, prev_health):
		update_brow_tilt()
		_damage_flash_time_remaining = damage_flash_time
		
		var knockback_force := knockback_multiplier_self * Vector3(-team.get_team_move_x(), 1.0, 0).normalized() * knockback_amount
		velocity += knockback_force
		
		if _health <= 0:
			die()


func die() -> void:
	# Event fired above is allowed to change the health last second.
	if _health <= 0:
		change_state(UnitState.DEAD)
		
		# In case an event handler wanted to save it
		if _state == UnitState.DEAD:
			# Allow time for knockback
			await get_tree().create_timer(0.25).timeout
			queue_free()


func get_damage_flash_intensity() -> float:
	return lerpf(0.0, damage_flash_intensity, clampf(_damage_flash_time_remaining / damage_flash_time, 0.0, 1.0))

################################################################################
######   END TAKING DAMAGE  #################################################
##########################################################################





##########################################################################
######   TEAM SPECIFICS   ###################################################
################################################################################

func _on_team_assigned(new_team : Team):
	assign_collision_layers()
	
	# Make team color's sprite variants visible
	show_green_art(new_team == TeamDefs.Player)
	show_red_art(new_team == TeamDefs.Enemy)
	
	# Make sure art is facing the right way (based on move direction)
	var art_node := find_child("Art2D") as Node3D
	if is_instance_valid(art_node):
		art_node.scale.x = new_team.get_team_move_x()
	
	# Enemy team gets thicker, angry eye brows
	if is_instance_valid(_eyes):
		if new_team == TeamDefs.Enemy:
			_eyes.brow_thickness = 0.15
			_brow_tilt_no_damage = 15
			update_brow_tilt()


func show_red_art(val : bool):
	for child in find_children("*Red"):
		child.visible = val


func show_green_art(val : bool):
	for child in find_children("*Green"):
		child.visible = val


func _find_eyes() -> GoogleyEyesPair:
	if not is_instance_valid(_eyes):
		var eye_children := find_children("GoogleyEyesPair")
		if len(eye_children) == 0: printerr("Missing the eyes!")
		for eye_child in eye_children:
			var eyes := eye_child as GoogleyEyesPair
			if is_instance_valid(eyes):
				return eyes
	printerr("No eyes found!")
	return null


# Based on damage, the eyes get sadder
func update_brow_tilt():
	_eyes.brow_tilt = lerp(_brow_tilt_no_damage, _brow_tilt_full_damage, (max_health - _health) / max_health)


################################################################################
######   END TEAM SPECIFICS   ###############################################
##########################################################################





##########################################################################
######   TARGET AQUISITION   ################################################
################################################################################

func _on_scan_right_body_entered(body : PhysicsBody3D):
	try_add_target(body, _right_list)


func _on_scan_left_body_entered(body : PhysicsBody3D):
	try_add_target(body, _left_list)


func _on_scan_right_body_exited(body : PhysicsBody3D):
	try_remove_target(body, _right_list)


func _on_scan_left_body_exited(body : PhysicsBody3D):
	try_remove_target(body, _left_list)


func try_add_target(body : PhysicsBody3D, list : Array[UnitBase]) -> void:
	if body is UnitBase:
		var unit := body as UnitBase
		if unit.team != self.team:
			if not list.has(unit):
				list.append(unit)


func try_remove_target(body : PhysicsBody3D, list : Array[UnitBase]) -> void:
	if body is UnitBase:
		var unit := body as UnitBase
		if unit.team != self.team:
			var index := list.find(unit)
			if index != -1:
				list.remove_at(index)


func _clean_target_lists():
	_clean_target_list(_left_list)
	_clean_target_list(_right_list)


func _clean_target_list(list : Array[UnitBase]) -> void:
	var i := 0
	while i < len(list):
		var unit = list[i]
		if not is_instance_valid(unit) or unit._state == UnitState.DEAD:
			list.remove_at(i)
		else:
			i += 1


func internal_check_target_dead(unit : UnitBase, new_state : UnitState, _old_state : UnitState): 
	if unit == _current_target and new_state == UnitState.DEAD:
		self.target_dead.emit(self, unit)
		clear_target()


func _find_nearest_target_with_scanners(max_range : float) -> UnitBase:
	var nearest_enemy : UnitBase = null
	var nearest_distance_squared = max_range * max_range
	
	# Gets a list of enemies from the left or right side detection area
	var candidates = _get_possible_targets();
	
	# Search all units in detection area
	for unit in candidates:
		var distance_squared = global_position.distance_squared_to(unit.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_enemy = unit
			nearest_distance_squared = distance_squared
	
	return nearest_enemy

func _get_possible_targets():
	_clean_target_lists()
	var other_units := _right_list
	if team == TeamDefs.Enemy:
		other_units = _left_list
	
	var candidates = [];
	for in_group in other_units:  # Could speed up with 1d tree even.
		if (_isValidTarget(in_group)):
			candidates.push_back(in_group);
	
	return candidates;

func _isValidTarget(in_group):
	var candidate_unit := in_group as UnitBase
	assert(candidate_unit, "All units should be UnitBase")
	if team == candidate_unit.team: return false;
	if candidate_unit._state == UnitState.DEAD: return false;
	return true;
  
################################################################################
######   END TARGET AQUISITION   ############################################
##########################################################################

func set_lane_offset(offset : Vector3):
	_lane_offset = offset
	var offset_node := $LaneOffset as Node3D
	if is_instance_valid(offset_node):
		# Don't let a unit move "in front of" (team based) it's collision position.
		offset.x = team.team_side * absf(offset.x)
		offset_node.position = offset
