class_name UnitBase extends CharacterBody3D

enum UnitState {
	MOVING,
	ATTACKING
}

static var next_uid := 0

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 3

@export_enum("Player", "Enemy") var team_name := "Player" : set = set_team_name
var team : Team

@export var unit_name : String

@export_category("Movement")
@export var top_speed := 10
@export var move_accel := 100.0
@export var gravity := 40.0

@export_category("Health")
@export var max_health := 100.0

@export_category("Attack")
@export var attack_range := 2.0
@export var damage := 30.0

@export_category("Rendering")
@export var damage_tint := 0.0 : set = set_damage_tint





@onready var _targeting_timer := %TargetingTimer as Timer
@onready var _ouch_animation := %OuchAnimation as AnimationPlayer

@onready var _slope_detect_left := $TerrainSlopeDetectLeft as SpringArm3D
@onready var _slope_detect_right := $TerrainSlopeDetectRight as SpringArm3D

@onready var _shadow := $Shadow as MeshInstance3D

var _target_speed : float
var _health : float

var _id := 0
var _is_dead := false
var _state := UnitState.MOVING
var _target : UnitBase = null

var _left_list := [] as Array[UnitBase]
var _right_list := [] as Array[UnitBase]

var _current_ground_angle := 0.0

signal state_changed(new_state : UnitState)





func _ready():
	_id = next_uid
	next_uid += 1
	
	# Ensure we have a team definition
	#set_team_name(team)
	
	_health = max_health
	
	state_changed.connect(on_state_changed)
	state_changed.emit(UnitState.MOVING)
	_targeting_timer.timeout.connect(_on_target_timer)
	
	_left_list.clear()
	_right_list.clear()


func _physics_process(delta : float):
	var teamMoveX := team.get_team_move_x()
	
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta
	
	else:
		var slope := _slope_detect_right.get_hit_length() - _slope_detect_left.get_hit_length()
		_current_ground_angle = atan2(slope, 1)
		_shadow.rotation.z = -_current_ground_angle
	
	
	if absf(velocity.x - teamMoveX * _target_speed) > 0.0:
		var target_move_x := teamMoveX * _target_speed
		velocity.x = move_toward(velocity.x, target_move_x, move_accel * delta)
	
	move_and_slide()


# Override if you want to pull stats from the spell definition dictionary
func consume_spell_def(_spell_def : Dictionary):
	pass


func set_team_name(val : String):
	team_name = val
	team = TeamDefs.FromName(team_name)
	on_team_change(team)


func set_damage_tint(amount : float):
	damage_tint = amount
	on_damage_tint_changed()


func _to_string():
	return unit_name + " #" + str(_id) + " (" + team_name + ")"


func on_state_changed(new_state : UnitState):
	var unit_anims := find_child("UnitAnimations") as AnimationPlayer
	match(new_state):
		UnitState.MOVING: 
			_target_speed = top_speed
			if is_instance_valid(unit_anims):
				unit_anims.play("walk")
		UnitState.ATTACKING:
			_target_speed = 0.0
			if is_instance_valid(unit_anims):
				unit_anims.play("attack")





##########################################################################
######   TAKING DAMAGE   ####################################################
################################################################################

# Call this from animation sequence to actually deal damage at the right time.
func damage_target():
	if is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		
		# Current swing is still allowed to hit up to 2x attack range
		if dist < attack_range * 2:
			# Apply damage
			_target.take_damage(damage)
			if _target._is_dead:
				_target = null
		
		# But the target will still be dropped afterward if out of attack range.
		if dist > attack_range:
			_target = null
	
	if not is_instance_valid(_target):
		state_changed.emit(UnitState.MOVING)


func take_damage(taken_damage : float) -> void:
	_health -= taken_damage
	_ouch_animation.play("ouch")
	velocity += Vector3(-team.get_team_move_x(), 0.5, 0).normalized() * 10.0
	if _health < 0:
		die()


func die() -> void:
	_is_dead = true
	queue_free()


func on_damage_tint_changed():
	var render_children := find_children("*Red")
	render_children.append_array(find_children("*Green"))
	for child in render_children:
		var meshInst := child as MeshInstance3D
		if is_instance_valid(meshInst):
			if meshInst.visible:
				set_damage_tint_on_mesh(meshInst, damage_tint)


func set_damage_tint_on_mesh(meshInst : MeshInstance3D, amount : float):
	var material := meshInst.mesh.surface_get_material(0) as ShaderMaterial
	material.set_shader_parameter("albedo", Color.WHITE.lerp(Color.RED, amount))

################################################################################
######   END TAKING DAMAGE  #################################################
##########################################################################





##########################################################################
######   TEAM SPECIFICS   ###################################################
################################################################################

func on_team_change(new_team : Team):
	# Get team layer number
	var team_layer : int
	var other_team_layer : int
	match new_team:
		TeamDefs.Player: 
			team_layer = LAYER_PLAYER
			other_team_layer = LAYER_ENEMY
		TeamDefs.Enemy: 
			team_layer = LAYER_ENEMY
			other_team_layer = LAYER_PLAYER
		_: assert(false, "Bad team!")
	
	# Assign to own team layer + world objects layer
	set_collision_layer_value(LAYER_WORLD, false)
	set_collision_layer_value(team_layer, true)
	set_collision_layer_value(other_team_layer, false)
	
	# Collide with other team layer + world objects layer
	set_collision_mask_value(LAYER_WORLD, true)
	set_collision_mask_value(other_team_layer, true)
	set_collision_mask_value(team_layer, false)
	
	# Make team color's sprite variants visible
	show_green_art(new_team == TeamDefs.Player)
	show_red_art(new_team == TeamDefs.Enemy)
	
	# Make sure art is facing the right way (based on move direction)
	var art_node := find_child("Art2D") as Node3D
	if is_instance_valid(art_node):
		art_node.scale.x = new_team.get_team_move_x()
	
	# Enemy team gets angry eye brows
	for eye_child in find_children("GoogleyEyesPair"):
		var eyes := eye_child as GoogleyEyesPair
		if is_instance_valid(eyes):
			eyes.brow_visible = (new_team == TeamDefs.Enemy)


func show_red_art(val : bool):
	for child in find_children("*Red"):
		child.visible = val


func show_green_art(val : bool):
	for child in find_children("*Green"):
		child.visible = val

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


func _on_target_timer() -> void:
	_clean_target_lists()
	_try_find_target()


func _clean_target_lists():
	_clean_target_list(_left_list)
	_clean_target_list(_right_list)


func _clean_target_list(list : Array[UnitBase]) -> void:
	var i := 0
	while i < len(list):
		var unit = list[i]
		if not is_instance_valid(unit) or unit._is_dead:
			list.remove_at(i)
		else:
			i += 1


func _try_find_target():
	if is_instance_valid(_target):
		# Current target is fine
		return
	
	var enemy := _find_nearest_target(attack_range)
	if enemy:
		_target = enemy
		if _state != UnitState.ATTACKING:
			state_changed.emit(UnitState.ATTACKING)
	else:
		_target = null
		if _state != UnitState.MOVING:
			state_changed.emit(UnitState.MOVING)


func _find_nearest_target(max_range : float) -> UnitBase:
	var nearest_enemy : UnitBase = null
	var nearest_distance_squared = max_range * max_range
	
	var other_units := _right_list
	if team == TeamDefs.Enemy:
		other_units = _left_list
	
	for in_group in other_units:  # Could speed up with 1d tree even.
		var candidate_unit := in_group as UnitBase
		assert(candidate_unit, "All units should be UnitBase")
		if team == candidate_unit.team:
			continue
		if candidate_unit._is_dead:
			continue
		
		var distance_squared = global_position.distance_squared_to(candidate_unit.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_enemy = candidate_unit
			nearest_distance_squared = distance_squared
	
	return nearest_enemy

################################################################################
######   END TARGET AQUISITION   ############################################
##########################################################################
